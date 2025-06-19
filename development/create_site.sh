#!/bin/bash
set -e

# Exit if site already exists
if [ -d "sites/intralogistics.localhost" ]; then
  echo "Site intralogistics.localhost already exists."
  exit 0
fi

# Create new site
echo "Creating site intralogistics.localhost..."
bench new-site intralogistics.localhost --mariadb-root-password ${MARIADB_ROOT_PASSWORD:-123} --admin-password ${ADMIN_PASSWORD:-admin} --install-app erpnext --set-default

# Get and install epibus app
echo "Getting epibus app..."
bench get-app epibus https://github.com/appliedrelevance/epibus.git
echo "Installing epibus app..."
bench --site intralogistics.localhost install-app epibus

echo "Site creation complete."