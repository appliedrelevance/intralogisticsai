#!/usr/bin/env python3
import frappe
frappe.init(site='intralogistics.lab')
frappe.connect()

from frappe import _dict
from erpnext.setup.setup_wizard.operations.install_fixtures import install_company

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

try:
    frappe.db.begin()
    install_company(args)
    frappe.db.commit()
    print(f"✅ Successfully created company with {frappe.db.count('Account', {'company': 'Global Trade and Logistics'})} accounts")
    print(f"✅ Created {frappe.db.count('Fiscal Year')} fiscal years")
except Exception as e:
    frappe.db.rollback()
    print(f"❌ Error: {str(e)}")
    raise
finally:
    frappe.destroy()