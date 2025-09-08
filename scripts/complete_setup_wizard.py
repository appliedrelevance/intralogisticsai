#!/usr/bin/env python3

import os
import sys

def main():
    site_name = sys.argv[1] if len(sys.argv) > 1 else 'intralogistics.lab'
    
    print(f"🚀 Complete setup wizard for site: {site_name}")
    
    # Change to the frappe-bench directory to ensure proper imports
    os.chdir("/home/frappe/frappe-bench")
    sys.path.insert(0, "/home/frappe/frappe-bench")
    
    try:
        import frappe
        
        # Initialize the site
        frappe.init(site=site_name)
        frappe.connect()
        
        # Check if setup is already complete
        if frappe.is_setup_complete():
            print("✅ Setup wizard already completed")
            return 0
        
        print("🔧 Completing ERPNext setup wizard...")
        
        # Setup wizard data matching ERPNext's expected structure
        setup_data = frappe._dict({
            "language": "en",
            "country": "United States", 
            "timezone": "America/New_York",
            "currency": "USD",
            "full_name": "Administrator",
            "email": "admin@intralogistics.lab",
            "company_name": "Global Trade and Logistics",
            "company_abbr": "GTAL",
            "fy_start_date": "2025-01-01",
            "fy_end_date": "2025-12-31",
            "domains": ["Manufacturing"],
            "chart_of_accounts": "Standard",
        })
        
        # Use ERPNext's official setup_complete function
        print("📊 Running ERPNext setup wizard completion...")
        from erpnext.setup.setup_wizard.setup_wizard import setup_complete
        setup_complete(setup_data)
        print("✅ ERPNext setup wizard completed")
        
        # Update the existing company with proper details
        print("🏢 Updating company configuration...")
        company = frappe.get_doc("Company", "Global Trade and Logistics")
        company.update({
            "default_currency": "USD",
            "country": "United States",
            "chart_of_accounts": "Standard",
            "create_chart_of_accounts_based_on": "Standard Template",
            "enable_perpetual_inventory": 1
        })
        company.save()
        print("✅ Company configuration updated")
        
        # Create chart of accounts if not exists
        accounts_count = frappe.db.sql("SELECT COUNT(*) FROM tabAccount WHERE company = %s", (company.name,))[0][0]
        if accounts_count == 0:
            print("📊 Creating chart of accounts...")
            from erpnext.accounts.doctype.account.chart_of_accounts.chart_of_accounts import create_charts
            create_charts("Global Trade and Logistics", "Standard", "United States")
            print("✅ Chart of accounts created")
        
        # Set global defaults
        print("🌐 Setting global defaults...")
        from erpnext.setup.setup_wizard.operations.install_fixtures import set_global_defaults
        set_global_defaults(setup_data)
        print("✅ Global defaults set")
        
        # Mark apps as setup complete
        print("🏁 Marking apps as setup complete...")
        frappe.db.set_value("Installed Application", {"app_name": "frappe"}, "is_setup_complete", 1)
        frappe.db.set_value("Installed Application", {"app_name": "erpnext"}, "is_setup_complete", 1)
        frappe.db.set_single_value("System Settings", "setup_complete", 1)
        
        # Commit all changes
        frappe.db.commit()
        
        # Verify setup completion
        print("🔍 Verifying setup completion...")
        companies = frappe.db.sql("SELECT COUNT(*) FROM tabCompany")[0][0]
        fiscal_years = frappe.db.sql("SELECT COUNT(*) FROM `tabFiscal Year`")[0][0]
        accounts = frappe.db.sql("SELECT COUNT(*) FROM tabAccount")[0][0]
        uoms = frappe.db.sql("SELECT COUNT(*) FROM tabUOM")[0][0]
        setup_complete = frappe.is_setup_complete()
        
        print(f"✅ Verification Results:")
        print(f"   - Companies: {companies}")
        print(f"   - Fiscal Years: {fiscal_years}")
        print(f"   - Accounts: {accounts}")
        print(f"   - UOMs: {uoms}")
        print(f"   - Setup Complete: {setup_complete}")
        
        if companies > 0 and fiscal_years > 0 and accounts > 0 and uoms > 0 and setup_complete:
            print("🎉 Setup wizard completion verified successfully!")
            return 0
        else:
            print("❌ Setup verification failed - not all components were created")
            return 1
            
    except Exception as e:
        print(f"❌ Setup failed with error: {str(e)}")
        import traceback
        traceback.print_exc()
        if 'frappe' in locals() and frappe.db:
            frappe.db.rollback()
        return 1
    finally:
        if 'frappe' in locals() and frappe.db:
            frappe.destroy()

if __name__ == '__main__':
    sys.exit(main())