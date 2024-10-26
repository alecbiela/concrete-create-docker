# Install the specified PHP-Apache version
ARG PHP_VERSION
FROM php:${PHP_VERSION}-apache
RUN apt-get update && apt-get upgrade -y

# Install Composer, unzip, git
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN apt-get install -y unzip git-all

# Grab mlocati's extension helper and install some missing extensions
ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN install-php-extensions pdo_mysql gd xdebug zip intl

# Set up SSL
RUN a2enmod rewrite && a2enmod ssl && a2enmod socache_shmcb
RUN sed -i '/SSLCertificateFile.*snakeoil\.pem/c\SSLCertificateFile \/etc\/ssl\/certs\/mycert.crt' /etc/apache2/sites-available/default-ssl.conf && sed -i '/SSLCertificateKeyFile.*snakeoil\.key/cSSLCertificateKeyFile /etc/ssl/private/mycert.key\' /etc/apache2/sites-available/default-ssl.conf
RUN a2ensite default-ssl

# Populate volume with Concrete CMS files
ARG CONCRETE_VERSION
RUN cd /var/www/html/
RUN composer create-project -n concrete5/concrete5:${CONCRETE_VERSION} .
RUN chown -R www-data:www-data ./application
RUN chown -R www-data:www-data ./packages
RUN chown -R www-data:www-data ./updates