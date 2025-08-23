#!/usr/bin/env python3
"""
Complete ERPNext setup wizard automatically
"""
import frappe
import sys
from frappe.desk.page.setup_wizard.setup_wizard import setup_complete

def complete_setup_wizard(site_name):
    """Complete the setup wizard with predefined values"""
    frappe.init(site=site_name)
    frappe.connect()
    
    # Check if setup is already complete
    if frappe.db.get_single_value("System Settings", "setup_complete"):
        print(f"Setup already completed for {site_name}")
        return True
        
    try:
        # Setup wizard data
        args = {
            "language": "en",
            "country": "United States", 
            "timezone": "America/New_York",
            "currency": "USD",
            "first_name": "Administrator",
            "last_name": "User",
            "email": f"admin@{site_name}",
            "company_name": "Roots Intralogistics",
            "company_abbr": "RL", 
            "domains": ["Manufacturing"],
            "bank_account": "Cash - RL"
        }
        
        # Complete setup
        setup_complete(args)
        print(f"Setup wizard completed successfully for {site_name}")
        return True
        
    except Exception as e:
        print(f"Setup wizard failed for {site_name}: {str(e)}")
        return False
    finally:
        frappe.destroy()

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python complete_setup.py <site_name>")
        sys.exit(1)
        
    site_name = sys.argv[1]
    success = complete_setup_wizard(site_name)
    sys.exit(0 if success else 1)