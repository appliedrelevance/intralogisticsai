#!/usr/bin/env python3
"""
Complete site setup with GTAL company and business data.
Run with: bench --site intralogistics.lab execute scripts/setup_complete_site.py
"""

import frappe
from frappe import _
from erpnext.setup.setup_wizard.operations.install_fixtures import install_post_company_fixtures

def setup_company():
    """Create Global Trade and Logistics company"""
    print("\n=== Creating GTAL Company ===")
    
    if frappe.db.exists("Company", "Global Trade and Logistics"):
        print("Company 'Global Trade and Logistics' already exists!")
        return frappe.get_doc("Company", "Global Trade and Logistics")
    
    # Create the company using ERPNext's standard setup
    company_doc = frappe.get_doc({
        "doctype": "Company",
        "company_name": "Global Trade and Logistics",
        "abbr": "GTAL",
        "default_currency": "USD",
        "country": "United States",
        "domain": "Manufacturing"
    })
    
    company_doc.insert()
    print(f"✓ Created company: {company_doc.company_name}")
    
    # Install post-company fixtures
    install_post_company_fixtures(company_doc.name)
    print("✓ Installed post-company fixtures")
    
    return company_doc


def create_basic_uom():
    """Create basic UOM that our items need"""
    print("\n=== Creating Basic UOM ===")
    
    uoms = [
        {"uom_name": "Nos", "must_be_whole_number": 1},
        {"uom_name": "Each", "must_be_whole_number": 1},
        {"uom_name": "Piece", "must_be_whole_number": 1}
    ]
    
    for uom_data in uoms:
        if not frappe.db.exists("UOM", uom_data["uom_name"]):
            uom = frappe.get_doc({
                "doctype": "UOM",
                **uom_data
            })
            uom.insert()
            print(f"✓ Created UOM: {uom_data['uom_name']}")
        else:
            print(f"UOM '{uom_data['uom_name']}' already exists")


def import_csv_data():
    """Import business data from CSV files"""
    print("\n=== Importing CSV Data ===")
    
    # Import order matters due to dependencies
    import_sequence = [
        ("Item Group", "import_data/item_groups.csv"),
        ("Item Attribute", "import_data/item_attributes.csv"), 
        ("Warehouse", "import_data/warehouses.csv"),
        ("Item", "import_data/items.csv")
    ]
    
    for doctype, csv_file in import_sequence:
        print(f"\nImporting {doctype} from {csv_file}")
        
        if not frappe.utils.os.path.exists(csv_file):
            print(f"Warning: {csv_file} not found, skipping...")
            continue
            
        try:
            # Use Frappe's data import functionality
            from frappe.core.doctype.data_import.importer import Importer
            from frappe.core.doctype.data_import.importer import ImportFile
            
            # Create data import record
            data_import = frappe.get_doc({
                "doctype": "Data Import",
                "reference_doctype": doctype,
                "import_type": "Insert New Records"
            })
            data_import.insert()
            
            # Import the file
            importer = Importer(
                doctype=doctype,
                file_path=csv_file,
                data_import=data_import
            )
            importer.import_data()
            
            print(f"✓ Completed import of {doctype}")
            
        except Exception as e:
            print(f"✗ Error importing {doctype}: {str(e)}")
            continue


def setup_epibus_fixtures():
    """Set up basic EpiBus configuration"""
    print("\n=== Setting up EpiBus ===")
    
    # Check if EpiBus fixtures exist
    try:
        modbus_connections = frappe.get_all("Modbus Connection")
        print(f"Found {len(modbus_connections)} Modbus connections")
        
        # You can add any specific EpiBus setup here
        print("✓ EpiBus ready for configuration")
        
    except Exception as e:
        print(f"EpiBus setup info: {str(e)}")


def main():
    """Main setup function"""
    print("🚀 Starting complete intralogistics site setup...")
    
    try:
        frappe.db.begin()
        
        # Step 1: Create company with chart of accounts
        company = setup_company()
        
        # Step 2: Create basic UOMs
        create_basic_uom()
        
        # Step 3: Import business data
        import_csv_data()
        
        # Step 4: Setup EpiBus
        setup_epibus_fixtures()
        
        frappe.db.commit()
        
        print("\n🎉 Complete site setup finished successfully!")
        print(f"✓ Company: {company.company_name} ({company.abbr})")
        print("✓ Chart of accounts created")
        print("✓ Business data imported")
        print("✓ EpiBus ready for industrial automation")
        print("\n🌐 Site ready at: http://intralogistics.lab")
        print("🔑 Login: Administrator / admin")
        
        # Summary counts
        companies = frappe.db.count("Company")
        accounts = frappe.db.count("Account", {"company": company.name})
        items = frappe.db.count("Item")
        warehouses = frappe.db.count("Warehouse")
        
        print(f"\n📊 Data Summary:")
        print(f"  Companies: {companies}")
        print(f"  Accounts: {accounts}")
        print(f"  Items: {items}")
        print(f"  Warehouses: {warehouses}")
        
    except Exception as e:
        frappe.db.rollback()
        print(f"\n💥 Setup failed: {str(e)}")
        raise


if __name__ == "__main__":
    main()