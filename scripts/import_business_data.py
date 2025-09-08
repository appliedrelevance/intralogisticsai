#!/usr/bin/env python3
"""
Import business data from CSV files into Frappe/ERPNext site.
Run with: bench --site intralogistics.lab execute scripts/import_business_data.py
"""

import csv
import os
import sys
import frappe
from frappe import _


def init_frappe():
    """Initialize Frappe context"""
    frappe.init(site="intralogistics.lab")
    frappe.connect()


def read_csv_file(filename):
    """Read CSV file and return list of dictionaries"""
    filepath = os.path.join("import_data", filename)
    if not os.path.exists(filepath):
        print(f"Warning: {filepath} not found, skipping...")
        return []
    
    with open(filepath, 'r', encoding='utf-8') as file:
        reader = csv.DictReader(file)
        return [row for row in reader if any(row.values())]  # Skip empty rows


def import_companies():
    """Import companies from CSV"""
    print("\n=== Importing Companies ===")
    companies = read_csv_file("companies.csv")
    
    for company_data in companies:
        try:
            # Check if company already exists
            if frappe.db.exists("Company", company_data["company_name"]):
                print(f"Company '{company_data['company_name']}' already exists, skipping...")
                continue
            
            company = frappe.get_doc({
                "doctype": "Company",
                "company_name": company_data["company_name"],
                "abbr": company_data["abbr"],
                "default_currency": company_data["default_currency"],
                "country": company_data["country"]
            })
            company.insert()
            print(f"✓ Created company: {company_data['company_name']}")
            
        except Exception as e:
            print(f"✗ Error creating company {company_data.get('company_name', 'Unknown')}: {str(e)}")


def import_item_groups():
    """Import item groups from CSV in hierarchical order"""
    print("\n=== Importing Item Groups ===")
    item_groups = read_csv_file("item_groups.csv")
    
    # Sort to ensure parent groups are created before children
    # Groups without parent_item_group should be created first
    item_groups.sort(key=lambda x: (x["parent_item_group"] or "", x["item_group_name"]))
    
    for group_data in item_groups:
        try:
            # Check if item group already exists
            if frappe.db.exists("Item Group", group_data["item_group_name"]):
                print(f"Item Group '{group_data['item_group_name']}' already exists, skipping...")
                continue
            
            item_group = frappe.get_doc({
                "doctype": "Item Group",
                "item_group_name": group_data["item_group_name"],
                "parent_item_group": group_data["parent_item_group"] or None,
                "is_group": int(group_data["is_group"]) if group_data["is_group"] else 0
            })
            item_group.insert()
            print(f"✓ Created item group: {group_data['item_group_name']}")
            
        except Exception as e:
            print(f"✗ Error creating item group {group_data.get('item_group_name', 'Unknown')}: {str(e)}")


def import_item_attributes():
    """Import item attributes from CSV"""
    print("\n=== Importing Item Attributes ===")
    attributes = read_csv_file("item_attributes.csv")
    
    for attr_data in attributes:
        try:
            # Check if attribute already exists
            if frappe.db.exists("Item Attribute", attr_data["attribute_name"]):
                print(f"Item Attribute '{attr_data['attribute_name']}' already exists, skipping...")
                continue
            
            attribute = frappe.get_doc({
                "doctype": "Item Attribute",
                "attribute_name": attr_data["attribute_name"]
            })
            attribute.insert()
            print(f"✓ Created item attribute: {attr_data['attribute_name']}")
            
        except Exception as e:
            print(f"✗ Error creating item attribute {attr_data.get('attribute_name', 'Unknown')}: {str(e)}")


def import_item_attribute_values():
    """Import item attribute values from CSV"""
    print("\n=== Importing Item Attribute Values ===")
    values = read_csv_file("item_attribute_values.csv")
    
    for value_data in values:
        try:
            # Check if attribute value already exists
            if frappe.db.exists("Item Attribute Value", {
                "parent": value_data["parent_attribute"],
                "attribute_value": value_data["attribute_value"]
            }):
                print(f"Attribute Value '{value_data['attribute_value']}' for '{value_data['parent_attribute']}' already exists, skipping...")
                continue
            
            # Get the parent Item Attribute document
            parent_attribute = frappe.get_doc("Item Attribute", value_data["parent_attribute"])
            
            # Add the attribute value to the parent
            parent_attribute.append("item_attribute_values", {
                "attribute_value": value_data["attribute_value"],
                "abbr": value_data["abbr"]
            })
            parent_attribute.save()
            print(f"✓ Added attribute value: {value_data['attribute_value']} to {value_data['parent_attribute']}")
            
        except Exception as e:
            print(f"✗ Error creating attribute value {value_data.get('attribute_value', 'Unknown')}: {str(e)}")


def import_warehouses():
    """Import warehouses from CSV in hierarchical order"""
    print("\n=== Importing Warehouses ===")
    warehouses = read_csv_file("warehouses.csv")
    
    # Sort to ensure parent warehouses are created before children
    warehouses.sort(key=lambda x: (x["parent_warehouse"] or "", x["warehouse_name"]))
    
    for warehouse_data in warehouses:
        try:
            # Check if warehouse already exists
            if frappe.db.exists("Warehouse", warehouse_data["warehouse_name"]):
                print(f"Warehouse '{warehouse_data['warehouse_name']}' already exists, skipping...")
                continue
            
            warehouse = frappe.get_doc({
                "doctype": "Warehouse",
                "warehouse_name": warehouse_data["warehouse_name"],
                "is_group": int(warehouse_data["is_group"]) if warehouse_data["is_group"] else 0,
                "parent_warehouse": warehouse_data["parent_warehouse"] or None,
                "disabled": int(warehouse_data["disabled"]) if warehouse_data["disabled"] else 0,
                "company": warehouse_data["company"] or None
            })
            warehouse.insert()
            print(f"✓ Created warehouse: {warehouse_data['warehouse_name']}")
            
        except Exception as e:
            print(f"✗ Error creating warehouse {warehouse_data.get('warehouse_name', 'Unknown')}: {str(e)}")


def import_items():
    """Import items from CSV"""
    print("\n=== Importing Items ===")
    items = read_csv_file("items.csv")
    
    for item_data in items:
        try:
            # Check if item already exists
            if frappe.db.exists("Item", item_data["item_code"]):
                print(f"Item '{item_data['item_code']}' already exists, skipping...")
                continue
            
            # Convert string booleans to integers
            def to_int_bool(value):
                return 1 if str(value).lower() in ['1', 'true', 'yes'] else 0
            
            item = frappe.get_doc({
                "doctype": "Item",
                "item_code": item_data["item_code"],
                "item_name": item_data["item_name"],
                "item_group": item_data["item_group"],
                "stock_uom": item_data["stock_uom"],
                "disabled": to_int_bool(item_data["disabled"]),
                "is_stock_item": to_int_bool(item_data["is_stock_item"]),
                "has_variants": to_int_bool(item_data["has_variants"]),
                "valuation_rate": float(item_data["valuation_rate"]) if item_data["valuation_rate"] else 0.0,
                "standard_rate": float(item_data["standard_rate"]) if item_data["standard_rate"] else 0.0,
                "description": item_data["description"],
                "is_purchase_item": to_int_bool(item_data["is_purchase_item"]),
                "is_sales_item": to_int_bool(item_data["is_sales_item"]),
                "country_of_origin": item_data["country_of_origin"]
            })
            item.insert()
            print(f"✓ Created item: {item_data['item_code']}")
            
        except Exception as e:
            print(f"✗ Error creating item {item_data.get('item_code', 'Unknown')}: {str(e)}")


def main():
    """Main import function"""
    print("Starting business data import...")
    
    init_frappe()
    
    try:
        frappe.db.begin()
        
        # Import in dependency order
        import_companies()
        import_item_groups()
        import_item_attributes()
        import_item_attribute_values()
        import_warehouses()
        import_items()
        
        frappe.db.commit()
        print("\n🎉 Business data import completed successfully!")
        print("\nNext steps:")
        print("1. Review imported data in the web interface")
        print("2. Run: bench --site intralogistics.lab backup")
        print("3. Store the backup for future deployments")
        
    except Exception as e:
        try:
            frappe.db.rollback()
        except:
            pass
        print(f"\n💥 Import failed with error: {str(e)}")
        print("All changes have been rolled back.")
        raise
    
    finally:
        frappe.destroy()


if __name__ == "__main__":
    main()