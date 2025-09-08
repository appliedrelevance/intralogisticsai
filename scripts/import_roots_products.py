#!/usr/bin/env python3
"""
Import Roots products directly into ERPNext
"""

import frappe
import csv
import os

def import_item_groups():
    """Import item groups first"""
    print("📦 Creating Item Groups...")
    
    groups = [
        {"item_group_name": "3D Printed Parts", "parent_item_group": "All Item Groups"},
        {"item_group_name": "Hardware", "parent_item_group": "All Item Groups"},
        {"item_group_name": "Product Bundles", "parent_item_group": "All Item Groups"},
        {"item_group_name": "Products", "parent_item_group": "All Item Groups"},
        {"item_group_name": "Template", "parent_item_group": "All Item Groups"},
    ]
    
    for group in groups:
        if not frappe.db.exists("Item Group", group["item_group_name"]):
            doc = frappe.get_doc({
                "doctype": "Item Group",
                "item_group_name": group["item_group_name"],
                "parent_item_group": group["parent_item_group"],
                "is_group": 0
            })
            doc.insert()
            print(f"  ✓ Created Item Group: {group['item_group_name']}")
        else:
            print(f"  ✓ Item Group exists: {group['item_group_name']}")

def import_warehouses():
    """Import warehouses"""
    print("🏢 Creating Warehouses...")
    
    warehouses = [
        {"warehouse_name": "Main Store", "company": "Global Trade and Logistics"},
        {"warehouse_name": "Production", "company": "Global Trade and Logistics"},
        {"warehouse_name": "Finished Goods", "company": "Global Trade and Logistics"}
    ]
    
    for warehouse in warehouses:
        if not frappe.db.exists("Warehouse", warehouse["warehouse_name"] + " - GTAL"):
            doc = frappe.get_doc({
                "doctype": "Warehouse",
                "warehouse_name": warehouse["warehouse_name"],
                "company": warehouse["company"]
            })
            doc.insert()
            print(f"  ✓ Created Warehouse: {warehouse['warehouse_name']}")
        else:
            print(f"  ✓ Warehouse exists: {warehouse['warehouse_name']}")

def import_items_from_csv():
    """Import items from CSV file"""
    print("📱 Importing Roots Products...")
    
    csv_path = "/home/frappe/frappe-bench/import_data/items.csv"
    
    with open(csv_path, 'r') as file:
        reader = csv.DictReader(file)
        count = 0
        
        for row in reader:
            item_code = row['item_code'].strip()
            
            if frappe.db.exists("Item", item_code):
                print(f"  ✓ Item exists: {item_code}")
                continue
                
            try:
                # Create the item
                doc = frappe.get_doc({
                    "doctype": "Item",
                    "item_code": item_code,
                    "item_name": row['item_name'].strip(),
                    "item_group": row['item_group'].strip(),
                    "stock_uom": row['stock_uom'].strip(),
                    "is_stock_item": int(row['is_stock_item']),
                    "is_purchase_item": int(row['is_purchase_item']),
                    "is_sales_item": int(row['is_sales_item']),
                    "description": row['description'].strip(),
                    "country_of_origin": row.get('country_of_origin', 'United States').strip(),
                    "valuation_rate": float(row.get('valuation_rate', 0)),
                    "standard_rate": float(row.get('standard_rate', 0)),
                    "has_variants": int(row.get('has_variants', 0)),
                    "disabled": int(row.get('disabled', 0))
                })
                
                doc.insert()
                count += 1
                print(f"  ✓ Created Item: {item_code} - {row['item_name'].strip()}")
                
            except Exception as e:
                print(f"  ✗ Failed to create {item_code}: {str(e)}")
                
    print(f"📊 Successfully imported {count} Roots products!")

def main():
    """Main import function"""
    print("🚀 Starting Roots Products Import...")
    print("=" * 50)
    
    try:
        frappe.init(site='intralogistics.lab')
        frappe.connect()
        
        # Import in dependency order
        import_item_groups()
        import_warehouses()
        import_items_from_csv()
        
        frappe.db.commit()
        print("\n🎉 Import completed successfully!")
        
        # Summary
        items = frappe.db.count("Item")
        item_groups = frappe.db.count("Item Group")
        warehouses = frappe.db.count("Warehouse")
        
        print(f"\n📊 Current Inventory:")
        print(f"  Items: {items}")
        print(f"  Item Groups: {item_groups}")
        print(f"  Warehouses: {warehouses}")
        
    except Exception as e:
        frappe.db.rollback()
        print(f"❌ Import failed: {str(e)}")
        import traceback
        traceback.print_exc()
        raise
    finally:
        frappe.destroy()

if __name__ == "__main__":
    main()