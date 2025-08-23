#!/usr/bin/env python3

import os
import sys

# Change to frappe-bench directory
os.chdir('/home/frappe/frappe-bench')

# Add frappe-bench to Python path
sys.path.insert(0, '/home/frappe/frappe-bench')
sys.path.insert(0, '/home/frappe/frappe-bench/apps')

import frappe
from frappe.desk.page.setup_wizard.setup_wizard import setup_complete

def main():
    site_name = sys.argv[1] if len(sys.argv) > 1 else 'intralogistics.lab'
    
    print(f"Current working directory: {os.getcwd()}")
    print(f"Sites directory contents: {os.listdir('sites')}")
    print(f"Looking for site: {site_name}")
    
    if os.path.exists(f'sites/{site_name}'):
        print(f"Site directory exists: sites/{site_name}")
        site_contents = os.listdir(f'sites/{site_name}')
        print(f"Site contents: {site_contents}")
    else:
        print(f"ERROR: Site directory does not exist: sites/{site_name}")
        return 1
    
    print(f"Initializing Frappe for site: {site_name}")
    frappe.init(site=site_name)
    frappe.connect()
    
    print("Completing setup wizard with all required parameters...")
    
    args = {
        'language': 'en',
        'country': 'United States', 
        'timezone': 'America/New_York',
        'currency': 'USD',
        'full_name': 'Administrator User',
        'email': 'admin@rootseducation.co',
        'password': 'admin',
        'company_name': 'Roots Intralogistics',
        'company_abbr': 'RL',
        'chart_of_accounts': 'Standard',
        'fy_start_date': '2025-01-01',
        'fy_end_date': '2025-12-31',
        'setup_demo': 0,
        'enable_telemetry': 0
    }
    
    try:
        setup_status = setup_complete(args=args)
        frappe.db.commit()
        print(f"Setup completed successfully: {setup_status}")
        return 0
    except Exception as e:
        print(f"Setup failed with error: {str(e)}")
        import traceback
        traceback.print_exc()
        return 1

if __name__ == '__main__':
    sys.exit(main())