#!/bin/bash

# Import business data using bench data-import command
echo "🚀 Starting business data import..."

# Define import order and files
declare -a imports=(
    "Company:import_data/companies.csv"
    "Item Group:import_data/item_groups.csv" 
    "Item Attribute:import_data/item_attributes.csv"
    "Warehouse:import_data/warehouses.csv"
    "Item:import_data/items.csv"
)

# Import each file
for import_def in "${imports[@]}"; do
    IFS=':' read -r doctype file <<< "$import_def"
    
    echo ""
    echo "=== Importing $doctype from $file ==="
    
    if [ ! -f "$file" ]; then
        echo "⚠️  Warning: $file not found, skipping..."
        continue
    fi
    
    echo "📁 File found: $file"
    echo "📊 Importing $doctype records..."
    
    if bench --site intralogistics.lab data-import --file "$file" --doctype "$doctype" --type insert --mute-emails; then
        echo "✅ Successfully imported $doctype"
    else
        echo "❌ Failed to import $doctype"
        # Continue with other imports even if one fails
    fi
done

echo ""
echo "🎉 Business data import process completed!"
echo ""
echo "Next steps:"
echo "1. Review imported data in the web interface"
echo "2. Check for any import errors"
echo "3. Run: bench --site intralogistics.lab backup"
echo "4. Store the backup for future deployments"