#!/usr/bin/env python3

import frappe

def fix_modbus_signals():
    """Fix MODBUS signal types from Digital Input Coil to Digital Output Coil"""
    frappe.init('intralogistics.lab')
    frappe.connect()
    
    # Update all Digital Input Coil to Digital Output Coil
    updated_count = frappe.db.sql("""
        UPDATE tabModbus_Connection_Signal 
        SET signal_type = 'Digital Output Coil' 
        WHERE signal_type = 'Digital Input Coil'
    """)
    
    frappe.db.commit()
    
    # Check the results
    counts = frappe.db.sql("""
        SELECT signal_type, COUNT(*) as count 
        FROM tabModbus_Connection_Signal 
        GROUP BY signal_type
    """, as_dict=True)
    
    print("MODBUS Signal Type Counts:")
    for count in counts:
        print(f"  {count.signal_type}: {count.count}")
    
    print(f"\nSuccessfully updated MODBUS signal types!")

if __name__ == "__main__":
    fix_modbus_signals()