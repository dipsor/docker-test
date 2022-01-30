ARG ALPINE_VERSION=3.14
FROM alpine:${ALPINE_VERSION}
LABEL Maintainer="Tim de Pater <code@trafex.nl>"
LABEL Description="Lightweight container with Nginx 1.20 & PHP 8.0 based on Alpine Linux."
# Setup document root
WORKDIR /var/www/html

# Install packages and remove default server definition
RUN apk add --no-cache \
  curl \
  nginx \
  php8 \
  php8-ctype \
  php8-curl \
  php8-dom \
  php8-fpm \
  php8-gd \
  php8-intl \
  php8-json \
  php8-mbstring \
  php8-mysqli \
  php8-pdo \
  php8-opcache \
  php8-openssl \
  php8-phar \
  php8-session \
  php8-xml \
  php8-xmlreader \
  php8-zlib \
  php8-tokenizer \
  php8-fileinfo \
  php8-json \
  php8-xml \
  php8-xmlwriter \
  php8-simplexml \
  php8-dom \
  php8-pdo_mysql \
  php8-pdo_sqlite \
  php8-tokenizer \
  php8-pecl-redis \
  supervisor

# Create symlink so programs depending on `php` still function
RUN ln -s /usr/bin/php8 /usr/bin/php

# Configure nginx
COPY tools/docker/config/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY tools/docker/config/fpm-pool.conf /etc/php8/php-fpm.d/www.conf
COPY tools/docker/config/php.ini /etc/php8/conf.d/custom.ini

# Configure supervisord
COPY tools/docker/config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /var/www/html /run /var/lib/nginx /var/log/nginx

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN apk update && apk add bash

# Install node npm
RUN apk add --update nodejs npm \
 && npm config set --global loglevel warn \
 && npm install --global marked \
 && npm install --global node-gyp \
 && npm install --global yarn \
 # Install node-sass's linux bindings
 && npm rebuild node-sass

# Switch to use a non-root user from here on
USER nobody

# Add application
COPY --chown=nobody ./ /var/www/html/

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
