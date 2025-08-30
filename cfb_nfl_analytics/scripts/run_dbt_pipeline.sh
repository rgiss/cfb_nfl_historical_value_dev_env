#!/usr/bin/env bash

# Run dbt pipeline using existing postgres.public tables

echo "🚀 Running CFB/NFL Analytics dbt Pipeline"
echo "=========================================="

# Prompt for PostgreSQL password
echo "Please enter your PostgreSQL password for user 'postgres':"
read -s POSTGRES_PASSWORD
export DBT_POSTGRES_PASSWORD="$POSTGRES_PASSWORD"

echo ""
echo "📊 Testing dbt connection..."

# Test dbt connection
if dbt debug --quiet; then
    echo "✅ dbt connection successful!"
else
    echo "❌ dbt connection failed. Please check your password and try again."
    exit 1
fi

echo ""
echo "🔨 Running dbt transformations..."

# Install dependencies
echo "Installing dbt dependencies..."
dbt deps

# Parse the project
echo "Parsing dbt project..."
dbt parse

# Run the models
echo "Running dbt models..."
dbt run

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 dbt pipeline completed successfully!"
    echo "Your analytical models are now built using your existing raw data!"
    echo ""
    echo "📋 Available models:"
    dbt ls --models tag:staging
    echo ""
    dbt ls --models tag:base 
    echo ""
    dbt ls --models tag:marts
else
    echo "❌ dbt pipeline failed"
    exit 1
fi
