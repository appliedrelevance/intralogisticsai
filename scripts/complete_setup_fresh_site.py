#!/usr/bin/env python3
"""
Complete company setup on fresh.lab site
"""

import frappe
from frappe import _dict
from erpnext.setup.setup_wizard.operations.install_fixtures import install_company

def setup_fresh_site():
    """Complete company setup on fresh site"""
    
    # Setup wizard parameters
    args = _dict({
        'company_name': 'Global Trade and Logistics',
        'company_abbr': 'GTAL',
        'country': 'United States',
        'currency': 'USD', 
        'domain': 'Manufacturing',
        'chart_of_accounts': 'Standard',
        'fy_start_date': '2025-01-01',
        'fy_end_date': '2025-12-31'
    })
    
    print("🚀 Setting up GTAL company on fresh.lab...")
    
    # Install company with all dependencies
    install_company(args)
    
    # Check results
    accounts = frappe.db.count('Account', {'company': 'Global Trade and Logistics'})
    fiscal_years = frappe.db.count('Fiscal Year')
    
    print(f"✅ Success!")
    print(f"  Company: Global Trade and Logistics (GTAL)")
    print(f"  Accounts: {accounts}")
    print(f"  Fiscal Years: {fiscal_years}")

if __name__ == "__main__":
    setup_fresh_site()