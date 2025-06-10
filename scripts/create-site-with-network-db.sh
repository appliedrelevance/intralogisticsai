#!/bin/bash

# Production-ready site creation script that ensures database works across container restarts
# This script fixes the fundamental IP-binding issue in Frappe Docker

set -e

SITE_NAME=${1:-intralogistics.localhost}
ADMIN_PASSWORD=${2:-admin}
DB_ROOT_PASSWORD=${3:-123}

echo "Creating site: $SITE_NAME"
echo "This script ensures database connectivity survives container restarts..."

# Step 1: Create the site normally
echo "Step 1: Creating Frappe site..."
docker compose exec backend bench new-site \
  --db-root-password "$DB_ROOT_PASSWORD" \
  --admin-password "$ADMIN_PASSWORD" \
  --mariadb-user-host-login-scope=% \
  --install-app erpnext \
  --install-app epibus \
  "$SITE_NAME"

# Step 2: Extract database credentials from site config
echo "Step 2: Extracting database credentials..."
DB_NAME=$(docker compose exec backend cat "sites/$SITE_NAME/site_config.json" | grep -o '"db_name": "[^"]*"' | cut -d'"' -f4)
DB_USER=$(docker compose exec backend cat "sites/$SITE_NAME/site_config.json" | grep -o '"db_name": "[^"]*"' | cut -d'"' -f4)
DB_PASSWORD=$(docker compose exec backend cat "sites/$SITE_NAME/site_config.json" | grep -o '"db_password": "[^"]*"' | cut -d'"' -f4)

echo "Database: $DB_NAME"
echo "User: $DB_USER"

# Step 3: Create wildcard database user that works from any container IP
echo "Step 3: Creating network-wide database user..."
docker compose exec db mysql -uroot -p"$DB_ROOT_PASSWORD" -e "
DROP USER IF EXISTS '$DB_USER'@'%';
CREATE USER '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'%';
FLUSH PRIVILEGES;
"

# Step 4: Remove any IP-specific users that were created
echo "Step 4: Cleaning up IP-specific database users..."
docker compose exec db mysql -uroot -p"$DB_ROOT_PASSWORD" -e "
DELETE FROM mysql.user WHERE User='$DB_USER' AND Host != '%';
FLUSH PRIVILEGES;
"

# Step 5: Verify the fix worked
echo "Step 5: Verifying database connectivity..."
docker compose exec backend bench --site "$SITE_NAME" list-apps

echo ""
echo "✅ Site created successfully with network-resilient database configuration!"
echo ""
echo "Access your site at: http://localhost:\$(docker port frappe_docker-frontend-1 8080 | cut -d':' -f2)/"
echo "Login: Administrator / $ADMIN_PASSWORD"
echo ""
echo "The database configuration will now survive container restarts."