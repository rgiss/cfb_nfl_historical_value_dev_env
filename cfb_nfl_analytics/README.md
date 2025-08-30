# 🏈 CFB/NFL Analytics Data Pipeline

A complete automated data pipeline for college football and NFL analytics, featuring:
- **R-based data ingestion** from cfbfastR and nflfastR
- **dbt transformations** for data modeling
- **PostgreSQL** for data storage
- **Automated scheduling** for daily updates
- **Integration ready** for your SvelteKit fantasy football app

## 🚀 Quick Start

### Prerequisites
- R (4.0+)
- PostgreSQL (12+)
- Python with dbt-postgres
- Git

### Setup

1. **Navigate to the project:**
   ```bash
   cd cfb_nfl_analytics
   ```

2. **Run the complete setup:**
   ```bash
   ./scripts/setup_complete_pipeline.sh
   ```

3. **Test the pipeline:**
   ```bash
   ./scripts/run_full_pipeline.sh
   ```

## 📊 Data Pipeline Architecture

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Data Sources  │ -> │ R Ingestion  │ -> │  PostgreSQL DB  │ -> │  dbt Transform  │
└─────────────────┘    └──────────────┘    └─────────────────┘    └─────────────────┘
│ cfbfastR        │    │ data_ingest  │    │ Raw Tables      │    │ Staging Models  │
│ nflfastR        │    │ .R scripts   │    │ - cfb_pbp_data  │    │ Base Models     │
│ Recruiting Data │    │              │    │ - nfl_pbp_data  │    │ Marts Models    │
└─────────────────┘    └──────────────┘    │ - nfl_players   │    └─────────────────┘
                                            └─────────────────┘
                                                     │
                                            ┌─────────────────┐
                                            │   Applications  │
                                            │ - SvelteKit App │
                                            │ - R Shiny App   │
                                            │ - CSV Exports   │
                                            └─────────────────┘
```

## 🚀 Quick Start

### 1. Prerequisites

```bash
# Install dependencies
brew install postgresql@14 r

# Install R packages
R -e "install.packages(c('cfbfastR', 'nflfastR', 'DBI', 'RPostgres', 'dplyr', 'readr'))"

# Install Python packages
pip install dbt-postgres psycopg2-binary
```

### 2. Database Setup

```bash
# Start PostgreSQL
brew services start postgresql@14

# Create database
psql -U postgres -c "CREATE DATABASE cfb_nfl_analytics;"
```

### 3. Environment Configuration

```bash
# Copy environment template
cp .env.example .env

# Edit .env file with your PostgreSQL password
echo "DBT_POSTGRES_PASSWORD=your_password_here" > .env
```

### 4. dbt Setup

```bash
# Initialize dbt (if not already done)
dbt init cfb_nfl_analytics

# Install dependencies and run
dbt deps
dbt seed
dbt run
dbt test
```

### 5. Run the Pipeline

```bash
# Manual run
./scripts/run_pipeline.sh

# Set up daily scheduling
./scripts/setup_scheduling.sh
```

## 📊 Data Models

### Staging Layer (`staging/`)
- **`stg_nfl_pbp`**: Cleaned NFL play-by-play data
- **`stg_cfb_pbp`**: Cleaned CFB play-by-play data

### Base Layer (`base/`)
- **`nfl_game_logs`**: Aggregated player game statistics
- **`nfl_beta_priors`**: Bayesian priors for player performance
- **`nfl_ra_epa_coefficients`**: EPA regression coefficients

### Marts Layer (`marts/`)
- **`nfl_historical_value_estimate`**: Final player value estimates
- **`cfb_nfl_historical_value_estimate`**: Combined CFB/NFL analysis
