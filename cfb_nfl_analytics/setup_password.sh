#!/usr/bin/env bash

# PostgreSQL password setup for dbt pipeline
# This will save your password for the current terminal session

echo "🔐 Setting up PostgreSQL password for dbt..."
echo "Enter your PostgreSQL password (it will be hidden):"
read -s POSTGRES_PASSWORD

# Export the password for this session
export DBT_POSTGRES_PASSWORD="$POSTGRES_PASSWORD"

# Save to a temporary file for easy re-sourcing
echo "export DBT_POSTGRES_PASSWORD=\"$POSTGRES_PASSWORD\"" > .env_temp

echo "✅ Password saved for this session!"
echo ""
echo "🔄 To reuse in new terminals, run: source .env_temp"
echo "🗑️  To clear: rm .env_temp"
echo ""
echo "Now you can run dbt commands without entering password each time:"
echo "  dbt debug"
echo "  dbt run"
echo "  ./run_simple.sh"
