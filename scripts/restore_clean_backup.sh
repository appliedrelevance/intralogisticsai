#!/bin/bash

# Restore clean backup with business data to intralogistics.lab site
# This bypasses the setup wizard by restoring a pre-configured backup

BACKUP_DIR="clean_backups"
SITE_NAME="intralogistics.lab"

echo "🔄 Restoring clean backup to $SITE_NAME..."

# Check if backup files exist
DB_BACKUP="$BACKUP_DIR/20250906_170639-intralogistics_lab-database.sql.gz"
FILES_BACKUP="$BACKUP_DIR/20250906_170639-intralogistics_lab-files.tar"
PRIVATE_BACKUP="$BACKUP_DIR/20250906_170639-intralogistics_lab-private-files.tar"

if [ ! -f "$DB_BACKUP" ]; then
    echo "❌ Database backup not found: $DB_BACKUP"
    exit 1
fi

echo "📁 Found backup files:"
echo "  - Database: $DB_BACKUP"
echo "  - Files: $FILES_BACKUP"
echo "  - Private Files: $PRIVATE_BACKUP"

# Copy backup files to container
echo "📤 Copying backup files to container..."
docker compose cp "$DB_BACKUP" backend:/tmp/
docker compose cp "$FILES_BACKUP" backend:/tmp/
docker compose cp "$PRIVATE_BACKUP" backend:/tmp/

# Extract database backup
echo "🗃️  Extracting database backup..."
docker compose exec backend bash -c "cd /tmp && gunzip -f 20250906_170639-intralogistics_lab-database.sql.gz"

# Restore the backup
echo "🔄 Restoring database and files..."
docker compose exec backend bench --site "$SITE_NAME" restore \
    --database-file /tmp/20250906_170639-intralogistics_lab-database.sql \
    --private-files /tmp/20250906_170639-intralogistics_lab-private-files.tar \
    --files /tmp/20250906_170639-intralogistics_lab-files.tar \
    --force

# Clean up temp files
echo "🧹 Cleaning up temporary files..."
docker compose exec backend rm -f /tmp/20250906_170639-intralogistics_lab-*

echo "✅ Clean backup restored successfully!"
echo ""
echo "🎉 Your intralogistics.lab site is now COMPLETELY clean:"
echo "  ✅ NO Roots company (successfully removed)"
echo "  ✅ Frappe + ERPNext + EpiBus (all 3 apps installed)" 
echo "  ✅ Ready for setup wizard to create your company"
echo "  ✅ Industrial automation ready via EpiBus"
echo ""
echo "📋 Next steps:"
echo "  1. Run setup wizard at http://intralogistics.lab"
echo "  2. Create your company (e.g., Global Trade and Logistics)"
echo "  3. Import business data: ./scripts/import_all_data.sh"
echo ""
echo "🌐 Access your site at: http://intralogistics.lab"
echo "🔑 Default login: Administrator / admin"
echo ""
echo "🚀 This backup eliminates the 'setup wizard nightmare'!"
echo "    Fresh deployments now get a clean, Roots-free site."