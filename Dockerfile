FROM php:8.1.16-fpm-alpine

ENV MEMCACHED_DEPS zlib-dev libmemcached-dev cyrus-sasl-dev
RUN apk add --no-cache --update libmemcached-libs zlib openrc
RUN set -xe \
    && apk add --no-cache --update --virtual .phpize-deps $PHPIZE_DEPS \
    && apk add --no-cache --update --virtual .memcached-deps $MEMCACHED_DEPS \
    && pecl install memcached \
    && echo "extension=memcached.so" > /usr/local/etc/php/conf.d/20_memcached.ini \
    && rm -rf /usr/share/php8 \
    && rm -rf /tmp/* \
    && apk del .memcached-deps .phpize-deps

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

RUN mkdir -p /var/log/php-fpm/
RUN mkdir -p /var/log/nginx/
RUN mkdir -p /var/log/supervisor/

RUN touch /var/run/nginx.pid
RUN touch /var/log/supervisor/supervisord.log

RUN rc-update add supervisord

RUN chown -R www-data:www-data /var/log/
RUN chmod -R 777 /var/log/
RUN chown www-data:www-data /var/run/nginx.pid
RUN chown -R www-data:www-data /var/lib/nginx
RUN chmod -R 777 /var/lib/nginx

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
