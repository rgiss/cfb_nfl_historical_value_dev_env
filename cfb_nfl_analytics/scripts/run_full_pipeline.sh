#!/bin/bash

# Complete Data Pipeline Runner
# This script sets up the environment and runs the full data pipeline

echo "🚀 Starting Complete CFB/NFL Data Pipeline"
echo "=========================================="

# Set working directory
cd "$(dirname "$0")/.."

# Set environment variables
export DBT_POSTGRES_PASSWORD="${DBT_POSTGRES_PASSWORD:-your_postgres_password}"
export DB_HOST="${DB_HOST:-localhost}"
export DB_PORT="${DB_PORT:-5432}"
export DB_NAME="${DB_NAME:-cfb_nfl_analytics}"
export DB_USER="${DB_USER:-postgres}"

echo "📊 Database: $DB_NAME on $DB_HOST:$DB_PORT"
echo "👤 User: $DB_USER"

# Step 1: Run R data ingestion
echo ""
echo "Step 1: Running R data ingestion..."
echo "=================================="
Rscript scripts/enhanced_data_ingestion.R

if [ $? -eq 0 ]; then
    echo "✅ R data ingestion completed successfully"
else
    echo "❌ R data ingestion failed"
    exit 1
fi

# Step 2: Run dbt transformations
echo ""
echo "Step 2: Running dbt transformations..."
echo "===================================="

# First ensure seeds are loaded
echo "Loading dbt seeds..."
dbt seed --target dev

if [ $? -eq 0 ]; then
    echo "✅ dbt seeds loaded"
else
    echo "⚠️  dbt seeds failed, continuing anyway"
fi

# Run dbt models
echo "Running dbt models..."
dbt run --target dev

if [ $? -eq 0 ]; then
    echo "✅ dbt transformations completed successfully"
else
    echo "❌ dbt transformations failed"
    echo "🔍 Check the logs above for specific errors"
    exit 1
fi

# Step 3: Run dbt tests (optional)
echo ""
echo "Step 3: Running dbt tests..."
echo "==========================="
dbt test --target dev

if [ $? -eq 0 ]; then
    echo "✅ All dbt tests passed"
else
    echo "⚠️  Some dbt tests failed - check the output above"
fi

# Summary
echo ""
echo "🎉 Complete Pipeline Summary"
echo "==========================="
echo "✅ R data ingestion: Complete"
echo "✅ dbt transformations: Complete"
echo "✅ Data quality tests: Complete"
echo ""
echo "💡 Your data is now ready for analysis!"
echo "📊 Check your marts schema for analysis-ready tables"
echo "🔗 Connect your SvelteKit app to the database for live updates"
echo ""
echo "Next steps:"
echo "  - View data: psql -h $DB_HOST -U $DB_USER -d $DB_NAME"
echo "  - Run daily: Add this script to your cron jobs"
echo "  - Monitor: Check logs in logs/ directory"
