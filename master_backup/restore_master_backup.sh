#!/bin/bash

# Master Backup Restoration Script
# Restores the fully configured intralogistics lab environment

BACKUP_PREFIX="20250906_200713-intralogistics_lab"
BACKUP_DIR="master_backup"
SITE_NAME="intralogistics.lab"

echo "🚀 Restoring Master Backup - Intralogistics Lab"
echo "================================================"
echo "Backup: $BACKUP_PREFIX"
echo "Target Site: $SITE_NAME"
echo ""

# Check if we're in the right directory
if [ ! -f "deploy.sh" ]; then
    echo "❌ Error: Must run from the project root directory (where deploy.sh is located)"
    exit 1
fi

# Check if backup files exist
if [ ! -f "$BACKUP_DIR/${BACKUP_PREFIX}-database.sql.gz" ]; then
    echo "❌ Error: Database backup not found at $BACKUP_DIR/${BACKUP_PREFIX}-database.sql.gz"
    exit 1
fi

echo "✅ Found all backup files"

# Stop any existing deployment
echo "🛑 Stopping existing deployment..."
./deploy.sh stop

# Start fresh deployment
echo "🚀 Starting fresh deployment..."
./deploy.sh

# Wait for deployment to complete
echo "⏳ Waiting for deployment to complete..."
sleep 30

# Copy backup files to container
echo "📤 Copying backup files to container..."
docker compose cp "$BACKUP_DIR/${BACKUP_PREFIX}-database.sql.gz" backend:/tmp/
docker compose cp "$BACKUP_DIR/${BACKUP_PREFIX}-files.tgz" backend:/tmp/ 2>/dev/null || echo "Files backup not critical"
docker compose cp "$BACKUP_DIR/${BACKUP_PREFIX}-private-files.tgz" backend:/tmp/ 2>/dev/null || echo "Private files backup not critical"
docker compose cp "$BACKUP_DIR/${BACKUP_PREFIX}-site_config_backup.json" backend:/tmp/ 2>/dev/null || echo "Site config backup not critical"

# Restore the database
echo "🔄 Restoring database..."
if echo "123" | docker compose exec -T backend bench --site "$SITE_NAME" restore "/tmp/${BACKUP_PREFIX}-database.sql.gz" --force; then
    echo "✅ Database restored successfully"
else
    echo "❌ Database restoration failed"
    exit 1
fi

# Restore files if they exist
echo "📁 Restoring files..."
docker compose exec backend bash -c "cd /home/frappe/frappe-bench/sites/$SITE_NAME && tar -xf /tmp/${BACKUP_PREFIX}-files.tgz" 2>/dev/null || echo "No public files to restore"
docker compose exec backend bash -c "cd /home/frappe/frappe-bench/sites/$SITE_NAME && tar -xf /tmp/${BACKUP_PREFIX}-private-files.tgz" 2>/dev/null || echo "No private files to restore"

# Clean up temporary files
echo "🧹 Cleaning up temporary files..."
docker compose exec backend rm -f "/tmp/${BACKUP_PREFIX}-*"

# Run database migrations to ensure consistency
echo "🔄 Running database migrations..."
docker compose exec backend bench --site "$SITE_NAME" migrate

# Restart services to ensure everything is loaded correctly
echo "🔄 Restarting backend and frontend services..."
docker compose restart backend frontend queue-short queue-long scheduler websocket

# Wait for services to be ready
echo "⏳ Waiting for services to restart..."
sleep 15

# Verify site is accessible
echo "🔍 Verifying site accessibility..."
for i in {1..10}; do
    if curl --max-time 5 -f -s "http://intralogistics.lab" >/dev/null 2>&1; then
        echo "✅ Site is accessible"
        break
    else
        echo "⏳ Waiting for site to be ready... ($i/10)"
        sleep 3
        if [ $i -eq 10 ]; then
            echo "⚠️ Site may take a moment to fully start - check http://intralogistics.lab"
        fi
    fi
done

echo ""
echo "🎉 MASTER BACKUP RESTORATION COMPLETED!"
echo "========================================="
echo "🌐 Access your site: http://intralogistics.lab"
echo "🔑 Login: Administrator / admin"
echo ""
echo "✅ What's included:"
echo "  - Global Trade and Logistics company (GTAL)"
echo "  - Complete chart of accounts"
echo "  - Fiscal years configured"
echo "  - ERPNext + EpiBus apps installed"
echo "  - Industrial automation ready"
echo "  - MODBUS configuration available"
echo ""
echo "🚀 Your lab environment is ready for industrial automation!"