#!/bin/bash

# Fix remaining CTE reference issues in specific models

echo "🔧 Fixing remaining CTE reference issues..."

# Fix stg_cfb_player_name_ids.sql
echo "Fixing stg_cfb_player_name_ids.sql..."
sed -i '' 's/{{ ref("player_histories") }}/player_histories/g' models/staging/stg_cfb_player_name_ids.sql
sed -i '' 's/{{ ref("player_name_ids") }}/player_name_ids/g' models/staging/stg_cfb_player_name_ids.sql  
sed -i '' 's/{{ ref("player_id_careers") }}/player_id_careers/g' models/staging/stg_cfb_player_name_ids.sql

# Fix cfb_game_logs.sql - remove commented conversion_rate references
echo "Fixing cfb_game_logs.sql..."
sed -i '' '/conversion_rate_by_down_distance/d' models/base/cfb_game_logs.sql

# Fix cfb_nfl_metrics_adjustment_dim.sql - check if it has CTEs to fix
echo "Fixing cfb_nfl_metrics_adjustment_dim.sql..."
sed -i '' 's/{{ ref("cfb_nfl_metrics_adjustment_dim") }}/cfb_nfl_metrics_adjustment_dim/g' models/base/cfb_nfl_metrics_adjustment_dim.sql

# Fix final reference at end of cfb_game_logs.sql
echo "Checking cfb_game_logs.sql for union references..."
sed -i '' 's/{{ ref("game_logs_union") }}/game_logs_union/g' models/base/cfb_game_logs.sql

echo "✅ CTE reference fixes complete!"

# Test dbt parse
echo "🧪 Testing dbt parse..."
if dbt parse; then
    echo "✅ dbt parse successful!"
else
    echo "❌ dbt parse failed - checking errors..."
    dbt parse 2>&1 | head -20
fi
