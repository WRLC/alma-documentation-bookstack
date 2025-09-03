#!/bin/bash
set -e

# Copy nginx config
cp /home/site/wwwroot/nginx.conf /etc/nginx/sites-enabled/default
nginx -s reload

# Navigate to BookStack directory
cd /home/site/wwwroot/BookStack

# Wait for database to be ready (optional but recommended)
sleep 5

# Run database migrations
php artisan migrate --force

# Clear caches
php artisan optimize:clear

# Set proper permissions for storage (needed after each restart)
chown -R www-data:www-data storage/app/public/uploads
chmod -R 775 storage/app/public/uploads
