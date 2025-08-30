#!/bin/bash

# dbt Reference Fixer
# Fixes common reference issues in converted models

PROJECT_DIR="/Users/riley.gisseman/Downloads/cfb_nfl_dev_env/cfb_nfl_analytics"
LOG_FILE="$PROJECT_DIR/logs/reference_fix_$(date +%Y%m%d_%H%M%S).log"

mkdir -p "$PROJECT_DIR/logs"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

fix_references() {
    local model_dir="$1"
    log "Fixing references in $model_dir models..."
    
    # Fix common table references to use source() for raw tables
    for file in "$model_dir"/*.sql; do
        if [ -f "$file" ]; then
            log "Processing $(basename "$file")"
            
            # Raw table references should use source()
            sed -i '' -e 's/{{ ref("nfl_players") }}/{{ source("raw", "nfl_players") }}/g' \
                      -e 's/{{ ref("nfl_hex") }}/{{ source("raw", "nfl_hex") }}/g' \
                      -e 's/{{ ref("cfb_hex") }}/{{ source("raw", "cfb_hex") }}/g' \
                      -e 's/{{ ref("cfb_elo_data") }}/{{ source("raw", "cfb_elo_data") }}/g' \
                      -e 's/{{ ref("nfl_snap_counts_2012_2024") }}/{{ source("raw", "nfl_snap_counts_2012_2024") }}/g' \
                      -e 's/{{ ref("cfb_recruiting_data") }}/{{ source("raw", "cfb_recruiting_data") }}/g' \
                      -e 's/{{ ref("college_football_play_by_play_data") }}/{{ source("raw", "college_football_play_by_play_data") }}/g' \
                      -e 's/{{ ref("nfl_ra_epa_coefficients") }}/{{ source("raw", "nfl_ra_epa_coefficients") }}/g' \
                      "$file"
            
            # Fix problematic table names that don't exist
            sed -i '' -e 's/{{ ref("player_years") }}/{{ ref("stg_cfb_player_name_ids") }}/g' \
                      -e 's/{{ ref("cfb_player_name_ids") }}/{{ ref("stg_cfb_player_name_ids") }}/g' \
                      -e 's/{{ ref("clean_cfb_player_names") }}/{{ ref("stg_clean_cfb_player_names") }}/g' \
                      -e 's/{{ ref("cfb_clean_player_positions") }}/{{ ref("stg_cfb_clean_player_positions") }}/g' \
                      -e 's/{{ ref("cfb_conferences") }}/{{ ref("stg_cfb_conferences") }}/g' \
                      -e 's/{{ ref("ncaaf_season_games_regularization") }}/{{ ref("stg_ncaaf_season_games_regularization") }}/g' \
                      -e 's/{{ ref("cfb_nfl_player_id_map") }}/{{ ref("stg_cfb_nfl_player_id_map") }}/g' \
                      -e 's/{{ ref("nfl_pbp_1999_2024") }}/{{ ref("stg_nfl_pbp_1999_2024") }}/g' \
                      "$file"
        fi
    done
}

log "=== Starting Reference Fixes ==="

# Fix staging models first
fix_references "$PROJECT_DIR/models/staging"

# Fix base models
fix_references "$PROJECT_DIR/models/base"

# Fix marts models  
fix_references "$PROJECT_DIR/models/marts"

log "=== Reference fixes complete ==="
log "Next step: dbt parse to check for remaining issues"
