import frappe

# Check the setup detection
print("frappe.is_setup_complete():", frappe.is_setup_complete())

# Check the boot info
if hasattr(frappe, 'boot'):
    print("frappe.boot.setup_complete:", getattr(frappe.boot, 'setup_complete', 'NOT SET'))
else:
    print("frappe.boot not available")

# Check database directly
apps = frappe.get_all("Installed Application", fields=["app_name", "is_setup_complete"])
print("Database flags:")
for app in apps:
    print(f"  {app.app_name}: {app.is_setup_complete}")
    
sys_setup = frappe.db.get_single_value("System Settings", "setup_complete") 
print("System Settings setup_complete:", sys_setup)