#!/usr/bin/env python3

import os
import sys

# Just use bench command - much simpler
def main():
    site_name = sys.argv[1] if len(sys.argv) > 1 else 'intralogistics.lab'
    
    print(f"Using bench command to complete setup for site: {site_name}")
    
    # Use bench execute to run setup - this avoids all the frappe.init() issues
    bench_cmd = f"""
bench --site {site_name} execute frappe.local.dev_server = 1; \\
from erpnext.setup.setup_wizard.operations.install_fixtures import install_company; \\
install_company({{
    'company_name': 'Roots Intralogistics',
    'company_abbr': 'RL', 
    'country': 'United States',
    'currency': 'USD'
}}); \\
frappe.db.set_single_value('System Settings', 'setup_complete', 1); \\
frappe.db.set_single_value('System Settings', 'time_zone', 'America/New_York'); \\
frappe.db.set_single_value('Global Defaults', 'default_currency', 'USD'); \\
frappe.db.commit()
"""
    
    try:
        result = os.system(bench_cmd)
        if result == 0:
            print("Setup completed successfully using bench command")
            return 0
        else:
            print(f"Bench command failed with exit code: {result}")
            return 1
    except Exception as e:
        print(f"Setup failed with error: {str(e)}")
        return 1

if __name__ == '__main__':
    sys.exit(main())