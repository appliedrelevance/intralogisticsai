#!/usr/bin/env python3
"""
Check GTAL company status and setup
Run with: bench --site intralogistics.lab execute scripts/check_company_status.py
"""

import frappe

def main():
    """Check company setup status"""
    print("🔍 Checking GTAL company status...")
    
    # Check if GTAL company exists
    company = frappe.db.get_value('Company', {'name': 'Global Trade and Logistics'})
    print(f"GTAL Company exists: {company}")
    
    if company:
        # Check accounts for GTAL
        accounts = frappe.db.get_all('Account', 
            {'company': 'Global Trade and Logistics'}, 
            ['name', 'account_type', 'is_group']
        )
        print(f"Accounts count for GTAL: {len(accounts)}")
        if accounts:
            print("Sample accounts:")
            for acc in accounts[:5]:
                print(f"  - {acc.name} ({acc.account_type})")
        
        # Check fiscal years
        fiscal_years = frappe.db.get_all('Fiscal Year', 
            {'company': 'Global Trade and Logistics'}, 
            ['name', 'year_start_date', 'year_end_date']
        )
        print(f"Fiscal years for GTAL: {len(fiscal_years)}")
        for fy in fiscal_years:
            print(f"  - {fy.name}: {fy.year_start_date} to {fy.year_end_date}")
        
        # Check company defaults
        company_doc = frappe.get_doc('Company', 'Global Trade and Logistics')
        print(f"Default currency: {company_doc.default_currency}")
        print(f"Country: {company_doc.country}")
        print(f"Abbr: {company_doc.abbr}")
        
        # Check for chart of accounts setup
        root_accounts = frappe.db.get_all('Account', {
            'company': 'Global Trade and Logistics',
            'is_group': 1,
            'parent_account': ['is', 'not set']
        }, ['name'])
        print(f"Root accounts: {len(root_accounts)}")
        for root in root_accounts:
            print(f"  - {root.name}")
        
    else:
        print("❌ GTAL company not found!")
    
    # Check all companies
    all_companies = frappe.db.get_all('Company', ['name', 'abbr'])
    print(f"\nAll companies in system: {len(all_companies)}")
    for comp in all_companies:
        print(f"  - {comp.name} ({comp.abbr})")

if __name__ == "__main__":
    main()