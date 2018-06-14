FROM php:7-fpm

WORKDIR /var/www

RUN apt-get update \
 && apt-get install -y \
      git \
      libfontconfig \
      libfreetype6-dev \
      libjpeg62-turbo-dev \
      unzip \
 && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
 && docker-php-ext-install -j$(nproc) \
      gd \
 && rm -r /var/lib/apt/lists/*

ENV COMPOSER_HOME /composer
ENV PATH /composer/vendor/bin:$PATH

RUN php -r "readfile('https://getcomposer.org/installer');" > /tmp/composer-setup.php \
  && php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer --snapshot && rm -rf /tmp/composer-setup.php \
  && chmod +x /usr/local/bin/composer

# Allow Composer to be run as root
ENV COMPOSER_ALLOW_SUPERUSER 1
# Composer extensions
RUN /usr/local/bin/composer global require 'hirak/prestissimo' \
 && mkdir -p /composer/cache \
 && chown -R www-data:www-data /composer \
 && chmod -R ug+rwX /composer
# Remove allowing to be run as root
ENV COMPOSER_ALLOW_SUPERUSER 0

COPY ./docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh \
 && mkdir /docker-entrypoint.d

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["php-fpm"]
