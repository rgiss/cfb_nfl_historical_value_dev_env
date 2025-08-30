#!/bin/bash

# CFB/NFL Data Pipeline Runner
# This script orchestrates the entire data pipeline

set -e  # Exit on any error

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | xargs)
fi

# Configuration
PROJECT_DIR="/Users/riley.gisseman/Downloads/cfb_nfl_dev_env/cfb_nfl_analytics"
LOG_DIR="$PROJECT_DIR/logs"
DATE=$(date +%Y%m%d_%H%M%S)

# Create logs directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_DIR/pipeline_$DATE.log"
}

# Function to run and log commands
run_with_logging() {
    log "Running: $1"
    if eval "$1" 2>&1 | tee -a "$LOG_DIR/pipeline_$DATE.log"; then
        log "✅ SUCCESS: $1"
        return 0
    else
        log "❌ FAILED: $1"
        return 1
    fi
}

log "=== CFB/NFL Data Pipeline Started ==="

# Step 1: Data Ingestion (R scripts)
log "Step 1: Running data ingestion..."
cd "$PROJECT_DIR"

if run_with_logging "Rscript scripts/data_ingestion.R"; then
    log "Data ingestion completed successfully"
else
    log "Data ingestion failed"
    exit 1
fi

# Step 2: dbt run (transform data)
log "Step 2: Running dbt transformations..."

# Activate virtual environment
source ../data-pipeline/.venv/bin/activate

# Set up dbt profiles
export DBT_PROFILES_DIR="$PROJECT_DIR"

if run_with_logging "dbt deps"; then
    log "dbt dependencies installed"
fi

if run_with_logging "dbt seed"; then
    log "dbt seeds loaded"
fi

if run_with_logging "dbt run"; then
    log "dbt models built successfully"
else
    log "dbt run failed"
    exit 1
fi

# Step 3: dbt test (data quality checks)
log "Step 3: Running data quality tests..."

if run_with_logging "dbt test"; then
    log "All tests passed"
else
    log "Some tests failed - check logs"
    # Don't exit on test failures, just log them
fi

# Step 4: Export data for applications
log "Step 4: Exporting data for applications..."

# Export to CSV for SvelteKit app
if run_with_logging "psql -h localhost -U postgres -d cfb_nfl_analytics -c \"\\copy (SELECT * FROM marts.nfl_historical_value_estimate WHERE position_group IN ('QB','RB','WR','TE') ORDER BY true_date DESC LIMIT 10000) TO '$PROJECT_DIR/../fantasy-football-analyzer/static/cfb_nfl_historical_value_estimate.csv' CSV HEADER\""; then
    log "Data exported to SvelteKit app"
fi

# Step 5: Cleanup old logs (keep last 30 days)
log "Step 5: Cleaning up old logs..."
find "$LOG_DIR" -name "pipeline_*.log" -mtime +30 -delete 2>/dev/null || true

log "=== CFB/NFL Data Pipeline Completed Successfully ==="
log "Total runtime: $SECONDS seconds"

# Send notification (optional)
if command -v osascript &> /dev/null; then
    osascript -e 'display notification "CFB/NFL Data Pipeline completed successfully" with title "Data Pipeline"'
fi
