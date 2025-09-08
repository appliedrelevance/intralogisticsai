#!/usr/bin/env python3
"""
Create company with proper ERPNext setup via setup wizard
"""

import frappe
from frappe import _
from erpnext.setup.setup_wizard.operations.install_fixtures import install_company, install_defaults
from erpnext.accounts.doctype.account.chart_of_accounts.chart_of_accounts import create_charts

def setup_company_properly():
    """Use ERPNext setup wizard functions to create company properly"""
    
    company_data = {
        "company_name": "Global Trade and Logistics",
        "company_abbr": "GTAL",
        "country": "United States",
        "currency": "USD",
        "domain": "Manufacturing"
    }
    
    try:
        frappe.db.begin()
        
        # Check if company already exists
        if frappe.db.exists("Company", company_data["company_name"]):
            print(f"✓ Company '{company_data['company_name']}' already exists")
            
            # Check if it has accounts
            accounts_count = frappe.db.count("Account", {"company": company_data["company_name"]})
            if accounts_count == 0:
                print("📊 Installing chart of accounts...")
                
                # Use ERPNext's proper company installation
                install_company(
                    company_data["company_name"],
                    company_data["company_abbr"], 
                    company_data["domain"],
                    company_data["country"]
                )
                
                accounts_count = frappe.db.count("Account", {"company": company_data["company_name"]})
                print(f"✓ Created {accounts_count} accounts")
            else:
                print(f"Chart of accounts already exists ({accounts_count} accounts)")
        else:
            print(f"Creating company: {company_data['company_name']}")
            
            # Create company using setup wizard method
            install_company(
                company_data["company_name"],
                company_data["company_abbr"],
                company_data["domain"], 
                company_data["country"]
            )
            
        # Install other defaults
        print("📋 Installing ERPNext defaults...")
        install_defaults({
            "country": company_data["country"],
            "currency": company_data["currency"],
            "timezone": "America/New_York"
        })
        
        frappe.db.commit()
        print("🎉 Company setup completed successfully!")
        
        # Summary
        company_name = company_data["company_name"]
        accounts = frappe.db.count("Account", {"company": company_name})
        fiscal_years = frappe.db.count("Fiscal Year")
        
        print(f"\n📊 Final Status:")
        print(f"  Company: {company_name} ({company_data['company_abbr']})")
        print(f"  Accounts: {accounts}")
        print(f"  Fiscal Years: {fiscal_years}")
        print(f"  Currency: {company_data['currency']}")
        print(f"  Country: {company_data['country']}")
        
    except Exception as e:
        frappe.db.rollback()
        print(f"❌ Error: {str(e)}")
        import traceback
        traceback.print_exc()
        raise

if __name__ == "__main__":
    setup_company_properly()