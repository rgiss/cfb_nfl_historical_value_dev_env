#!/usr/bin/env Rscript

# Enhanced CFB and NFL Data Ingestion Script
# Automatically downloads fresh data and loads it directly into PostgreSQL
# Supports incremental updates and smart data management

library(cfbfastR)
library(nflfastR)
library(DBI)
library(RPostgres)
library(dplyr)
library(readr)
library(lubridate)

cat("🚀 Starting enhanced automated data pipeline...\n")

# Database connection with better error handling
get_db_connection <- function() {
  # Get password from environment variable
  password <- Sys.getenv("DBT_POSTGRES_PASSWORD")
  if (password == "") {
    cat("❌ Please set DBT_POSTGRES_PASSWORD environment variable\n")
    stop("Database password not found in environment variables")
  }
  
  tryCatch({
    con <- dbConnect(
      RPostgres::Postgres(),
      host = Sys.getenv("DB_HOST", "localhost"),
      port = as.integer(Sys.getenv("DB_PORT", "5432")),
      dbname = Sys.getenv("DB_NAME", "cfb_nfl_analytics"),
      user = Sys.getenv("DB_USER", "postgres"),
      password = password
    )
    cat("✅ Database connection established\n")
    return(con)
  }, error = function(e) {
    cat("❌ Database connection failed:", e$message, "\n")
    cat("💡 Make sure PostgreSQL is running and accessible with user 'postgres'\n")
    stop("Cannot connect to database. Please check your connection settings.")
  })
}

# Create schemas if they don't exist
setup_database_schemas <- function(con) {
  cat("📊 Setting up database schemas...\n")
  
  schemas <- c("raw", "staging", "base", "marts", "snapshots")
  
  for (schema in schemas) {
    dbExecute(con, paste0("CREATE SCHEMA IF NOT EXISTS ", schema))
    cat("  ✅ Schema '", schema, "' ready\n")
  }
}

# Enhanced CFB Data Ingestion with smart incremental loading
ingest_cfb_data <- function(con) {
  cat("🏈 Starting CFB data ingestion...\n")
  
  # Get current season (CFB season spans Aug-Jan)
  current_year <- year(Sys.Date())
  if (month(Sys.Date()) < 6) current_year <- current_year - 1
  
  # Check what CFB data we already have
  existing_years <- tryCatch({
    if (dbExistsTable(con, c("raw", "cfb_pbp_data"))) {
      result <- dbGetQuery(con, "SELECT DISTINCT season FROM raw.cfb_pbp_data ORDER BY season")
      result$season
    } else {
      integer(0)
    }
  }, error = function(e) {
    cat("  No existing CFB data found, will create fresh table\n")
    integer(0)
  })
  
  # Determine years to update (current + last 2 years for incremental)
  years_to_update <- (current_year-2):current_year
  
  cat(sprintf("  Existing years: %s\n", ifelse(length(existing_years) > 0, paste(existing_years, collapse=", "), "none")))
  cat(sprintf("  Will update years: %s\n", paste(years_to_update, collapse=", ")))
  
  # Download and load CFB play-by-play data
  for (year in years_to_update) {
    cat(sprintf("  📥 Downloading CFB play-by-play data for %d...\n", year))
    
    tryCatch({
      # Get CFB play-by-play data
      cfb_pbp <- cfbd_pbp_data(
        year = year,
        season_type = "regular",
        week = NULL
      )
      
      if (nrow(cfb_pbp) > 0) {
        # Clean and standardize data
        cfb_pbp <- cfb_pbp %>%
          mutate(
            season = year,
            data_source = "cfbfastR",
            ingestion_timestamp = Sys.time()
          )
        
        # Handle table creation/updates
        if (year %in% existing_years) {
          # Update existing year - delete old data first
          dbExecute(con, sprintf("DELETE FROM raw.cfb_pbp_data WHERE season = %d", year))
          dbWriteTable(con, name = c("raw", "cfb_pbp_data"), value = cfb_pbp, append = TRUE)
          cat(sprintf("    ✅ Updated CFB %d data (%d rows)\n", year, nrow(cfb_pbp)))
        } else {
          # New year - append or create table
          table_exists <- dbExistsTable(con, c("raw", "cfb_pbp_data"))
          dbWriteTable(
            con, 
            name = c("raw", "cfb_pbp_data"), 
            value = cfb_pbp,
            overwrite = !table_exists,
            append = table_exists
          )
          cat(sprintf("    ✅ Added CFB %d data (%d rows)\n", year, nrow(cfb_pbp)))
        }
      } else {
        cat(sprintf("    ⚠️  No CFB data found for %d\n", year))
      }
      
    }, error = function(e) {
      cat(sprintf("    ❌ Error loading CFB %d data: %s\n", year, e$message))
    })
    
    # Brief pause to be respectful to the API
    Sys.sleep(2)
  }
  
  # Also get team/conference data  
  cat("  📥 Downloading CFB team and conference data...\n")
  tryCatch({
    cfb_teams <- cfbd_team_info(year = current_year)
    if (nrow(cfb_teams) > 0) {
      cfb_teams$ingestion_timestamp <- Sys.time()
      dbWriteTable(con, name = c("raw", "cfb_teams"), value = cfb_teams, overwrite = TRUE)
      cat(sprintf("    ✅ CFB team data loaded (%d teams)\n", nrow(cfb_teams)))
    }
  }, error = function(e) {
    cat(sprintf("    ❌ Error loading CFB team data: %s\n", e$message))
  })
  
  cat("✅ CFB data ingestion complete\n")
}

# Enhanced NFL Data Ingestion
ingest_nfl_data <- function(con) {
  cat("🏈 Starting NFL data ingestion...\n")
  
  # Get current season (NFL season spans Sep-Feb)
  current_year <- year(Sys.Date())
  if (month(Sys.Date()) < 3) current_year <- current_year - 1
  
  # Check what NFL data we already have
  existing_years <- tryCatch({
    if (dbExistsTable(con, c("raw", "nfl_pbp_data"))) {
      result <- dbGetQuery(con, "SELECT DISTINCT season FROM raw.nfl_pbp_data ORDER BY season")
      result$season
    } else {
      integer(0)
    }
  }, error = function(e) {
    cat("  No existing NFL data found, will create fresh table\n")
    integer(0)
  })
  
  # Determine years to update (current + last 2 years)
  years_to_update <- (current_year-2):current_year
  
  cat(sprintf("  Existing years: %s\n", ifelse(length(existing_years) > 0, paste(existing_years, collapse=", "), "none")))
  cat(sprintf("  Will update years: %s\n", paste(years_to_update, collapse=", ")))
  
  # Download and load NFL play-by-play data
  for (year in years_to_update) {
    cat(sprintf("  📥 Downloading NFL play-by-play data for %d...\n", year))
    
    tryCatch({
      # Get NFL play-by-play data
      nfl_pbp <- load_pbp(seasons = year)
      
      if (nrow(nfl_pbp) > 0) {
        # Clean and standardize data
        nfl_pbp <- nfl_pbp %>%
          mutate(
            data_source = "nflfastR",
            ingestion_timestamp = Sys.time()
          )
        
        # Handle table creation/updates
        if (year %in% existing_years) {
          # Update existing year
          dbExecute(con, sprintf("DELETE FROM raw.nfl_pbp_data WHERE season = %d", year))
          dbWriteTable(con, name = c("raw", "nfl_pbp_data"), value = nfl_pbp, append = TRUE)
          cat(sprintf("    ✅ Updated NFL %d data (%d rows)\n", year, nrow(nfl_pbp)))
        } else {
          # New year
          table_exists <- dbExistsTable(con, c("raw", "nfl_pbp_data"))
          dbWriteTable(
            con, 
            name = c("raw", "nfl_pbp_data"), 
            value = nfl_pbp,
            overwrite = !table_exists,
            append = table_exists
          )
          cat(sprintf("    ✅ Added NFL %d data (%d rows)\n", year, nrow(nfl_pbp)))
        }
      }
      
    }, error = function(e) {
      cat(sprintf("    ❌ Error loading NFL %d data: %s\n", year, e$message))
    })
    
    # Brief pause
    Sys.sleep(2)
  }
  
  # Also get player data
  cat("  📥 Downloading NFL player data...\n")
  tryCatch({
    nfl_players <- load_players()
    if (nrow(nfl_players) > 0) {
      nfl_players$ingestion_timestamp <- Sys.time()
      dbWriteTable(con, name = c("raw", "nfl_players"), value = nfl_players, overwrite = TRUE)
      cat(sprintf("    ✅ NFL player data loaded (%d players)\n", nrow(nfl_players)))
    }
  }, error = function(e) {
    cat(sprintf("    ❌ Error loading NFL player data: %s\n", e$message))
  })
  
  cat("✅ NFL data ingestion complete\n")
}

# Load additional reference data
load_reference_data <- function(con) {
  cat("📚 Loading reference data...\n")
  
  # Create dummy tables for missing sources that dbt expects
  missing_tables <- list(
    "cfb_elo_data" = data.frame(team = character(), year = integer(), week = integer(), elo = numeric()),
    "college_football_play_by_play_data" = data.frame() # Will be populated by CFB data above
  )
  
  for (table_name in names(missing_tables)) {
    if (!dbExistsTable(con, c("raw", table_name))) {
      dbWriteTable(con, name = c("raw", table_name), value = missing_tables[[table_name]], overwrite = TRUE)
      cat(sprintf("  ✅ Created placeholder table: %s\n", table_name))
    }
  }
}

# Main execution function
main <- function() {
  cat("🎯 Starting enhanced data pipeline execution...\n")
  
  # Connect to database
  con <- get_db_connection()
  
  tryCatch({
    # Setup
    setup_database_schemas(con)
    
    # Load data
    ingest_cfb_data(con)
    ingest_nfl_data(con)
    load_reference_data(con)
    
    # Create summary
    cat("\n📊 Pipeline Summary:\n")
    
    # Check data counts
    tables_to_check <- c("cfb_pbp_data", "nfl_pbp_data", "nfl_players", "cfb_teams")
    for (table in tables_to_check) {
      tryCatch({
        count <- dbGetQuery(con, sprintf("SELECT COUNT(*) as count FROM raw.%s", table))$count
        cat(sprintf("  ✅ %s: %s rows\n", table, format(count, big.mark = ",")))
      }, error = function(e) {
        cat(sprintf("  ❌ %s: Not available\n", table))
      })
    }
    
    cat("\n🎉 Data pipeline completed successfully!\n")
    cat("💡 Next steps:\n")
    cat("   1. Run 'dbt run' to transform the data\n")
    cat("   2. Run 'dbt test' to validate data quality\n")
    cat("   3. Check your marts for analysis-ready data\n")
    
  }, finally = {
    dbDisconnect(con)
    cat("🔐 Database connection closed\n")
  })
}

# Execute if script is run directly
if (!interactive()) {
  main()
}
