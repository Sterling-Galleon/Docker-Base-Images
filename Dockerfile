FROM php:5.6-apache
MAINTAINER Andre Marcelo-Tanner <andre@galleon.ph>

ENV DEBIAN_FRONTEND=noninteractive

# Install utility software
RUN apt-get update \
    && apt-get install -y \
       git \
       wget \
       lsb-release \
       apt-transport-https \
       ssl-cert \
       vim-tiny \
    && curl -LO https://dev.mysql.com/get/mysql-apt-config_0.8.8-1_all.deb \
    && dpkg -i mysql-apt-config_0.8.8-1_all.deb \
    && rm mysql-apt-config_0.8.8-1_all.deb

# Install NodeJS
RUN curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
    && echo "deb https://deb.nodesource.com/node_6.x $(lsb_release -cs) main" >> /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y \
       nodejs

# Install mysql client
RUN apt-get install -y \
   libmysqlclient-dev

# Install PHP Extensions w/o deps: mbstring, mysqli, opcache, pdo, pdo_mysql, bcmath, json, zip
RUN docker-php-ext-install -j$(nproc) \
    mbstring \
    mysqli \
    opcache \
    pdo \
    pdo_mysql \
	bcmath \
	json \
	zip

# Install PHP Extensions: gd
RUN apt-get install -y --no-install-recommends \
		libfontconfig1-dev \
		libfreetype6-dev \
		libjpeg62-turbo-dev \
		libpng12-dev \
	&& docker-php-ext-configure \
		gd \
		--with-freetype-dir=/usr/include \
		--with-jpeg-dir=/usr/include \
	&& RUN docker-php-ext-install -j$(nproc) \
		gd \
	&& apt-get autoremove -y

# Install PHP Extensions: xml
RUN apt-get install -y --no-install-recommends \
		libxml2-dev \
	&& RUN docker-php-ext-install -j$(nproc) \
		xml \
	&& apt-get autoremove -y

# Install PHP Extensions: bz2
RUN apt-get install -y --no-install-recommends \
		libbz2-dev \
	&& RUN docker-php-ext-install -j$(nproc) \
		bz2 \
	&& apt-get autoremove -y

# Install PHP Extensions: intl
RUN apt-get install -y --no-install-recommends \
        libicu-dev \
    && docker-php-ext-install -j$(nproc) \
        intl \
    && apt-get remove -y \
        libicu-dev \
    && apt-get autoremove -y \
    && apt-get install -y \
        libicu52 \
        libltdl7

# Install PHP Extensions: mcrypt
RUN apt-get install -y --no-install-recommends \
        libmcrypt-dev \
    && docker-php-ext-install -j$(nproc) \
        mcrypt \
    && apt-get remove -y \
        libmcrypt-dev \
    && apt-get autoremove -y \
    && apt-get install -y \
        libmcrypt4

# Install PHP Pecl Extensions w/o deps: apcu
RUN yes '' | pecl install \
        apcu-4.0.11 \
    && docker-php-ext-enable \
        apcu

# Install PHP Pecl Extensions: imagick
RUN apt-get install -y --no-install-recommends \
        libmagickwand-dev \
    && yes '' | pecl install \
        imagick-3.4.3 \
    && docker-php-ext-enable \
        imagick \
    && apt-get remove -y \
        libmagickwand-dev \
    && apt-get autoremove -y \
    && apt-get install -y \
        libmagickwand-6.q16-2

# Cleanup APT
RUN rm -rf /var/lib/apt/lists/*

# Install Composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php -r "if (hash_file('SHA384', 'composer-setup.php') === '544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    && php composer-setup.php --install-dir=/usr/bin --filename=composer \
    && php -r "unlink('composer-setup.php');"

# Enable Apache Mods
RUN a2enmod rewrite ssl \
    && a2ensite default-ssl

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
      echo 'opcache.memory_consumption=128'; \
      echo 'opcache.interned_strings_buffer=8'; \
      echo 'opcache.max_accelerated_files=4000'; \
      echo 'opcache.revalidate_freq=2'; \
      echo 'opcache.fast_shutdown=1'; \
      echo 'opcache.enable_cli=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini