# from https://www.drupal.org/docs/8/system-requirements/drupal-8-php-requirements
FROM php:8.2-fpm-alpine

RUN set -eux; \
  apk add --update --no-cache \
  bash \
  c-client=2007f-r15 \
  fcgi \
  findutils \
  freetype \
  ghostscript \
  git \
  gmp \
  icu-libs \
  imagemagick \
  jpegoptim \
  less \
  libbz2 \
  libevent \
  libjpeg-turbo \
  libjpeg-turbo-utils \
  libldap \
  libltdl \
  libmemcached-libs \
  libmcrypt \
  libpng \
  libuuid \
  libwebp \
  libxml2 \
  libxslt \
  libzip \
  mysql-client \
  nginx \
  patch \
  pngquant \
  rsync \
  shadow \
  su-exec \
  supervisor \
  tidyhtml-libs \
  yaml \
  ; \
  apk add --no-cache --virtual .build-deps \
  autoconf \
  cmake \
  build-base \
  bzip2-dev \
  freetype-dev \
  gmp-dev \
  icu-dev \
  imagemagick-dev \
  imap-dev \
  jpeg-dev \
  krb5-dev \
  libevent-dev \
  libgcrypt-dev \
  libjpeg-turbo-dev \
  libmemcached-dev \
  libmcrypt-dev \
  libpng-dev \
  libtool \
  libwebp-dev \
  libxslt-dev \
  libzip-dev \
  linux-headers \
  openldap-dev \
  openssl-dev \
  pcre-dev \
  tidyhtml-dev \
  yaml-dev \
  ; \
  \
  docker-php-ext-configure gd \
  --with-webp \
  --with-freetype \
  --with-jpeg \
  ; \
  \
  docker-php-ext-install -j "$(nproc)" \
  bcmath \
  bz2 \
  calendar \
  exif \
  gd \
  gmp \
  intl \
  ldap \
  mysqli \
  opcache \
  pcntl \
  pdo_mysql \
  soap \
  sockets \
  tidy \
  xsl \
  zip \
  ; \
  \
  pecl install \
  apcu \
  ast \
  ds \
  event \
  igbinary \
  imagick \
  mcrypt \
  memcached \
  oauth \
  pcov \
  redis \
  uploadprogress \
  uuid \
  yaml \
  channel://pecl.php.net/xmlrpc-1.0.0RC3 \
  ; \
  docker-php-ext-enable \
  apcu \
  ast \
  ds \
  event \
  igbinary \
  imagick \
  mcrypt \
  memcached \
  oauth \
  pcov \
  redis \
  uploadprogress \
  uuid \
  yaml \
  xmlrpc \
  ; \
  mv /usr/local/etc/php/conf.d/docker-php-ext-event.ini /usr/local/etc/php/conf.d/z-docker-php-ext-event.ini; \
  runDeps="$( \
  scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
  | tr ',' '\n' \
  | sort -u \
  | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
  )"; \
  apk add --virtual .drupal-phpexts-rundeps $runDeps; \
  pecl clear-cache; \
  apk del .build-deps

RUN mv /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini && \
  rm /usr/local/etc/php-fpm.d/*docker*.conf

COPY config/nginx-general.conf /etc/nginx/nginx.conf
COPY config/nginx-site.conf /etc/nginx/conf.d/default.conf
COPY config/php-fpm-custom.conf /usr/local/etc/php-fpm.d/zzz-custom.conf
COPY config/php-custom.ini /usr/local/etc/php/conf.d/zzz-custom.ini
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY scripts/docker-entrypoint.sh /docker-entrypoint.sh

# set default UID and GID for www-data to 1000
# override these with PUID and PGID environment variables
RUN usermod -u 1000 www-data && \
  groupmod -g 1000 www-data && \
  chown www-data:www-data /home/www-data && \
  chown -R www-data:www-data /var/www

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install Drush Launcher
RUN curl -L -sLo drush.phar https://github.com/drush-ops/drush-launcher/releases/latest/download/drush.phar && \
  chmod +x drush.phar && \
  mv drush.phar /usr/local/bin/drush

WORKDIR /var/www/html
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord","-c","/etc/supervisor/conf.d/supervisord.conf"]
EXPOSE 8080

# vim:set ft=dockerfile:
