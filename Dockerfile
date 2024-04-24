FROM php:8.3.6-fpm

RUN apt update

RUN apt install -y gcc make autoconf libc-dev pkg-config
RUN apt install -y zlib1g-dev
RUN apt install -y libmemcached-dev
RUN apt install -y libssl-dev
RUN apt install -y cron

RUN pecl install -f memcached
RUN docker-php-ext-enable memcached

RUN docker-php-ext-install mysqli pdo_mysql sockets

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && chmod +x /usr/local/bin/composer

RUN apt install -y nginx

COPY nginx/conf.d/ /etc/nginx/conf.d/
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/proxy.conf /etc/nginx/proxy.conf

COPY php/src/ /var/www/html/
COPY php/conf.d/error_reporting.ini /usr/local/etc/php/conf.d/error_reporting.ini
COPY php/conf.d/php.ini /usr/local/etc/php/php.ini

RUN apt install -y supervisor
RUN mkdir -p /etc/supervisor/conf.d/
COPY supervisor/supervisord.conf /etc/supervisor/supervisord.conf

EXPOSE 8000

STOPSIGNAL SIGTERM

RUN mkdir -p /var/log/php-fpm/
RUN mkdir -p /var/log/nginx/
RUN mkdir -p /var/log/supervisor/

RUN touch /var/run/nginx.pid
RUN chown www-data:www-data /var/run/nginx.pid

RUN touch /var/run/supervisord.pid
RUN chown www-data:www-data /var/run/supervisord.pid

RUN touch /var/log/supervisor/supervisord.log

RUN chown -R www-data:www-data /var/log/
RUN chmod -R 777 /var/log/

RUN chown -R www-data:www-data /var/lib/nginx
RUN chmod -R 777 /var/lib/nginx

RUN mkdir -p /var/www/html/storage/
RUN chown www-data:www-data /var/www/html/storage/

COPY cron/artisan /var/spool/cron/crontabs/root
RUN chown root:root /var/spool/cron/crontabs/root
RUN chmod 644 /var/spool/cron/crontabs/root

RUN apt install -y nano

RUN service cron restart

CMD /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
