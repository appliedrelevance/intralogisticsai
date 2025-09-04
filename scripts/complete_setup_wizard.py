#!/usr/bin/env python3

import os
import sys

def main():
    site_name = sys.argv[1] if len(sys.argv) > 1 else 'intralogistics.lab'
    
    print(f"🚀 Complete setup wizard bypass for site: {site_name}")
    
    # Test basic bench command
    test_cmd = f"bench --site {site_name} list-apps"
    print(f"Testing bench command: {test_cmd}")
    result = os.system(test_cmd)
    
    if result != 0:
        print(f"❌ Basic bench command failed with exit code: {result}")
        return 1
    else:
        print("✅ Basic bench command works")
    
    print("🔧 Setting setup completion flags in database...")
    
    # The critical SQL commands to bypass setup wizard
    sql_commands = [
        # Set System Settings setup_complete flag
        f"bench --site {site_name} mariadb -e \"UPDATE tabSingles SET value = '1' WHERE doctype = 'System Settings' AND field = 'setup_complete';\"",
        
        # Set home page away from setup wizard
        f"bench --site {site_name} mariadb -e \"SET SQL_SAFE_UPDATES = 0; UPDATE tabSingles SET value = '/app' WHERE field = 'home_page'; SET SQL_SAFE_UPDATES = 1;\"",
        f"bench --site {site_name} mariadb -e \"SET SQL_SAFE_UPDATES = 0; UPDATE tabSingles SET value = '/app' WHERE field = 'desktop:home_page'; SET SQL_SAFE_UPDATES = 1;\"",
        
        # Mark frappe app as setup complete (CRITICAL!) - Use app_name not name
        f"bench --site {site_name} mariadb -e \"SET SQL_SAFE_UPDATES = 0; UPDATE \\`tabInstalled Application\\` SET is_setup_complete = 1 WHERE app_name = 'frappe'; SET SQL_SAFE_UPDATES = 1;\"",
        
        # Mark erpnext app as setup complete (CRITICAL!) - Use app_name not name  
        f"bench --site {site_name} mariadb -e \"SET SQL_SAFE_UPDATES = 0; UPDATE \\`tabInstalled Application\\` SET is_setup_complete = 1 WHERE app_name = 'erpnext'; SET SQL_SAFE_UPDATES = 1;\"",
        
        # Set Global Defaults
        f"bench --site {site_name} mariadb -e \"UPDATE tabSingles SET value = 'Global Trade and Logistics' WHERE doctype = 'Global Defaults' AND field = 'default_company';\"",
        f"bench --site {site_name} mariadb -e \"UPDATE tabSingles SET value = 'United States' WHERE doctype = 'Global Defaults' AND field = 'country';\"",
        f"bench --site {site_name} mariadb -e \"UPDATE tabSingles SET value = 'USD' WHERE doctype = 'Global Defaults' AND field = 'default_currency';\"",
        
        # Create basic company if not exists
        f"bench --site {site_name} mariadb -e \"INSERT IGNORE INTO tabCompany (name, company_name, abbr, country, default_currency, creation, modified, owner, modified_by, docstatus) VALUES ('Global Trade and Logistics', 'Global Trade and Logistics', 'GTAL', 'United States', 'USD', NOW(), NOW(), 'Administrator', 'Administrator', 0);\"",
    ]
    
    try:
        success = True
        for i, cmd in enumerate(sql_commands, 1):
            print(f"⚙️  Running setup command {i}/{len(sql_commands)}")
            result = os.system(cmd)
            if result != 0:
                print(f"❌ Setup command {i} failed with exit code: {result}")
                success = False
            else:
                print(f"✅ Setup command {i} completed successfully")
                
        if success:
            print("🎉 All setup commands completed successfully!")
            print("🔍 Setup wizard should now be bypassed")
            return 0
        else:
            print("❌ Some setup commands failed")
            return 1
    except Exception as e:
        print(f"❌ Setup failed with error: {str(e)}")
        return 1

if __name__ == '__main__':
    sys.exit(main())