import frappe

print("Testing Frappe import...")
print(f"Current site: {frappe.local.site}")
print("Available doctypes:")
print(f"Company exists: {frappe.db.exists('Company', 'Global Trade and Logistics')}")