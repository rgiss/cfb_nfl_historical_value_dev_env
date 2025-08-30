#!/bin/bash

# Setup script for daily data pipeline scheduling
# This script sets up a cron job to run the data pipeline daily

SCRIPT_DIR="/Users/riley.gisseman/Downloads/cfb_nfl_dev_env/cfb_nfl_analytics/scripts"
PIPELINE_SCRIPT="$SCRIPT_DIR/run_pipeline.sh"

echo "Setting up daily data pipeline scheduling..."

# Check if pipeline script exists and is executable
if [ ! -x "$PIPELINE_SCRIPT" ]; then
    echo "Error: Pipeline script not found or not executable at $PIPELINE_SCRIPT"
    exit 1
fi

# Create cron job (runs daily at 6:00 AM)
CRON_JOB="0 6 * * * cd $SCRIPT_DIR && ./run_pipeline.sh >> $SCRIPT_DIR/../logs/cron.log 2>&1"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "run_pipeline.sh"; then
    echo "Cron job already exists. Current crontab:"
    crontab -l | grep "run_pipeline.sh"
else
    # Add the cron job
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "✅ Cron job added successfully!"
    echo "Pipeline will run daily at 6:00 AM"
    echo "Logs will be written to: $SCRIPT_DIR/../logs/"
fi

echo ""
echo "Current crontab:"
crontab -l

echo ""
echo "To remove the cron job, run:"
echo "crontab -e"
echo "Then delete the line containing 'run_pipeline.sh'"

echo ""
echo "To test the pipeline manually, run:"
echo "cd $SCRIPT_DIR && ./run_pipeline.sh"
