# Golden Master Backup - September 30, 2025

**Created**: 2025-09-30 17:56:10 UTC

## Contents

This Golden Master backup includes a fully configured IntraLogistics ERP system with:

### ✅ Core Configuration
- **Site**: intralogistics.lab
- **Company**: Global Trade and Logistics (GTAL)
- **ERPNext Version**: v15.64.1
- **Frappe Version**: 15.84.0
- **EpiBus Version**: 0.1.0

### ✅ Business Data
- **Items**: 200+ product catalog (bracelets, keychains, wallets, t-shirts, 3D printed components)
- **Item Attributes**: Color and Size variants
- **Item Groups**: 3D Printed Parts, Hardware, Products, Templates
- **Item Prices**: All items have selling prices configured in "Standard Selling" price list
- **Item Valuation**: All items have valuation rates set for proper stock accounting
- **Stock Items**: All sellable products properly configured as stock items (9 items fixed from non-stock)
- **Warehouses**: 23 total warehouses with proper hierarchy and accounting defaults
  - All warehouses configured with "Stock In Hand - GTAL" account
  - Storage bins (1-12) ready for automation
  - Receiving Station 1 and Pick & Pack Station 2 for robot operations

### ✅ Industrial Automation (EpiBus)
- **MODBUS Connection**: "Roots Intralogistics Learning Lab" fully configured
- **Signals**: All PLC signals mapped to warehouses
  - PICK_BIN_1 through PICK_BIN_12 → Storage bins
  - TO_RECEIVING_STA_1 → Receiving station
  - TO_PICKPACK_STA_2 → Pick & Pack station
  - FROM_RECEIVING_STA_1, FROM_PICKPACK_STA_2
  - PICK_TO_RECEIVING_IN_PROCESS, PICK_TO_PICKPACK_IN_PROCESS
- **Server Scripts**: Fixed and working
  - **Purchase Receipt** → Move Bin to Receiving (triggers PICK_BIN_X + TO_RECEIVING_STA_1)
  - **Pick List** → Move Bin to Pick Pack (triggers PICK_BIN_X + TO_PICKPACK_STA_2)
  - POS Invoice automation disabled (superseded by Pick List workflow)

### ✅ Sample Data
- **Customers**: 5 cash customers ready for testing (Sarah Mitchell, James Chen, Maria Rodriguez, David Thompson, Emily Johnson)
- **Stock**: 1000 green bracelets in Storage Bin 12 - GTAL
- **Sales Order**: SAL-ORD-2025-00001 (submitted, ready for Pick List generation)

### ✅ Fixed Issues
- Server scripts now correctly trigger both bin and station signals
- Uses explicit signal names instead of warehouse lookup to avoid ambiguity
- Warehouse accounting defaults configured (no more "No accounting entries" errors)
- Removed frappe.logger() calls that caused errors in server scripts
- Stock item flags properly set for all sellable products
- Valuation rates set for proper stock accounting
- Selling prices configured for all items

## Backup Files

1. **GOLDEN_MASTER_20250930-intralogistics_lab-database.sql.gz** (868KB)
   - Complete database with all data and configurations

2. **GOLDEN_MASTER_20250930-intralogistics_lab-files.tar** (10KB)
   - Public files (uploaded files, attachments)

3. **GOLDEN_MASTER_20250930-intralogistics_lab-private-files.tar** (10KB)
   - Private files (confidential documents)

4. **GOLDEN_MASTER_20250930-intralogistics_lab-site_config_backup.json** (193B)
   - Site configuration

## How to Restore

### Method 1: Using the restore script (inside backend container)
```bash
docker compose exec backend /home/frappe/restore_golden_master.sh
```

### Method 2: Manual restore
```bash
# Copy backup files to container
docker compose cp master_backup/GOLDEN_MASTER_20250930-intralogistics_lab-database.sql.gz backend:/home/frappe/frappe-bench/sites/intralogistics.lab/private/backups/

# Restore database
docker compose exec backend bench --site intralogistics.lab --force restore \
  sites/intralogistics.lab/private/backups/GOLDEN_MASTER_20250930-intralogistics_lab-database.sql.gz \
  --mariadb-root-password 123
```

## What's Working

✅ Purchase Receipt submission triggers robot to move bin to Receiving Station
✅ Pick List submission triggers robot to move bin to Pick & Pack Station (NEW!)
✅ All warehouse accounting properly configured
✅ MODBUS signals mapped correctly
✅ No more signal triggering ambiguity
✅ Stock items properly configured with prices and valuation rates
✅ Sales Order workflow with Pick List generation

## Pick List Workflow

The recommended workflow for order fulfillment:

1. **Create Sales Order** with customer and items
2. **Submit Sales Order**
3. **Create Pick List** from Sales Order (ERPNext auto-selects correct storage bin)
4. **Submit Pick List** → Robot automatically moves bin to Pick & Pack Station 2
5. **Create Delivery Note** from Pick List
6. **Create Sales Invoice** from Delivery Note

## Login Credentials

- **URL**: http://localhost:9000 or http://intralogistics.lab
- **Username**: Administrator
- **Password**: admin

## API Access

API keys are available in the system:
- Use Frappe's API token authentication
- Example: `Authorization: token <api_key>:<api_secret>`

## Notes

- This backup represents a clean, working state with Pick List automation
- All warehouses have proper accounting configuration
- Server scripts use correct field names (warehouse, not target_warehouse)
- No logger calls that would break in server script context
- Stock items properly configured (not non-stock items)
- POS profile set to "Storage Area - GTAL" with hide_unavailable_items disabled
- Known Issue: ERPNext doesn't aggregate stock from child warehouses to parent warehouses in POS queries (ERPNext limitation)
