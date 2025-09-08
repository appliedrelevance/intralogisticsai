#!/usr/bin/env python3
"""
Create merged backup: Clean base + Business data from original (with company changes)
"""

import re
import os

# File paths
ORIGINAL_BACKUP = "backups/backups/20250904_221006-intralogistics_lab-database.sql/20250904_221006-intralogistics_lab-database.sql"
CLEAN_BASE = "clean_backups/clean_base.sql"
OUTPUT_FILE = "clean_backups/merged_complete_backup.sql"

def extract_business_data_tables():
    """Extract INSERT statements for business data from original backup"""
    print("📥 Extracting business data from original backup...")
    
    # Tables we want to extract business data from
    business_tables = [
        'tabCompany',
        'tabAccount', 
        'tabWarehouse',
        'tabItem Group',
        'tabItem Attribute',
        'tabItem Attribute Value',
        'tabUOM',
        'tabItem'
    ]
    
    extracted_data = {}
    current_table = None
    
    with open(ORIGINAL_BACKUP, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            
            # Look for INSERT statements for our business tables
            for table in business_tables:
                if f"INSERT INTO `{table}` VALUES" in line:
                    current_table = table
                    if current_table not in extracted_data:
                        extracted_data[current_table] = []
                    print(f"  Found data for {table}")
                    break
            
            # Collect the data lines for current table
            if current_table and line.startswith("("):
                extracted_data[current_table].append(line)
            
            # End of table data
            if line == "/*!40000 ALTER TABLE" or line.startswith("UNLOCK TABLES;"):
                current_table = None
    
    return extracted_data

def transform_company_data():
    """Create GTAL company data to replace Roots"""
    print("🔄 Creating GTAL company data...")
    
    # GTAL company INSERT statement
    gtal_company = """INSERT INTO `tabCompany` VALUES
('Global Trade and Logistics','2025-09-06 18:00:00.000000','2025-09-06 18:00:00.000000','Administrator','Administrator',0,0,'Global Trade and Logistics','GTAL','USD','United States',0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,'Oldest Of Invoice Or Advance',NULL,NULL,0,NULL,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0.000000000,0.000000000,NULL,NULL,0.000000000,NULL,1,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);"""
    
    return gtal_company

def update_company_references(data):
    """Replace Roots/RL references with GTAL in business data"""
    print("🔄 Updating company references from RL to GTAL...")
    
    updated_data = {}
    
    for table, lines in data.items():
        print(f"  Processing {table}...")
        updated_lines = []
        
        for line in lines:
            # Replace company abbreviation
            line = line.replace("'RL'", "'GTAL'")
            line = line.replace("'Roots Intralogistics'", "'Global Trade and Logistics'")
            
            # Replace account names with company suffix
            line = line.replace(" - RL", " - GTAL")
            
            # Handle other potential company references
            line = line.replace("Roots", "GTAL")
            
            updated_lines.append(line)
        
        updated_data[table] = updated_lines
        print(f"    ✓ Updated {len(updated_lines)} records")
    
    return updated_data

def create_merged_backup(base_file, business_data, gtal_company):
    """Create final merged backup file"""
    print("📦 Creating merged backup file...")
    
    with open(base_file, 'r', encoding='utf-8') as base_f:
        base_content = base_f.read()
    
    # Find insertion points in base content
    # We'll insert our business data before the final SQL statements
    
    # Insert company data
    company_insert_point = base_content.find("/*!40000 ALTER TABLE `tabCompany` ENABLE KEYS */;")
    if company_insert_point > 0:
        # Find the preceding INSERT INTO tabCompany VALUES
        company_start = base_content.rfind("INSERT INTO `tabCompany` VALUES", 0, company_insert_point)
        if company_start > 0:
            # Replace empty company data with GTAL company
            company_end = base_content.find(";\n", company_start) + 2
            base_content = base_content[:company_start] + gtal_company + ";\n" + base_content[company_end:]
            print("  ✓ Inserted GTAL company data")
        else:
            # No existing company data, insert before ALTER TABLE
            base_content = base_content[:company_insert_point] + gtal_company + ";\n" + base_content[company_insert_point:]
            print("  ✓ Added GTAL company data")
    
    # Insert business data for each table
    for table, lines in business_data.items():
        if table == 'tabCompany':
            continue  # Already handled above
            
        # Find the table's ALTER TABLE statement
        alter_table_pattern = f"/*!40000 ALTER TABLE `{table}` ENABLE KEYS */;"
        alter_pos = base_content.find(alter_table_pattern)
        
        if alter_pos > 0:
            # Insert data before ALTER TABLE
            # Remove trailing commas and semicolons from lines first
            clean_lines = []
            for line in lines:
                clean_line = line.rstrip(',;')
                clean_lines.append(clean_line)
            
            insert_data = f"INSERT INTO `{table}` VALUES\n" + ",\n".join(clean_lines) + ";\n"
            base_content = base_content[:alter_pos] + insert_data + base_content[alter_pos:]
            print(f"  ✓ Inserted {len(clean_lines)} records for {table}")
        else:
            print(f"  ⚠ Could not find insertion point for {table}")
    
    # Write merged backup
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as output_f:
        output_f.write(base_content)
    
    print(f"✅ Merged backup created: {OUTPUT_FILE}")
    
    # Get file size
    size_mb = os.path.getsize(OUTPUT_FILE) / (1024 * 1024)
    print(f"📊 File size: {size_mb:.1f} MB")

def main():
    print("🚀 Creating merged backup with GTAL company + business data...")
    print("="*60)
    
    # Step 1: Extract business data from original
    business_data = extract_business_data_tables()
    print(f"📊 Extracted data from {len(business_data)} tables")
    
    # Step 2: Create GTAL company
    gtal_company = transform_company_data()
    
    # Step 3: Update company references  
    updated_data = update_company_references(business_data)
    
    # Step 4: Create merged backup
    create_merged_backup(CLEAN_BASE, updated_data, gtal_company)
    
    print("\n🎉 Merged backup creation completed!")
    print("📋 Next steps:")
    print("  1. Compress: gzip merged_complete_backup.sql")
    print("  2. Test restore")
    print("  3. Verify GTAL company and business data")

if __name__ == "__main__":
    main()