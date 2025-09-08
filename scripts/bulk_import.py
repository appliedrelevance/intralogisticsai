#!/usr/bin/env python3
"""
Import business data from CSV files using Frappe's Data Import tool.
Run as: bench --site intralogistics.lab execute scripts.bulk_import.main
"""

import csv
import os
import frappe
from frappe.core.doctype.data_import.data_import import DataImport


def create_data_import(doctype, csv_file_path):
    """Create a data import record and execute it"""
    if not os.path.exists(csv_file_path):
        frappe.throw(f"CSV file not found: {csv_file_path}")
    
    # Read CSV content
    with open(csv_file_path, 'r', encoding='utf-8') as f:
        csv_content = f.read()
    
    # Create Data Import document
    data_import = frappe.get_doc({
        "doctype": "Data Import",
        "import_type": "Insert New Records",
        "reference_doctype": doctype,
        "import_file": None,  # We'll set the content directly
    })
    
    # Set the CSV content directly
    data_import.payload = csv_content
    data_import.save()
    
    # Start the import
    data_import.start_import()
    
    return data_import


def main():
    """Main import function"""
    print("Starting business data import using Frappe Data Import tool...")
    
    import_files = [
        ("Company", "import_data/companies.csv"),
        ("Item Group", "import_data/item_groups.csv"),
        ("Item Attribute", "import_data/item_attributes.csv"),
        ("Warehouse", "import_data/warehouses.csv"),
        ("Item", "import_data/items.csv"),
    ]
    
    for doctype, csv_file in import_files:
        print(f"\n=== Importing {doctype} from {csv_file} ===")
        
        try:
            if not os.path.exists(csv_file):
                print(f"Warning: {csv_file} not found, skipping...")
                continue
                
            data_import = create_data_import(doctype, csv_file)
            print(f"✓ Created Data Import: {data_import.name}")
            
            # Wait for import to complete and check status
            data_import.reload()
            if data_import.status == "Success":
                print(f"✓ Successfully imported {doctype}")
            else:
                print(f"⚠ Import status: {data_import.status}")
                if data_import.error_log:
                    print(f"Error log: {data_import.error_log}")
                    
        except Exception as e:
            print(f"✗ Error importing {doctype}: {str(e)}")
    
    print("\n🎉 Business data import process completed!")
    print("\nNext steps:")
    print("1. Review Data Import records in the web interface")
    print("2. Check import logs for any errors")
    print("3. Run: bench --site intralogistics.lab backup")


if __name__ == "__main__":
    main()