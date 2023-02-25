FROM php:8.1.16-fpm-alpine

RUN apk update && apk add --no-cache autoconf g++ make libmemcached-dev \
    && pecl install memcached \
    && docker-php-ext-enable memcached

RUN docker-php-ext-install mysqli pdo_mysql sockets
RUN apk add --no-cache pcre-dev $PHPIZE_DEPS

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && chmod +x /usr/local/bin/composer

RUN apk add nginx

COPY nginx/conf.d/ /etc/nginx/conf.d/
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/proxy.conf /etc/nginx/proxy.conf

COPY php/src/ /var/www/html/
COPY php/conf.d/error_reporting.ini /usr/local/etc/php/conf.d/error_reporting.ini
COPY php/conf.d/php.ini /usr/local/etc/php/php.ini

#COPY php/conf.d/xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

RUN apk add supervisor
RUN mkdir -p /etc/supervisor/conf.d/
COPY supervisor/supervisord.conf /etc/supervisor/supervisord.conf

EXPOSE 8000

STOPSIGNAL SIGTERM

RUN chown -R www-data:www-data /var/lib/nginx
RUN chmod -R 777 /var/lib/nginx

RUN chown -R www-data:www-data /var/log/nginx
RUN chmod -R 777 /var/log/nginx

RUN touch /var/run/nginx.pid && chown www-data:www-data /var/run/nginx.pid
RUN touch /var/log/supervisord.log && chown www-data:www-data /var/log/supervisord.log

RUN mkdir -p /var/log/php-fpm && chown www-data:www-data /var/log/php-fpm

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
