#!/usr/bin/env bash

# Simple dbt runner - assumes you can connect to PostgreSQL
# Set your postgres password here temporarily for testing

# For testing, set a known password (you can change this)
echo "Enter your PostgreSQL password and press Enter:"
read -s POSTGRES_PASSWORD
export DBT_POSTGRES_PASSWORD="$POSTGRES_PASSWORD"

echo "Testing dbt connection..."
dbt debug

if [ $? -eq 0 ]; then
    echo "✅ Connection successful! Running dbt models..."
    
    # Run dbt
    dbt deps
    dbt parse
    dbt run
    
    if [ $? -eq 0 ]; then
        echo "🎉 Pipeline completed successfully!"
    else
        echo "❌ Pipeline failed during execution"
    fi
else
    echo "❌ Connection failed"
fi
