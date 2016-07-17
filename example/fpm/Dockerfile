FROM php:7-fpm

WORKDIR /var/www

RUN apt-get update && apt-get install -y git unzip \
 && rm -r /var/lib/apt/lists/*

ENV COMPOSER_HOME /composer
ENV PATH /composer/vendor/bin:$PATH
ENV COMPOSER_ALLOW_SUPERUSER 1

RUN php -r "readfile('https://getcomposer.org/installer');" > /tmp/composer-setup.php \
  && php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer --snapshot && rm -rf /tmp/composer-setup.php \
  && chmod +x /usr/local/bin/composer

COPY ./docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh \
 && mkdir /docker-entrypoint.d

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["php-fpm"]
