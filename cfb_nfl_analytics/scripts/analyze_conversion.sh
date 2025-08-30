#!/bin/bash

# Batch dbt Model Conversion Script
# This script converts all existing SQL files to dbt models systematically

PROJECT_DIR="/Users/riley.gisseman/Downloads/cfb_nfl_dev_env/cfb_nfl_analytics"
SOURCE_DIR="/Users/riley.gisseman/Downloads/cfb_nfl_dev_env/Data & Modeling/modeling"

echo "=== dbt Model Conversion Plan ==="

# 1. RAW LAYER - Convert raw SQL to sources
echo "1. Raw data tables to convert to sources:"
ls -1 "$SOURCE_DIR/raw/"*.sql | sed 's|.*/||' | sed 's|\.sql||'

# 2. PRE-PROCESSING LAYER - Convert to staging models  
echo ""
echo "2. Pre-processing to staging models:"
ls -1 "$SOURCE_DIR/pre/"*.sql | sed 's|.*/||' | sed 's|\.sql||'

# 3. BASE LAYER - Convert base models
echo ""
echo "3. Base models to convert:"
ls -1 "$SOURCE_DIR/base/"*.sql | sed 's|.*/||' | sed 's|\.sql||'

# 4. ADJUSTMENT LAYER - Convert to base models
echo ""
echo "4. Adjustment layer to base models:"
ls -1 "$SOURCE_DIR/adjustment layer/"*.sql | sed 's|.*/||' | sed 's|\.sql||'

# 5. FINAL MODELS - Convert to marts
echo ""
echo "5. Final models to marts:"
ls -1 "$SOURCE_DIR/model/"*.sql | sed 's|.*/||' | sed 's|\.sql||'

# 6. PYTHON MODELS - Special handling
echo ""
echo "6. Python/analysis models:"
ls -1 "$SOURCE_DIR/python/"*.sql 2>/dev/null | sed 's|.*/||' | sed 's|\.sql||' || echo "None found"

echo ""
echo "=== Total Models to Convert ==="
echo "Raw sources: $(ls -1 "$SOURCE_DIR/raw/"*.sql 2>/dev/null | wc -l)"
echo "Staging models: $(ls -1 "$SOURCE_DIR/pre/"*.sql 2>/dev/null | wc -l)"  
echo "Base models: $(ls -1 "$SOURCE_DIR/base/"*.sql 2>/dev/null | wc -l)"
echo "Adjustment models: $(ls -1 "$SOURCE_DIR/adjustment layer/"*.sql 2>/dev/null | wc -l)"
echo "Mart models: $(ls -1 "$SOURCE_DIR/model/"*.sql 2>/dev/null | wc -l)"
echo "Analysis models: $(ls -1 "$SOURCE_DIR/python/"*.sql 2>/dev/null | wc -l)"

TOTAL=$(find "$SOURCE_DIR" -name "*.sql" | wc -l)
echo "TOTAL: $TOTAL SQL files to convert"
