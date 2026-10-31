# from https://www.drupal.org/docs/8/system-requirements/drupal-8-php-requirements
FROM php:8.5.12-fpm-alpine3.24@sha256:4c2818074ec49f6abe46620f3965e0cb75bc3a5f2b417edd1aacaba6f091c40e AS php-base

# Compile extensions separately so build tools and PECL artifacts stay out of runtime.
FROM php-base AS extensions

RUN set -eux; \
  apk add --no-cache --virtual .build-deps \
    autoconf=2.73-r0 \
    cmake=4.2.3-r0 \
    build-base=0.5-r4 \
    bzip2-dev=1.0.8-r6 \
    freetype-dev=2.14.3-r0 \
    gmp-dev=6.3.0-r4 \
    icu-dev=78.1-r0 \
    imagemagick-dev=7.1.2.34-r0 \
    imap-dev=2007f-r16 \
    jpeg-dev=9f-r0 \
    krb5-dev=1.22.2-r1 \
    libevent-dev=2.1.13-r0 \
    libgcrypt-dev=1.12.2-r0 \
    libjpeg-turbo-dev=3.1.3-r0 \
    libmemcached-dev=1.1.4-r1 \
    libmcrypt-dev=2.5.8-r11 \
    libpng-dev=1.6.59-r0 \
    libtool=2.6.0-r1 \
    libwebp-dev=1.6.0-r0 \
    libxslt-dev=1.1.43-r3 \
    libzip-dev=1.11.4-r2 \
    linux-headers=7.0.0-r1 \
    openldap-dev=2.6.15-r0 \
    openssl-dev=3.5.9-r0 \
    pcre-dev=8.45-r4 \
    tidyhtml-dev=5.8.0-r5 \
    yaml-dev=0.2.5-r2 \
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
    pcntl \
    pdo_mysql \
    soap \
    sockets \
    tidy \
    xsl \
    zip \
  ; \
  \
  for extension in \
    apcu-5.1.28 \
    ast-1.1.4 \
    ds-2.0.0 \
    event-3.1.6 \
    igbinary-3.2.17RC1 \
    imagick-3.8.1 \
    mcrypt-1.0.9 \
    memcached-3.4.0 \
    oauth-2.0.10 \
    pcov-1.0.12 \
    redis-6.3.0 \
    uploadprogress-2.0.2 \
    uuid-1.3.0 \
    yaml-2.3.0 \
    channel://pecl.php.net/xmlrpc-1.0.0RC3 \
  ; do \
    module="${extension##*/}"; \
    module="${module%%-*}"; \
    attempt=1; \
    until pecl install "$extension" && test -f "$(php-config --extension-dir)/$module.so"; do \
      if [ "$attempt" -ge 3 ]; then \
        echo "Failed to install PHP extension: $extension" >&2; \
        exit 1; \
      fi; \
      attempt=$((attempt + 1)); \
      sleep 5; \
    done; \
  done; \
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
  mv /usr/local/etc/php/conf.d/docker-php-ext-event.ini /usr/local/etc/php/conf.d/z-docker-php-ext-event.ini

FROM php-base AS runtime

RUN set -eux; \
  apk add --update --no-cache \
    bash=5.3.9-r1 \
    c-client=2007f-r16 \
    fcgi=2.4.6-r0 \
    findutils=4.10.0-r1 \
    freetype=2.14.3-r0 \
    ghostscript=10.08.0-r0 \
    git=2.54.0-r0 \
    gmp=6.3.0-r4 \
    icu-libs=78.1-r0 \
    imagemagick=7.1.2.34-r0 \
    jpegoptim=1.5.6-r0 \
    less=702-r0 \
    libbz2=1.0.8-r6 \
    libevent=2.1.13-r0 \
    libjpeg-turbo=3.1.3-r0 \
    libjpeg-turbo-utils=3.1.3-r0 \
    libldap=2.6.15-r0 \
    libltdl=2.6.0-r1 \
    libmemcached-libs=1.1.4-r1 \
    libmcrypt=2.5.8-r11 \
    libpng=1.6.59-r0 \
    libuuid=2.42.3-r1 \
    libwebp=1.6.0-r0 \
    libxml2=2.13.9-r2 \
    libxslt=1.1.43-r3 \
    libzip=1.11.4-r2 \
    mysql-client=11.8.9-r0 \
    nginx=1.30.6-r0 \
    patch=2.8-r0 \
    pngquant=3.0.3-r0 \
    rsync=3.5.0-r0 \
    shadow=4.18.0-r1 \
    su-exec=0.3-r0 \
    supervisor=4.3.0-r1 \
    tidyhtml-libs=5.8.0-r5 \
    yaml=0.2.5-r2

# Only compiled modules and their ini files cross the stage boundary.
COPY --from=extensions /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=extensions /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/

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
COPY --from=composer:2.11.1@sha256:537fb03057ed901ae06bde7ef25af348903485ae1acc7fc789b80d8bac666f35 /usr/bin/composer /usr/local/bin/composer

# Fail the build if an extension or one of its runtime libraries is missing.
RUN php -r 'foreach (explode(" ", "bcmath bz2 calendar exif gd gmp intl ldap mysqli pcntl pdo_mysql soap sockets tidy xsl zip apcu ast ds event igbinary imagick mcrypt memcached oauth pcov redis uploadprogress uuid yaml xmlrpc") as $extension) { if (!extension_loaded($extension)) { fwrite(STDERR, "Missing PHP extension: $extension\n"); exit(1); } }'

WORKDIR /var/www/html
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord","-c","/etc/supervisor/conf.d/supervisord.conf"]
EXPOSE 8080

# vim:set ft=dockerfile:
