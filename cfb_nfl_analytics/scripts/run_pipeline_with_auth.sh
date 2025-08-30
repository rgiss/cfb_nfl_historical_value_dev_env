#!/usr/bin/env bash

# Simple setup script to run the complete pipeline with password authentication

echo "🚀 CFB/NFL Analytics Pipeline Setup"
echo "====================================="

# Prompt for PostgreSQL password
echo "Please enter your PostgreSQL password for user 'postgres':"
read -s POSTGRES_PASSWORD
export DBT_POSTGRES_PASSWORD="$POSTGRES_PASSWORD"

echo ""
echo "📊 Testing database connection..."

# Test the connection
if psql -h localhost -p 5432 -U postgres -d cfb_nfl_analytics -c "SELECT 1;" >/dev/null 2>&1; then
    echo "✅ Database connection successful!"
else
    echo "❌ Database connection failed. Please check your password and try again."
    exit 1
fi

echo ""
echo "🔄 Running data ingestion..."

# Run R data ingestion
cd /Users/riley.gisseman/Downloads/cfb_nfl_dev_env/cfb_nfl_analytics
Rscript scripts/enhanced_data_ingestion.R

if [ $? -eq 0 ]; then
    echo "✅ Data ingestion completed successfully!"
else
    echo "❌ Data ingestion failed"
    exit 1
fi

echo ""
echo "🔨 Running dbt transformations..."

# Run dbt
dbt deps
dbt debug
dbt seed
dbt run

if [ $? -eq 0 ]; then
    echo "✅ dbt transformations completed successfully!"
    echo ""
    echo "🎉 Complete pipeline execution finished!"
    echo "Your database is now populated with fresh CFB and NFL data!"
else
    echo "❌ dbt transformations failed"
    exit 1
fi
