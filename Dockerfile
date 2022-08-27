FROM php:8.1.9-fpm-alpine

RUN docker-php-ext-install mysqli pdo_mysql
RUN docker-php-ext-install sockets
RUN apk add --no-cache pcre-dev $PHPIZE_DEPS

RUN pecl install redis
RUN docker-php-ext-enable redis.so

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && chmod +x /usr/local/bin/composer

RUN apk add bash
RUN apk add nginx

COPY nginx/conf.d/ /etc/nginx/conf.d/
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/proxy.conf /etc/nginx/proxy.conf

COPY php/src/ /var/www/html/
COPY php/conf.d/error_reporting.ini /usr/local/etc/php/conf.d/error_reporting.ini
COPY php/conf.d/php.ini /usr/local/etc/php/php.ini

#COPY php/conf.d/xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

RUN apk add supervisor
COPY supervisor/supervisord.conf /etc/supervisord.conf

EXPOSE 8000

STOPSIGNAL SIGTERM

RUN chown -R www-data:www-data /var/lib/nginx
RUN chmod -R 777 /var/lib/nginx

RUN chown -R www-data:www-data /var/log/nginx
RUN chmod -R 777 /var/log/nginx

RUN touch /var/run/nginx.pid && chown www-data:www-data /var/run/nginx.pid
RUN touch /var/log/supervisord.log && chown www-data:www-data /var/log/supervisord.log

RUN mkdir -p /var/log/php-fpm && chown www-data:www-data /var/log/php-fpm

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
