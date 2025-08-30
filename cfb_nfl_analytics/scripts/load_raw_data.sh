#!/bin/bash

echo "📊 Loading essential raw data for dbt models..."

# Set database connection parameters
export PGPASSWORD="your_postgres_password"
DB_HOST="localhost"
DB_USER="postgres"  
DB_NAME="cfb_nfl_analytics"

echo "Loading NFL data..."

# Load NFL play-by-play data (main table)
echo "  Loading nfl_pbp_1999_2023.csv..."
psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "
DROP TABLE IF EXISTS raw.nfl_pbp_data;
CREATE TABLE raw.nfl_pbp_data AS
SELECT * FROM (VALUES (1)) AS dummy(x) LIMIT 0; -- Create empty table first
"

# Use Python to load CSV since it's large
python3 -c "
import pandas as pd
import sqlalchemy
from sqlalchemy import create_engine

print('Loading NFL PBP data with pandas...')
df = pd.read_csv('../Data & Modeling/data/raw_data/nfl_pbp_1999_2023.csv')
print(f'Loaded {len(df)} rows')

# Connect to database
engine = create_engine('postgresql://postgres:your_postgres_password@localhost:5432/cfb_nfl_analytics')

# Load to database
df.to_sql('nfl_pbp_data', engine, schema='raw', if_exists='replace', index=False, chunksize=1000)
print('✅ NFL PBP data loaded successfully')
"

echo "Loading NFL players data..."
psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "
DROP TABLE IF EXISTS raw.nfl_players;
"

python3 -c "
import pandas as pd
import sqlalchemy
from sqlalchemy import create_engine

print('Loading NFL players data...')
df = pd.read_csv('../Data & Modeling/data/raw_data/nfl_players.csv')
print(f'Loaded {len(df)} rows')

engine = create_engine('postgresql://postgres:your_postgres_password@localhost:5432/cfb_nfl_analytics')
df.to_sql('nfl_players', engine, schema='raw', if_exists='replace', index=False)
print('✅ NFL players data loaded successfully')
"

echo "Loading CFB data..."
python3 -c "
import pandas as pd  
import sqlalchemy
from sqlalchemy import create_engine

print('Loading CFB PBP data...')
df = pd.read_csv('../Data & Modeling/data/raw_data/cfb_pbp_2014_2024.csv')
print(f'Loaded {len(df)} rows')

engine = create_engine('postgresql://postgres:your_postgres_password@localhost:5432/cfb_nfl_analytics')
df.to_sql('college_football_play_by_play_data', engine, schema='raw', if_exists='replace', index=False, chunksize=1000)
print('✅ CFB PBP data loaded successfully')
"

echo "✅ Essential raw data loading complete!"
echo "Ready to run dbt models!"
