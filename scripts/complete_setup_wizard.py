#!/usr/bin/env python3

import os
import sys

# Just use bench command - much simpler
def main():
    site_name = sys.argv[1] if len(sys.argv) > 1 else 'intralogistics.lab'
    
    print(f"Using bench command to complete setup for site: {site_name}")
    
    # Use individual bench commands - avoid shell syntax issues
    commands = [
        f"bench --site {site_name} execute \"frappe.db.set_single_value('System Settings', 'setup_complete', 1); frappe.db.commit()\"",
        f"bench --site {site_name} execute \"frappe.db.set_single_value('System Settings', 'time_zone', 'America/New_York'); frappe.db.commit()\"", 
        f"bench --site {site_name} execute \"frappe.db.set_single_value('Global Defaults', 'default_currency', 'USD'); frappe.db.commit()\"",
        f"bench --site {site_name} execute \"from erpnext.setup.setup_wizard.operations.install_fixtures import install_company; install_company({{'company_name': 'Roots Intralogistics', 'company_abbr': 'RL', 'country': 'United States', 'currency': 'USD'}}); frappe.db.commit()\""
    ]
    
    try:
        success = True
        for i, cmd in enumerate(commands, 1):
            print(f"Running command {i}/{len(commands)}: {cmd}")
            result = os.system(cmd)
            if result != 0:
                print(f"Command {i} failed with exit code: {result}")
                success = False
            else:
                print(f"Command {i} completed successfully")
                
        if success:
            print("All setup commands completed successfully")
            return 0
        else:
            print("Some setup commands failed")
            return 1
    except Exception as e:
        print(f"Setup failed with error: {str(e)}")
        return 1

if __name__ == '__main__':
    sys.exit(main())