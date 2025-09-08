#!/usr/bin/env python3
"""
Simulate the ERPNext setup wizard to create company properly
Run with: bench --site intralogistics.lab execute scripts/setup_wizard_simulation.py
"""

import frappe

def simulate_setup_wizard():
    """Simulate the setup wizard process to create company with all dependencies"""
    
    # Setup wizard data
    setup_data = {
        'language': 'en',
        'country': 'United States',
        'timezone': 'America/New_York',
        'currency': 'USD',
        'company_name': 'Global Trade and Logistics',
        'company_abbr': 'GTAL',
        'domain': 'Manufacturing',
        'company_tagline': 'Industrial Automation Excellence',
        'bank_account': 'Primary Checking Account',
        'chart_of_accounts': 'Standard',
        'fy_start_date': '2025-01-01',
        'fy_end_date': '2025-12-31'
    }
    
    print("🚀 Running setup wizard simulation...")
    
    try:
        frappe.db.begin()
        
        # Step 1: Create company
        print("📊 Creating company...")
        company = frappe.get_doc({
            'doctype': 'Company',
            'company_name': setup_data['company_name'],
            'abbr': setup_data['company_abbr'],
            'default_currency': setup_data['currency'],
            'country': setup_data['country'],
            'domain': setup_data['domain'],
            'company_description': setup_data['company_tagline']
        })
        company.insert()
        print(f"✓ Created company: {company.name}")
        
        # Step 2: Install company fixtures (chart of accounts, etc.)
        print("📋 Installing company fixtures...")
        from erpnext.setup.setup_wizard.operations.install_fixtures import install_company
        install_company(
            setup_data['company_name'],
            setup_data['company_abbr'],
            setup_data['domain'],
            setup_data['country']
        )
        
        accounts_count = frappe.db.count('Account', {'company': setup_data['company_name']})
        print(f"✓ Created chart of accounts with {accounts_count} accounts")
        
        # Step 3: Create fiscal year
        print("📅 Creating fiscal year...")
        fiscal_year = frappe.get_doc({
            'doctype': 'Fiscal Year',
            'year': '2025',
            'year_start_date': setup_data['fy_start_date'],
            'year_end_date': setup_data['fy_end_date'],
            'companies': [{'company': setup_data['company_name']}]
        })
        fiscal_year.insert()
        print(f"✓ Created fiscal year: {fiscal_year.name}")
        
        # Step 4: Set company defaults
        print("⚙️ Setting company defaults...")
        company_doc = frappe.get_doc('Company', setup_data['company_name'])
        company_doc.default_fiscal_year = fiscal_year.name
        company_doc.save()
        
        # Step 5: Install other defaults
        print("🔧 Installing ERPNext defaults...")
        from erpnext.setup.setup_wizard.operations.install_fixtures import install_defaults
        install_defaults({
            'country': setup_data['country'],
            'currency': setup_data['currency'],
            'timezone': setup_data['timezone']
        })
        
        frappe.db.commit()
        print("🎉 Setup wizard simulation completed!")
        
        # Final status
        company_name = setup_data['company_name']
        accounts = frappe.db.count('Account', {'company': company_name})
        fiscal_years = frappe.db.count('Fiscal Year')
        
        print(f"\n📊 Final Status:")
        print(f"  Company: {company_name} ({setup_data['company_abbr']})")
        print(f"  Accounts: {accounts}")
        print(f"  Fiscal Years: {fiscal_years}")
        print(f"  Currency: {setup_data['currency']}")
        print(f"  Country: {setup_data['country']}")
        
    except Exception as e:
        frappe.db.rollback()
        print(f"❌ Error: {str(e)}")
        import traceback
        traceback.print_exc()
        raise

if __name__ == "__main__":
    simulate_setup_wizard()