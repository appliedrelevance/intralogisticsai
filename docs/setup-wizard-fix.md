# Setup Wizard Bypass Fix

## Problem
After EpiBus installation, the Frappe/ERPNext setup wizard kept appearing even when setup was complete, preventing direct access to the desk.

## Root Cause
Frappe's setup wizard detection logic checks the `Installed Application` table, **NOT** the `System Settings.setup_complete` flag. Specifically, it requires both `frappe` and `erpnext` apps to have `is_setup_complete = 1` in the database.

## The Detection Logic
```python
# From frappe/__init__.py
def is_setup_complete():
    return all(
        frappe.get_all(
            "Installed Application", 
            {"app_name": ("in", ["frappe", "erpnext"])},
            pluck="is_setup_complete"
        )
    )
```

## Solution Implemented
Updated `/mnt/c/Users/Geordie/Code/intralogisticsai/epibus/epibus/install.py` to properly mark both apps as setup complete:

```python
def complete_setup_wizard():
    # ... setup wizard data preparation ...
    
    # Complete ERPNext's business setup (creates companies, UOMs, etc.)
    from erpnext.setup.setup_wizard.setup_wizard import setup_complete as erpnext_setup_complete
    erpnext_setup_complete(setup_data)
    
    # Mark both frappe and erpnext apps as setup complete (this is what Frappe actually checks)
    frappe.db.set_value("Installed Application", {"app_name": "frappe"}, "is_setup_complete", 1)
    frappe.db.set_value("Installed Application", {"app_name": "erpnext"}, "is_setup_complete", 1)
    
    # Also set System Settings for completeness
    frappe.db.set_single_value("System Settings", "setup_complete", 1)
    
    frappe.db.commit()
```

## Key Insight
ERPNext's `setup_complete()` function creates all the business data (companies, UOMs, etc.) but **does not** mark the apps as setup complete in the `Installed Application` table. This must be done separately.

## Database Tables Involved
1. **`tabInstalled Application`** - Primary check for setup completion
   - `frappe` app: `is_setup_complete = 1` ✅
   - `erpnext` app: `is_setup_complete = 1` ✅

2. **`tabSingles` (System Settings)** - Secondary flag
   - `setup_complete = 1` ✅

## Cache Clearing
After making database changes manually, clear cache and restart services:
```bash
docker compose exec backend bench --site intralogistics.lab clear-cache
docker compose restart backend frontend
```

## Browser Cache
Users may need to log out and log back in, or clear browser cache, for changes to take effect.

## Testing
Verify setup completion with:
```python
import frappe
print("Setup complete:", frappe.is_setup_complete())  # Should return True
```

## Files Modified
- `/mnt/c/Users/Geordie/Code/intralogisticsai/epibus/epibus/install.py:58-71`