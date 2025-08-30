#!/bin/bash

# Complete Setup Script for CFB/NFL Analytics Pipeline
# Sets up everything needed for the data pipeline

echo "🚀 CFB/NFL Analytics Pipeline Setup"
echo "===================================="

# Get the directory this script is in
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "📁 Project directory: $PROJECT_DIR"
cd "$PROJECT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function for colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Step 1: Check prerequisites
echo ""
echo "Step 1: Checking prerequisites..."
echo "================================="

# Check if R is installed
if command -v R &> /dev/null; then
    R_VERSION=$(R --version | head -1)
    print_status "R is installed: $R_VERSION"
else
    print_error "R is not installed. Please install R first."
    echo "  macOS: brew install r"
    echo "  Ubuntu: sudo apt-get install r-base"
    exit 1
fi

# Check if PostgreSQL is installed
if command -v psql &> /dev/null; then
    PG_VERSION=$(psql --version)
    print_status "PostgreSQL is installed: $PG_VERSION"
else
    print_error "PostgreSQL is not installed. Please install PostgreSQL first."
    echo "  macOS: brew install postgresql"
    echo "  Ubuntu: sudo apt-get install postgresql postgresql-contrib"
    exit 1
fi

# Check if Python/dbt is available
if command -v dbt &> /dev/null; then
    DBT_VERSION=$(dbt --version | head -1)
    print_status "dbt is installed: $DBT_VERSION"
else
    print_error "dbt is not installed. Please install dbt first."
    echo "  pip install dbt-postgres"
    exit 1
fi

# Step 2: Set up R packages
echo ""
echo "Step 2: Setting up R packages..."
echo "==============================="

if Rscript scripts/setup_r_packages.R; then
    print_status "R packages setup completed"
else
    print_error "R packages setup failed"
    exit 1
fi

# Step 3: Database setup
echo ""
echo "Step 3: Database setup..."
echo "========================="

# Prompt for database password
echo "Please enter your PostgreSQL password for user 'postgres':"
read -s DB_PASSWORD
export DBT_POSTGRES_PASSWORD="$DB_PASSWORD"

# Test database connection
echo "Testing database connection..."
if psql -h localhost -U postgres -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
    print_status "Database connection successful"
else
    print_error "Database connection failed. Please check your PostgreSQL installation and password."
    exit 1
fi

# Create database if it doesn't exist
echo "Creating database if needed..."
psql -h localhost -U postgres -c "CREATE DATABASE cfb_nfl_analytics;" 2>/dev/null || echo "Database may already exist"

# Step 4: dbt setup
echo ""
echo "Step 4: dbt setup..."
echo "==================="

# Create profiles directory if it doesn't exist
mkdir -p ~/.dbt

# Create or update dbt profiles
cat > ~/.dbt/profiles.yml << EOF
cfb_nfl_analytics:
  target: dev
  outputs:
    dev:
      type: postgres
      host: localhost
      user: postgres
      password: "$DB_PASSWORD"
      port: 5432
      dbname: cfb_nfl_analytics
      schema: public
      threads: 4
      keepalives_idle: 0
    prod:
      type: postgres
      host: localhost
      user: postgres
      password: "$DB_PASSWORD"
      port: 5432
      dbname: cfb_nfl_analytics
      schema: public
      threads: 4
      keepalives_idle: 0
EOF

print_status "dbt profiles configured"

# Test dbt connection
if dbt debug; then
    print_status "dbt connection test successful"
else
    print_error "dbt connection test failed"
    exit 1
fi

# Step 5: Create necessary directories
echo ""
echo "Step 5: Creating directories..."
echo "==============================="

mkdir -p logs
mkdir -p data/exports
mkdir -p data/backups

print_status "Directory structure created"

# Step 6: Set up automation (optional)
echo ""
echo "Step 6: Setting up automation..."
echo "==============================="

# Make scripts executable
chmod +x scripts/*.sh
chmod +x scripts/*.R

print_status "Scripts made executable"

# Step 7: Create environment file
echo ""
echo "Step 7: Creating environment file..."
echo "===================================="

cat > .env << EOF
# Database Configuration
DBT_POSTGRES_PASSWORD="$DB_PASSWORD"
DB_HOST=localhost
DB_PORT=5432
DB_NAME=cfb_nfl_analytics
DB_USER=postgres

# Pipeline Configuration
ENVIRONMENT=dev
LOG_LEVEL=INFO

# Optional: Email notifications
# NOTIFICATION_EMAIL=your-email@example.com
EOF

print_status "Environment file created"

# Final summary
echo ""
echo "🎉 Setup Complete!"
echo "=================="
print_status "R packages installed and configured"
print_status "Database connection tested"
print_status "dbt profiles configured"
print_status "Directory structure created"
print_status "Scripts made executable"
print_status "Environment configured"

echo ""
echo "💡 Next Steps:"
echo "=============="
echo "1. Test the pipeline:"
echo "   ./scripts/run_full_pipeline.sh"
echo ""
echo "2. Set up daily automation (optional):"
echo "   crontab -e"
echo "   Add: 0 6 * * * $PROJECT_DIR/scripts/daily_pipeline.sh"
echo ""
echo "3. Connect your SvelteKit app to the database:"
echo "   Database: cfb_nfl_analytics"
echo "   Host: localhost:5432"
echo "   Schemas: raw, staging, base, marts"
echo ""
echo "4. Monitor logs:"
echo "   tail -f logs/daily_pipeline_*.log"

echo ""
print_warning "Remember to keep your database password secure!"
print_warning "Consider using environment variables in production"

echo ""
echo "🚀 Ready to run your CFB/NFL analytics pipeline!"
