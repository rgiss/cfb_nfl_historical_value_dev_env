#!/bin/bash

echo "🔄 Finding and fixing circular dependencies with static references..."

# Strategy: Make staging models that reference base models use static references
# This breaks the cycles where base models reference staging models

echo "Making staging → base references static..."

# Staging models that reference base models should use static references
find models/staging/ -name "*.sql" -exec grep -l "{{ ref(\"cfb_game_logs\")" {} \; | while read file; do
    echo "  Fixing cfb_game_logs reference in $file"
    sed -i '' 's/{{ ref("cfb_game_logs") }}/base.cfb_game_logs/g' "$file"
done

find models/staging/ -name "*.sql" -exec grep -l "{{ ref(\"nfl_game_logs\")" {} \; | while read file; do
    echo "  Fixing nfl_game_logs reference in $file"
    sed -i '' 's/{{ ref("nfl_game_logs") }}/base.nfl_game_logs/g' "$file"
done

# Also fix mart → staging circular references
find models/staging/ -name "*.sql" -exec grep -l "{{ ref(\".*_historical_value_estimate\")" {} \; | while read file; do
    echo "  Fixing historical value estimate references in $file"
    sed -i '' 's/{{ ref("cfb_historical_value_estimate") }}/marts.cfb_historical_value_estimate/g' "$file"
    sed -i '' 's/{{ ref("nfl_historical_value_estimate") }}/marts.nfl_historical_value_estimate/g' "$file"
    sed -i '' 's/{{ ref("cfb_nfl_historical_value_estimate") }}/marts.cfb_nfl_historical_value_estimate/g' "$file"
done

echo "✅ Static reference fixes complete!"

# Test dbt parse
echo "🧪 Testing dbt parse..."
if dbt parse; then
    echo "✅ All circular dependencies resolved!"
else
    echo "❌ Still have circular dependencies:"
    dbt parse 2>&1 | grep -A 1 -B 1 "Found a cycle"
fi
