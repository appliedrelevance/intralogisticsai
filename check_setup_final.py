#!/usr/bin/env python3
import frappe

print("=== FINAL SETUP CHECK ===")
print("frappe.is_setup_complete():", frappe.is_setup_complete())

# Check boot info
boot_complete = getattr(frappe.boot, 'setup_complete', 'NOT SET')
print("frappe.boot.setup_complete:", boot_complete)

# Check database flags
apps = frappe.get_all("Installed Application", fields=["name", "app_name", "is_setup_complete"])
print("App setup flags:")
for app in apps:
    print(f"  {app.app_name} ({app.name}): {app.is_setup_complete}")
    
sys_setup = frappe.db.get_single_value("System Settings", "setup_complete") 
print("System Settings.setup_complete:", sys_setup)

# Check site config
import frappe.utils
site_config = frappe.utils.get_site_config()
print("skip_setup_wizard config:", site_config.get('skip_setup_wizard', 'NOT SET'))

# Check what the actual boot response would be  
from frappe.boot import get_bootinfo
boot_info = get_bootinfo()
print("Boot info setup_complete:", boot_info.get('setup_complete', 'NOT SET'))
print("Boot info home_page:", boot_info.get('home_page', 'NOT SET'))