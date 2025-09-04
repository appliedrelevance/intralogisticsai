#!/usr/bin/env python3
"""
Extract item data from SQL backup and convert to Frappe fixtures format.
"""

import re
import json
from datetime import datetime


def parse_sql_insert(insert_line, table_name):
	"""Parse SQL INSERT statement and convert to list of records."""
	# Extract VALUES part
	values_match = re.search(r"VALUES\s+(.+);$", insert_line, re.DOTALL)
	if not values_match:
		return []
	
	values_str = values_match.group(1)
	
	# Split by record boundaries - look for ),( pattern
	records = []
	current_record = ""
	paren_count = 0
	in_quotes = False
	quote_char = None
	i = 0
	
	while i < len(values_str):
		char = values_str[i]
		
		if not in_quotes and char in ["'", '"']:
			in_quotes = True
			quote_char = char
		elif in_quotes and char == quote_char:
			# Check for escaped quotes
			if i + 1 < len(values_str) and values_str[i + 1] == quote_char:
				i += 1  # Skip escaped quote
			else:
				in_quotes = False
		elif not in_quotes:
			if char == '(':
				paren_count += 1
			elif char == ')':
				paren_count -= 1
				if paren_count == 0:
					# End of record
					current_record += char
					records.append(current_record.strip())
					current_record = ""
					# Skip comma and whitespace
					i += 1
					while i < len(values_str) and values_str[i] in [',', ' ', '\n', '\t']:
						i += 1
					i -= 1  # Compensate for the increment at end of loop
				else:
					current_record += char
			else:
				current_record += char
		else:
			current_record += char
			
		i += 1
	
	# Add last record if exists
	if current_record.strip():
		records.append(current_record.strip())
	
	return records


def parse_record_values(record_str):
	"""Parse a single record string into list of values."""
	# Remove outer parentheses
	record_str = record_str.strip()
	if record_str.startswith('(') and record_str.endswith(')'):
		record_str = record_str[1:-1]
	
	values = []
	current_value = ""
	in_quotes = False
	quote_char = None
	i = 0
	
	while i < len(record_str):
		char = record_str[i]
		
		if not in_quotes and char in ["'", '"']:
			in_quotes = True
			quote_char = char
			current_value += char
		elif in_quotes and char == quote_char:
			# Check for escaped quotes
			if i + 1 < len(record_str) and record_str[i + 1] == quote_char:
				current_value += char + char
				i += 1
			else:
				in_quotes = False
				current_value += char
		elif not in_quotes and char == ',':
			values.append(current_value.strip())
			current_value = ""
		else:
			current_value += char
		
		i += 1
	
	# Add last value
	if current_value.strip():
		values.append(current_value.strip())
	
	return values


def convert_sql_value(value_str):
	"""Convert SQL value to Python value."""
	value_str = value_str.strip()
	
	if value_str == 'NULL':
		return None
	elif value_str.startswith("'") and value_str.endswith("'"):
		# String value - remove quotes and handle escapes
		return value_str[1:-1].replace("''", "'").replace('\\"', '"')
	elif value_str.isdigit():
		return int(value_str)
	elif re.match(r'^\d+\.\d+$', value_str):
		return float(value_str)
	else:
		# Try to parse as number or keep as string
		try:
			if '.' in value_str:
				return float(value_str)
			else:
				return int(value_str)
		except ValueError:
			return value_str


def get_tabitem_structure():
	"""Return the expected structure for tabItem based on SQL schema."""
	return [
		"name", "creation", "modified", "modified_by", "owner", "docstatus", "idx",
		"naming_series", "item_code", "item_name", "item_group", "stock_uom", "disabled",
		"allow_alternative_item", "is_stock_item", "has_variants", "opening_stock",
		"valuation_rate", "standard_rate", "is_purchase_item", "is_customer_provided_item",
		"is_expense_item", "enable_deferred_expense", "no_of_months_exp", "expense_account",
		"deferred_expense_account", "purchase_uom", "min_order_qty", "safety_stock",
		"is_sales_item", "grant_commission", "max_discount", "image", "description",
		"brand", "shelf_life_in_days", "end_of_life", "default_material_request_type",
		"valuation_method", "warranty_period", "weight_per_unit", "weight_uom",
		"allow_negative_stock", "has_batch_no", "create_new_batch", "batch_number_series",
		"has_expiry_date", "retain_sample", "sample_quantity", "has_serial_no",
		"serial_no_series", "variant_of", "variant_based_on", "enable_deferred_revenue",
		"no_of_months", "deferred_revenue_account", "enable_deferred_expense",
		"deferred_expense_account", "customer_code", "default_item_manufacturer",
		"default_manufacturer_part_no", "total_projected_qty", "country_of_origin",
		"customs_tariff_number", "sales_uom", "is_grouped", "is_sub_contracted_item",
		"default_bom", "customer_items", "supplier_items", "attributes", "variants",
		"defaults", "item_tax", "inspection_required_before_purchase",
		"inspection_required_before_delivery", "is_stock_item", "include_item_in_manufacturing",
		"is_fixed_asset", "auto_create_assets", "asset_category", "asset_naming_series"
	]


def process_items_data():
	"""Extract and process item data from SQL backup."""
	
	# Read the SQL file
	sql_file = "/mnt/c/Users/Geordie/Code/intralogisticsai/resources/initialization/20250110_130123-intralogistics_frappe_cloud-database.sql"
	
	with open(sql_file, 'r', encoding='utf-8') as f:
		content = f.read()
	
	# Find INSERT statements for relevant tables
	tables_to_extract = [
		'tabItem',
		'tabItem Attribute', 
		'tabItem Attribute Value',
		'tabItem Barcode',
		'tabItem Default'
	]
	
	all_fixtures = {}
	
	for table in tables_to_extract:
		print(f"Processing {table}...")
		
		# Find INSERT statement for this table
		pattern = rf"INSERT INTO `{re.escape(table)}` VALUES (.+?);"
		match = re.search(pattern, content, re.DOTALL)
		
		if match:
			values_str = match.group(1)
			
			# Parse the values - they are in format (val1,val2,...),(val1,val2,...),...
			records = []
			current_record = ""
			paren_depth = 0
			in_string = False
			string_char = None
			
			i = 0
			while i < len(values_str):
				char = values_str[i]
				
				if not in_string:
					if char in ["'", '"']:
						in_string = True
						string_char = char
					elif char == '(':
						paren_depth += 1
					elif char == ')':
						paren_depth -= 1
						current_record += char
						if paren_depth == 0:
							records.append(current_record.strip())
							current_record = ""
							# Skip to next record
							while i + 1 < len(values_str) and values_str[i + 1] in [',', ' ', '\n', '\t']:
								i += 1
							i += 1
							continue
				else:
					if char == string_char:
						# Check for escaped quote
						if i + 1 < len(values_str) and values_str[i + 1] == string_char:
							i += 1  # Skip the escaped quote
						else:
							in_string = False
				
				current_record += char
				i += 1
			
			# Process each record based on table type
			processed_records = []
			
			if table == 'tabItem':
				# Get item structure 
				item_fields = [
					"name", "creation", "modified", "modified_by", "owner", "docstatus", "idx",
					"naming_series", "item_code", "item_name", "item_group", "stock_uom", 
					"disabled", "allow_alternative_item", "is_stock_item", "has_variants"
					# Add more fields as needed - this is just the core ones
				]
				
				for record in records:
					# Remove outer parentheses and split by commas (handling quotes)
					if record.startswith('(') and record.endswith(')'):
						record = record[1:-1]
					
					# Simple CSV parsing for now - would need more robust parsing for production
					values = []
					current = ""
					in_quote = False
					quote_char = None
					
					for char in record:
						if not in_quote and char in ["'", '"']:
							in_quote = True
							quote_char = char
						elif in_quote and char == quote_char:
							in_quote = False
						elif not in_quote and char == ',':
							values.append(current.strip())
							current = ""
							continue
						current += char
					
					if current:
						values.append(current.strip())
					
					# Create record dict (just basic fields for now)
					if len(values) >= 12:  # Minimum number of fields we need
						item_doc = {
							"doctype": "Item",
							"name": values[0].strip("'\"") if values[0] != 'NULL' else None,
							"item_code": values[8].strip("'\"") if values[8] != 'NULL' else None,
							"item_name": values[9].strip("'\"") if values[9] != 'NULL' else None,
							"item_group": values[10].strip("'\"") if values[10] != 'NULL' else None,
							"stock_uom": values[11].strip("'\"") if values[11] != 'NULL' else None,
							"disabled": int(values[12]) if values[12] != 'NULL' else 0,
							"is_stock_item": int(values[14]) if values[14] != 'NULL' else 1,
							"has_variants": int(values[15]) if values[15] != 'NULL' else 0
						}
						
						# Add image if present (around field 26 in the SQL)
						if len(values) > 26 and values[26] != 'NULL':
							item_doc["image"] = values[26].strip("'\"")
						
						processed_records.append(item_doc)
			
			elif table == 'tabItem Attribute':
				for record in records:
					if record.startswith('(') and record.endswith(')'):
						record = record[1:-1]
					
					parts = record.split("','")  # Simple split - would need better parsing
					if len(parts) >= 8:
						attr_doc = {
							"doctype": "Item Attribute", 
							"name": parts[0].strip("'\""),
							"attribute_name": parts[7].strip("'\"")
						}
						processed_records.append(attr_doc)
			
			# Store in fixtures dict
			all_fixtures[table] = processed_records
			print(f"  Extracted {len(processed_records)} records from {table}")
	
	return all_fixtures


if __name__ == "__main__":
	fixtures = process_items_data()
	
	# Save to JSON files
	for table_name, records in fixtures.items():
		if records:  # Only save if we have data
			safe_name = table_name.replace(' ', '_').lower()
			filename = f"/mnt/c/Users/Geordie/Code/intralogisticsai/extracted_data/{safe_name}_fixture.json"
			with open(filename, 'w', encoding='utf-8') as f:
				json.dump(records, f, indent=2, default=str)
			print(f"Saved {len(records)} records to {filename}")