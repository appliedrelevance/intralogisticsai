import frappe

print("=== Deleting Roots Company ===")

try:
    # Start transaction
    frappe.db.begin()
    
    # Check if company exists
    if frappe.db.exists("Company", "Roots"):
        print("Found Roots company, proceeding with deletion...")
        
        # Delete the company document with force
        company_doc = frappe.get_doc("Company", "Roots")
        company_doc.delete(force=True)
        
        print("✓ Roots company deleted successfully")
    else:
        print("Roots company not found")
    
    # Commit the transaction
    frappe.db.commit()
    
    # Verify deletion
    remaining_companies = frappe.get_all("Company", fields=["name", "company_name"])
    print("\nRemaining companies:")
    for company in remaining_companies:
        print(f"  - {company.company_name} ({company.name})")
    
    print("\n✅ Company deletion completed successfully!")
    
except Exception as e:
    frappe.db.rollback()
    print(f"❌ Error deleting company: {str(e)}")
    raise