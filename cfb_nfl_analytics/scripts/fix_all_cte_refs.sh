#!/bin/bash

echo "🔍 Finding and fixing ALL remaining CTE reference issues..."

# Find all files with CTE definitions and their references
for file in models/staging/*.sql models/base/*.sql models/marts/*.sql; do
    if [[ -f "$file" ]]; then
        echo "Checking $file..."
        
        # Extract CTE names from 'with [name] as (' patterns
        cte_names=$(grep -E "^[[:space:]]*,[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]+as[[:space:]]*\(" "$file" | sed -E 's/^[[:space:]]*,[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]+as[[:space:]]*\(.*/\1/' | tr '\n' ' ')
        
        # Also check for 'with [name] as (' pattern
        first_cte=$(grep -E "^[[:space:]]*with[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]+as[[:space:]]*\(" "$file" | sed -E 's/^[[:space:]]*with[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]+as[[:space:]]*\(.*/\1/' | tr '\n' ' ')
        
        all_ctes="$first_cte $cte_names"
        
        if [[ -n "$all_ctes" ]]; then
            echo "  Found CTEs: $all_ctes"
            
            # For each CTE, replace {{ ref("cte_name") }} with cte_name
            for cte in $all_ctes; do
                if [[ -n "$cte" ]]; then
                    echo "    Fixing CTE reference: $cte"
                    sed -i '' "s/{{ ref(\"$cte\") }}/$cte/g" "$file"
                fi
            done
        fi
    fi
done

echo "✅ All CTE reference fixes complete!"

# Test dbt parse
echo "🧪 Testing dbt parse..."
if dbt parse; then
    echo "✅ dbt parse successful!"
else
    echo "❌ dbt parse failed - showing first error:"
    dbt parse 2>&1 | head -10
fi
