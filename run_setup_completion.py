from epibus.epibus.install import complete_setup_wizard
import frappe

print("Running setup wizard completion...")
complete_setup_wizard()
print("Setup completed!")

# Verify results
print("is_setup_complete():", frappe.is_setup_complete())
apps = frappe.get_all("Installed Application", fields=["app_name", "is_setup_complete"])
print("Apps:")
for app in apps:
    print(f"  {app.app_name}: {app.is_setup_complete}")