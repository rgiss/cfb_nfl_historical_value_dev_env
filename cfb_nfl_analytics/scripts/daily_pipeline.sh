#!/bin/bash

# Daily Data Pipeline Runner for Cron
# Runs the complete pipeline with logging and error handling

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/daily_pipeline_$(date +%Y%m%d_%H%M%S).log"

# Create logs directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Start logging
log "🚀 Starting daily data pipeline"
log "Log file: $LOG_FILE"

# Change to project directory
cd "$PROJECT_DIR"

# Set environment variables (these should be set in your system)
export DBT_POSTGRES_PASSWORD="${DBT_POSTGRES_PASSWORD:-your_postgres_password}"
export DB_HOST="${DB_HOST:-localhost}"
export DB_PORT="${DB_PORT:-5432}"
export DB_NAME="${DB_NAME:-cfb_nfl_analytics}"
export DB_USER="${DB_USER:-postgres}"

log "📊 Target database: $DB_NAME on $DB_HOST:$DB_PORT"

# Function to run command with logging
run_with_logging() {
    local cmd="$1"
    local description="$2"
    
    log "Starting: $description"
    log "Command: $cmd"
    
    if eval "$cmd" >> "$LOG_FILE" 2>&1; then
        log "✅ SUCCESS: $description"
        return 0
    else
        log "❌ FAILED: $description"
        return 1
    fi
}

# Main pipeline execution
PIPELINE_SUCCESS=true

# Step 1: R Data Ingestion
if run_with_logging "Rscript scripts/enhanced_data_ingestion.R" "R data ingestion"; then
    log "R data ingestion completed successfully"
else
    log "R data ingestion failed - aborting pipeline"
    PIPELINE_SUCCESS=false
fi

# Step 2: dbt transformations (only if R succeeded)
if [ "$PIPELINE_SUCCESS" = true ]; then
    # Load seeds first
    run_with_logging "dbt seed --target prod" "dbt seeds"
    
    # Run models
    if run_with_logging "dbt run --target prod" "dbt transformations"; then
        log "dbt transformations completed successfully"
    else
        log "dbt transformations failed"
        PIPELINE_SUCCESS=false
    fi
    
    # Run tests
    if run_with_logging "dbt test --target prod" "dbt tests"; then
        log "dbt tests passed"
    else
        log "Some dbt tests failed - check logs"
    fi
fi

# Final summary
if [ "$PIPELINE_SUCCESS" = true ]; then
    log "🎉 Daily pipeline completed successfully"
    
    # Log data summary
    log "📊 Data summary:"
    
    # Get row counts from key tables
    psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c "
    SELECT 
        schemaname, 
        tablename, 
        n_tup_ins - n_tup_del as row_count
    FROM pg_stat_user_tables 
    WHERE schemaname IN ('raw', 'staging', 'base', 'marts')
    ORDER BY schemaname, tablename;
    " >> "$LOG_FILE" 2>&1
    
    # Clean up old logs (keep last 30 days)
    find "$LOG_DIR" -name "daily_pipeline_*.log" -mtime +30 -delete 2>/dev/null
    
    log "✅ Pipeline completed successfully"
    exit 0
else
    log "❌ Pipeline failed - see logs for details"
    
    # Send failure notification (if configured)
    if [ ! -z "$NOTIFICATION_EMAIL" ]; then
        echo "Daily data pipeline failed at $(date). Check logs at $LOG_FILE" | \
        mail -s "CFB/NFL Pipeline Failed" "$NOTIFICATION_EMAIL" 2>/dev/null || true
    fi
    
    exit 1
fi
