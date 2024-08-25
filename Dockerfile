# Use an official PHP image as the base image
FROM php:7.4-apache

# Set the working directory
WORKDIR /var/www/html

# Copy the composer.json file first
COPY composer.json /var/www/html/

# Install necessary PHP extensions and utilities
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    curl \
    && docker-php-ext-install mysqli pdo pdo_mysql \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install Composer dependencies
RUN composer install --no-dev --optimize-autoloader

# Copy the rest of the application files
COPY . /var/www/html

# Set appropriate permissions for the web server
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Enable Apache mod_rewrite for pretty URLs
RUN a2enmod rewrite

# Expose port 80 to the outside world
EXPOSE 80

# Start Apache in the foreground
CMD ["apache2-foreground"]
