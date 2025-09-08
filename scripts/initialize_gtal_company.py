#!/usr/bin/env python3
"""
Initialize GTAL company with proper ERPNext setup
"""

import frappe
from frappe import _
from erpnext.setup.setup_wizard.operations.install_fixtures import install_company

def initialize_company():
    """Initialize GTAL company with chart of accounts and fiscal year"""
    print("🚀 Initializing GTAL company...")
    
    frappe.init(site='intralogistics.lab')
    frappe.connect()
    
    try:
        company_name = "Global Trade and Logistics"
        
        # Get the company document
        if not frappe.db.exists("Company", company_name):
            print(f"❌ Company '{company_name}' not found!")
            return
            
        company_doc = frappe.get_doc("Company", company_name)
        print(f"✓ Found company: {company_doc.name} ({company_doc.abbr})")
        
        # Check if chart of accounts already exists
        accounts_count = frappe.db.count("Account", {"company": company_name})
        if accounts_count > 0:
            print(f"Chart of accounts already exists ({accounts_count} accounts)")
        else:
            print("📊 Creating chart of accounts...")
            
            # Install company fixtures (creates chart of accounts)
            install_company(company_name, company_doc.abbr, company_doc.domain, company_doc.country)
            
            accounts_count = frappe.db.count("Account", {"company": company_name})
            print(f"✓ Created chart of accounts with {accounts_count} accounts")
        
        # Check fiscal year
        fiscal_years_count = frappe.db.count("Fiscal Year")
        if fiscal_years_count == 0:
            print("📅 Creating fiscal year...")
            
            from datetime import datetime
            current_year = datetime.now().year
            
            # Create current fiscal year
            fiscal_year = frappe.get_doc({
                "doctype": "Fiscal Year",
                "year": str(current_year),
                "year_start_date": f"{current_year}-01-01",
                "year_end_date": f"{current_year}-12-31"
            })
            fiscal_year.insert()
            print(f"✓ Created fiscal year: {fiscal_year.year}")
        else:
            print(f"Fiscal year already exists ({fiscal_years_count} years)")
        
        # Set default fiscal year in company if not set
        if not company_doc.default_fiscal_year:
            fiscal_year = frappe.db.get_value("Fiscal Year", {}, "name")
            if fiscal_year:
                company_doc.default_fiscal_year = fiscal_year
                company_doc.save()
                print(f"✓ Set default fiscal year: {fiscal_year}")
        
        frappe.db.commit()
        print("🎉 GTAL company initialization completed!")
        
        # Summary
        accounts = frappe.db.count("Account", {"company": company_name})
        fiscal_years = frappe.db.count("Fiscal Year")
        
        print(f"\n📊 Final Status:")
        print(f"  Company: {company_name} ({company_doc.abbr})")
        print(f"  Accounts: {accounts}")
        print(f"  Fiscal Years: {fiscal_years}")
        print(f"  Currency: {company_doc.default_currency}")
        print(f"  Country: {company_doc.country}")
        
    except Exception as e:
        frappe.db.rollback()
        print(f"❌ Error: {str(e)}")
        raise
    finally:
        frappe.destroy()

if __name__ == "__main__":
    initialize_company()