#!/bin/bash

# Fix CTE references in converted dbt models
# CTEs should be referenced directly, not with {{ ref() }}

echo "🔧 Fixing CTE references in dbt models..."

# Function to fix CTE references in a file
fix_cte_refs() {
    local file="$1"
    echo "Fixing: $file"
    
    # Common CTE patterns to fix
    sed -i '' 's/{{ ref("player_names_cleaning") }}/player_names_cleaning/g' "$file"
    sed -i '' 's/{{ ref("pre_clean") }}/pre_clean/g' "$file"
    sed -i '' 's/{{ ref("name_variations") }}/name_variations/g' "$file"
    sed -i '' 's/{{ ref("cfb_player_names") }}/cfb_player_names/g' "$file"
    sed -i '' 's/{{ ref("pbp_data") }}/pbp_data/g' "$file"
    sed -i '' 's/{{ ref("game_data") }}/game_data/g' "$file"
    sed -i '' 's/{{ ref("player_data") }}/player_data/g' "$file"
    sed -i '' 's/{{ ref("team_data") }}/team_data/g' "$file"
    sed -i '' 's/{{ ref("clean_data") }}/clean_data/g' "$file"
    sed -i '' 's/{{ ref("base_stats") }}/base_stats/g' "$file"
    sed -i '' 's/{{ ref("agg_stats") }}/agg_stats/g' "$file"
    sed -i '' 's/{{ ref("final_stats") }}/final_stats/g' "$file"
    sed -i '' 's/{{ ref("ranked_data") }}/ranked_data/g' "$file"
    sed -i '' 's/{{ ref("filtered_data") }}/filtered_data/g' "$file"
    sed -i '' 's/{{ ref("with_metrics") }}/with_metrics/g' "$file"
    sed -i '' 's/{{ ref("historical_data") }}/historical_data/g' "$file"
    sed -i '' 's/{{ ref("current_data") }}/current_data/g' "$file"
    sed -i '' 's/{{ ref("combined_data") }}/combined_data/g' "$file"
    sed -i '' 's/{{ ref("strength_metrics") }}/strength_metrics/g' "$file"
    sed -i '' 's/{{ ref("adjustment_metrics") }}/adjustment_metrics/g' "$file"
    sed -i '' 's/{{ ref("conference_strength") }}/conference_strength/g' "$file"
    sed -i '' 's/{{ ref("opponent_strength") }}/opponent_strength/g' "$file"
    sed -i '' 's/{{ ref("team_strength") }}/team_strength/g' "$file"
}

# Fix all staging models
for file in models/staging/*.sql; do
    if [[ -f "$file" ]]; then
        fix_cte_refs "$file"
    fi
done

# Fix all base models  
for file in models/base/*.sql; do
    if [[ -f "$file" ]]; then
        fix_cte_refs "$file"
    fi
done

# Fix all marts models
for file in models/marts/*.sql; do
    if [[ -f "$file" ]]; then
        fix_cte_refs "$file"
    fi
done

echo "✅ CTE reference fixes complete!"

# Test dbt parse
echo "🧪 Testing dbt parse..."
if dbt parse; then
    echo "✅ dbt parse successful!"
else
    echo "❌ dbt parse failed - manual fixes may be needed"
fi
