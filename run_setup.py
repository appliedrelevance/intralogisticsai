import frappe

def run_setup():
    try:
        print("Running setup wizard completion...")
        from epibus.epibus.install import complete_setup_wizard
        complete_setup_wizard()
        
        # Check results
        try:
            setup_complete = frappe.db.get_single_value("System Settings", "setup_complete")
            print(f"Setup complete flag: {setup_complete}")
        except Exception as e:
            print(f"Could not check setup status: {e}")
            
        print("Setup wizard completed successfully!")
        
    except Exception as e:
        print(f"Setup failed: {e}")
        import traceback
        traceback.print_exc()
        raise

run_setup()