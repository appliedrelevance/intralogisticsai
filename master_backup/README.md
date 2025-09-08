# Master Backup - Intralogistics Lab

**Created**: September 6, 2025 at 20:07 UTC  
**Source Site**: intralogistics.lab  
**Backup ID**: 20250906_200713

## Contents

This master backup contains a fully configured intralogistics ERPNext site with:

### ✅ **Apps Installed**
- **Frappe Framework**: Core platform
- **ERPNext**: Enterprise Resource Planning system
- **EpiBus**: Industrial automation integration

### ✅ **Company Setup**
- **Company**: Global Trade and Logistics (GTAL)
- **Currency**: USD
- **Country**: United States
- **Fiscal Year**: 2025 (Jan 1 - Dec 31)
- **Chart of Accounts**: Complete standard chart

### ✅ **Business Data**
- **Items**: At least 1 item configured
- **MODBUS Configuration**: At least 1 MODBUS connection
- **Setup Wizard**: Completed
- **Industrial Automation**: Ready for PLC integration

## Backup Files

| File | Size | Description |
|------|------|-------------|
| `20250906_200713-intralogistics_lab-database.sql.gz` | 806KB | Complete database with all data |
| `20250906_200713-intralogistics_lab-files.tgz` | 137B | Public files and attachments |
| `20250906_200713-intralogistics_lab-private-files.tgz` | 138B | Private files and uploads |
| `20250906_200713-intralogistics_lab-site_config_backup.json` | 94B | Site configuration |

## How to Use This Master Backup

### Method 1: Update deploy.sh (Recommended)
1. Update `deploy.sh` to restore this backup after site creation
2. Uncomment and modify the backup restoration section (around line 566)
3. Point to these master backup files instead of the old backup

### Method 2: Manual Restoration
```bash
# Stop current deployment
./deploy.sh stop

# Start fresh deployment (creates clean site)
./deploy.sh

# Copy backup files to container
docker compose cp master_backup/20250906_200713-intralogistics_lab-database.sql.gz backend:/tmp/
docker compose cp master_backup/20250906_200713-intralogistics_lab-files.tgz backend:/tmp/
docker compose cp master_backup/20250906_200713-intralogistics_lab-private-files.tgz backend:/tmp/

# Restore the backup
echo "123" | docker compose exec -T backend bench --site intralogistics.lab restore /tmp/20250906_200713-intralogistics_lab-database.sql.gz --with-public-files /tmp/20250906_200713-intralogistics_lab-files.tgz --with-private-files /tmp/20250906_200713-intralogistics_lab-private-files.tgz --force
```

### Method 3: Use restore_master_backup.sh
Run the included restore script: `./master_backup/restore_master_backup.sh`

## What You Get After Restoration

- ✅ **Ready-to-use ERPNext system**
- ✅ **Global Trade and Logistics company fully configured**
- ✅ **Complete chart of accounts and fiscal years**
- ✅ **EpiBus ready for industrial automation**
- ✅ **No setup wizard needed**
- ✅ **Login**: Administrator / admin
- ✅ **Industrial automation ready** via EpiBus

## Notes

- This backup completely bypasses the "setup wizard nightmare"
- Perfect for rapid deployment of configured lab environments
- Contains working MODBUS configuration for PLC integration
- All three apps (Frappe, ERPNext, EpiBus) are properly integrated
- Chart of accounts and fiscal years are properly initialized

## Next Steps After Restoration

1. Access the site: `http://intralogistics.lab`
2. Login: `Administrator` / `admin`
3. Import additional business data as needed
4. Configure additional MODBUS connections via EpiBus
5. Start industrial automation workflows