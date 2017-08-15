#!/bin/sh

# Inspired by https://github.com/psi-4ward/docker-owncloud
# more than ripped off, i admit

# enable opcache config
sed -i -e"s/;opcache.enable=.*/opcache.enable=1/" /etc/php7/php.ini
sed -i -e"s/;opcache.enable_cli=.*/opcache.enable_cli=1/" /etc/php7/php.ini
sed -i -e"s/;opcache.interned_strings_buffer=.*/opcache.interned_strings_buffer=8/" /etc/php7/php.ini
sed -i -e"s/;opcache.max_accelerated_files=.*/opcache.max_accelerated_files=10000/" /etc/php7/php.ini
sed -i -e"s/;opcache.memory_consumption=.*/opcache.memory_consumption=128/" /etc/php7/php.ini
sed -i -e"s/;opcache.save_comments=.*/opcache.save_comments=1/" /etc/php7/php.ini
sed -i -e"s/;opcache.revalidate_freq=.*/opcache.revalidate_freq=1/" /etc/php7/php.ini

# needed for some apps, which don't set x-frame themselves. potential security risk
sed -i -e"s/header('X-Frame-Options: .*/header('X-Frame-Options: ALLOW');/" /usr/share/webapps/nextcloud/lib/private/legacy/response.php
# deal with the weird alpine packaging of some nextcloud packages
ln -s /usr/share/doc/nextcloud/core/doc/ /usr/share/webapps/nextcloud/core/doc

# expose config directory
[ ! -d /media/owncloud/config ] \
      && mkdir -p /media/owncloud/config \
      && chown -R nginx:www-data /media/owncloud/config \
      && chmod -R 0770 /media/owncloud/config
[ -d /usr/share/webapps/nextcloud/config ] && rm -rf /usr/share/webapps/nextcloud/config
ln -s /media/owncloud/config /usr/share/webapps/nextcloud/config
ln -s /media/owncloud/apps /usr/share/webapps/nextcloud/apps2

# create default config.php
[ ! -f /media/owncloud/config/config.php ] \
      && mv /tmp/config.php /media/owncloud/config/config.php \
      && chown nginx:www-data /media/owncloud/config/config.php

# copy owncloud autoconfig.php
[ "`grep "'installed' => false" /media/owncloud/config/config.php`" != "" ] \
      && [ -f /tmp/autoconfig.php ] \
      && mv /tmp/autoconfig.php /media/owncloud/config/autoconfig.php \
      && chown nginx:www-data /media/owncloud/config/autoconfig.php

# owncloud data directory
[ ! -d /media/owncloud/data ] \
      && mkdir -p /media/owncloud/data \
      && chown -R nginx:www-data /media/owncloud/data \
      && chmod -R 0770 /media/owncloud/data      

# owncloud app directory
[ ! -d /media/owncloud/apps ] \
      && mkdir -p /media/owncloud/apps \
      && chown -R nginx:www-data /media/owncloud/apps \
      && chmod -R 0770 /media/owncloud/apps
      
# fix owncloud bugs
#mv /usr/share/webapps/owncloud/apps/calendar-* /usr/share/webapps/owncloud/apps/calendar
#mv /usr/share/webapps/owncloud/apps/contacts-* /usr/share/webapps/owncloud/apps/contacts


# owncloud log directory
[ ! -d /media/owncloud/logs/owncloud ] \
      && mkdir -p /media/owncloud/logs/owncloud \
      && chown nginx:www-data /media/owncloud/logs/owncloud \
      && chmod 0770 /media/owncloud/logs/owncloud
      
# create cronjob for nextcloud
{ crontab -l -u nginx; echo '*/15  *  *  *  * php -f /usr/share/webapp/nextcloud/cron.php'; } | crontab -u nginx -

# only needed, if you don't have redis as a server  start redis and make it run as deamon
#mkdir -p /media/owncloud/cache
#redis-server --dir /media/owncloud/cache --appendonly yes --daemonize yes

# start php-fpm
mkdir -p /media/owncloud/logs/php-fpm
php-fpm7

# start nginx
mkdir -p /media/owncloud/logs/nginx
mkdir -p /tmp/nginx
chown nginx /tmp/nginx 
nginx
