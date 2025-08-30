#!/bin/bash

# Batch dbt Model Converter
# Systematically converts SQL files to dbt models with proper dependencies

set -e

PROJECT_DIR="/Users/riley.gisseman/Downloads/cfb_nfl_dev_env/cfb_nfl_analytics"
SOURCE_DIR="/Users/riley.gisseman/Downloads/cfb_nfl_dev_env/Data & Modeling/modeling"
LOG_FILE="$PROJECT_DIR/logs/conversion_$(date +%Y%m%d_%H%M%S).log"

mkdir -p "$PROJECT_DIR/logs"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

convert_sql_to_dbt() {
    local source_file="$1"
    local target_file="$2"
    local materialization="$3"
    local schema="$4"
    
    log "Converting $source_file to $target_file"
    
    # Create dbt header
    cat > "$target_file" << EOF
{{
  config(
    materialized='$materialization',
    schema='$schema'
  )
}}

-- Converted from: $source_file
-- $(basename "$source_file" .sql)

EOF
    
    # Extract SQL content (remove CREATE/DROP statements)
    sed -e '/^drop table/d' \
        -e '/^create table.*as$/d' \
        -e 's/from \([a-zA-Z_][a-zA-Z0-9_]*\)/from {{ ref("\1") }}/g' \
        -e 's/inner join \([a-zA-Z_][a-zA-Z0-9_]*\)/inner join {{ ref("\1") }}/g' \
        -e 's/left join \([a-zA-Z_][a-zA-Z0-9_]*\)/left join {{ ref("\1") }}/g' \
        -e 's/right join \([a-zA-Z_][a-zA-Z0-9_]*\)/right join {{ ref("\1") }}/g' \
        "$source_file" >> "$target_file"
    
    log "✅ Created $target_file"
}

log "=== Starting Batch dbt Conversion ==="

# Priority 1: Critical adjustment models (base layer)
log "=== Phase 1: Adjustment Models (Base Layer) ==="
convert_sql_to_dbt "$SOURCE_DIR/adjustment layer/cfb_beta_priors.sql" \
                   "$PROJECT_DIR/models/base/cfb_beta_priors.sql" \
                   "table" "base"

convert_sql_to_dbt "$SOURCE_DIR/adjustment layer/cfb_nfl_metrics_adjustment_dim.sql" \
                   "$PROJECT_DIR/models/base/cfb_nfl_metrics_adjustment_dim.sql" \
                   "table" "base"

convert_sql_to_dbt "$SOURCE_DIR/adjustment layer/cfb_opponent_strength_adjustment_metrics.sql" \
                   "$PROJECT_DIR/models/base/cfb_opponent_strength_adjustment_metrics.sql" \
                   "table" "base"

convert_sql_to_dbt "$SOURCE_DIR/adjustment layer/cfb_team_strength_adjustment_metrics.sql" \
                   "$PROJECT_DIR/models/base/cfb_team_strength_adjustment_metrics.sql" \
                   "table" "base"

# Priority 2: Pre-processing models (staging layer)
log "=== Phase 2: Pre-processing Models (Staging Layer) ==="
for file in "$SOURCE_DIR/pre/"*.sql; do
    filename=$(basename "$file" .sql)
    convert_sql_to_dbt "$file" \
                       "$PROJECT_DIR/models/staging/stg_$filename.sql" \
                       "view" "staging"
done

# Priority 3: Base game logs (already done, but update if needed)
log "=== Phase 3: Base Models ==="
if [ ! -f "$PROJECT_DIR/models/base/cfb_game_logs.sql" ]; then
    convert_sql_to_dbt "$SOURCE_DIR/base/cfb_game_logs.sql" \
                       "$PROJECT_DIR/models/base/cfb_game_logs.sql" \
                       "table" "base"
fi

# Priority 4: Final analytical models (marts layer)
log "=== Phase 4: Analytical Models (Marts Layer) ==="
convert_sql_to_dbt "$SOURCE_DIR/model/cfb_historical_value_estimate.sql" \
                   "$PROJECT_DIR/models/marts/cfb_historical_value_estimate.sql" \
                   "table" "marts"

convert_sql_to_dbt "$SOURCE_DIR/model/cfb_nfl_historical_value_estimate.sql" \
                   "$PROJECT_DIR/models/marts/cfb_nfl_historical_value_estimate.sql" \
                   "table" "marts"

log "=== Conversion Complete ==="
log "Converted models available in:"
log "- Staging: $(ls -1 "$PROJECT_DIR/models/staging/" | wc -l) models"
log "- Base: $(ls -1 "$PROJECT_DIR/models/base/" | wc -l) models"  
log "- Marts: $(ls -1 "$PROJECT_DIR/models/marts/" | wc -l) models"

log "Next steps:"
log "1. Review converted models for ref() corrections"
log "2. Update source() references for raw tables"
log "3. Run: dbt run --full-refresh"
log "4. Run: dbt test"
