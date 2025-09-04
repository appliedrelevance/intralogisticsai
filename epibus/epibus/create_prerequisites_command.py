import click
import frappe
from frappe.commands import pass_context, get_site

@click.command('create-prerequisites')
@pass_context
def create_prerequisites(context):
	"""Create minimal prerequisites for EpiBus item fixtures"""
	site = get_site(context)
	frappe.init(site=site)
	frappe.connect()
	
	try:
		print("Creating minimal prerequisites...")
		
		# Create All Item Groups (root)
		if not frappe.db.exists("Item Group", "All Item Groups"):
			all_groups = frappe.get_doc({
				"doctype": "Item Group",
				"item_group_name": "All Item Groups",
				"is_group": 1
			})
			all_groups.insert(ignore_permissions=True)
			print("✅ Created 'All Item Groups'")
		
		# Create Products group
		if not frappe.db.exists("Item Group", "Products"):
			products = frappe.get_doc({
				"doctype": "Item Group", 
				"item_group_name": "Products",
				"parent_item_group": "All Item Groups",
				"is_group": 1
			})
			products.insert(ignore_permissions=True)
			print("✅ Created 'Products' item group")
		
		# Create essential UOMs
		uoms = ["Nos", "Kg", "Meter", "Litre"]
		for uom_name in uoms:
			if not frappe.db.exists("UOM", uom_name):
				uom = frappe.get_doc({
					"doctype": "UOM",
					"uom_name": uom_name,
					"enabled": 1
				})
				uom.insert(ignore_permissions=True)
				print(f"✅ Created UOM: {uom_name}")
		
		# Create company
		company_name = "Global Trade and Logistics"
		if not frappe.db.exists("Company", company_name):
			company = frappe.get_doc({
				"doctype": "Company",
				"company_name": company_name,
				"abbr": "GTAL",
				"country": "United States",
				"default_currency": "USD"
			})
			company.insert(ignore_permissions=True)
			print(f"✅ Created company: {company_name}")
		
		frappe.db.commit()
		click.echo("✅ All prerequisites created successfully!")
		
	except Exception as e:
		frappe.db.rollback()
		click.echo(f"❌ Error: {str(e)}")
		raise
	finally:
		frappe.destroy()

commands = [create_prerequisites]