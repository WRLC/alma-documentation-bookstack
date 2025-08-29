#!/bin/bash
set -e

echo "BookStack Post-Deployment Script Starting..."

# Navigate to the application directory
cd /home/site/wwwroot

# Install Composer dependencies if composer.json exists
if [ -f "composer.json" ]; then
    echo "Installing Composer dependencies..."
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php composer-setup.php --quiet
    rm composer-setup.php
    php composer.phar install --no-dev --optimize-autoloader --no-interaction
    rm composer.phar
else
    echo "No composer.json found, skipping Composer install"
fi

# Generate storage link
if [ ! -L "public/storage" ]; then
    echo "Creating storage link..."
    php artisan storage:link
fi

# Set proper permissions
echo "Setting permissions..."
chmod -R 755 storage bootstrap/cache
chmod -R 775 storage/logs storage/framework

# Clear and cache configuration
echo "Optimizing application..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Run database migrations
echo "Running database migrations..."
php artisan migrate --force --no-interaction

echo "BookStack deployment completed successfully!"