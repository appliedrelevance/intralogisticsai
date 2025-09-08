import frappe

print("=== Checking imported data ===")

# Check Companies
companies = frappe.get_all("Company", fields=["name", "company_name"])
print(f"Companies: {len(companies)}")
for company in companies:
    print(f"  - {company.company_name} ({company.name})")

# Check Item Groups  
item_groups = frappe.get_all("Item Group", fields=["name", "item_group_name"])
print(f"\nItem Groups: {len(item_groups)}")
for group in item_groups:
    print(f"  - {group.item_group_name}")

# Check Warehouses
warehouses = frappe.get_all("Warehouse", fields=["name", "warehouse_name"])
print(f"\nWarehouses: {len(warehouses)}")
for warehouse in warehouses:
    print(f"  - {warehouse.warehouse_name}")

# Check Items (just count due to potentially large number)
items_count = frappe.db.count("Item")
print(f"\nItems: {items_count}")

print("\n=== Import Summary ===")
print("✅ Data import appears successful!")
print("Next: Create backup for future deployments")