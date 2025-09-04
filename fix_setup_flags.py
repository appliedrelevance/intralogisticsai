#!/usr/bin/env python3
import frappe

# Update the setup completion flags in the database
frappe.db.sql("""UPDATE `tabInstalled Application` 
                 SET is_setup_complete = 1 
                 WHERE app_name IN ('frappe', 'erpnext')""")

# Also set System Settings for completeness
frappe.db.set_single_value("System Settings", "setup_complete", 1)

# Commit the changes
frappe.db.commit()

print("✅ Setup completion flags updated successfully!")
print("Checking results:")
apps = frappe.get_all("Installed Application", fields=["name", "app_name", "is_setup_complete"])
for app in apps:
    print(f"  {app.app_name}: is_setup_complete = {app.is_setup_complete}")

sys_setup = frappe.db.get_single_value("System Settings", "setup_complete") 
print(f"System Settings.setup_complete: {sys_setup}")