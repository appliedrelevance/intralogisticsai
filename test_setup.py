import frappe

# Test setup detection
print("frappe.is_setup_complete():", frappe.is_setup_complete())

# Check the installed apps
apps = frappe.get_all("Installed Application", fields=["app_name", "is_setup_complete"])
print("Installed Applications:")
for app in apps:
    print(f"  {app.app_name}: {app.is_setup_complete}")

# Check System Settings
sys_setup = frappe.db.get_single_value("System Settings", "setup_complete")
print("System Settings setup_complete:", sys_setup)