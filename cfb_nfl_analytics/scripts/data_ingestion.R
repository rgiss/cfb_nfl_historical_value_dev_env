#!/usr/bin/env Rscript

# CFB and NFL Data Ingestion Script
# This script downloads fresh data and loads it directly into PostgreSQL

library(cfbfastR)
library(nflfastR)
library(DBI)
library(RPostgres)
library(dplyr)
library(readr)
library(lubridate)

cat("🚀 Starting automated data pipeline...\n")

# Database connection
get_db_connection <- function() {
  # Try environment variables first, then fallback to defaults
  password <- Sys.getenv("DBT_POSTGRES_PASSWORD", "your_postgres_password")
  
  con <- dbConnect(
    RPostgres::Postgres(),
    host = Sys.getenv("DB_HOST", "localhost"),
    port = as.integer(Sys.getenv("DB_PORT", "5432")),
    dbname = Sys.getenv("DB_NAME", "cfb_nfl_analytics"),
    user = Sys.getenv("DB_USER", "postgres"),
    password = password
  )
  return(con)
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

# CFB Data Ingestion
ingest_cfb_data <- function(con) {
  cat("Starting CFB data ingestion...\n")
  
  # Get current season
  current_year <- as.integer(format(Sys.Date(), "%Y"))
  
  # CFB Play-by-play data (last 3 years for incremental updates)
  years_to_update <- (current_year-2):current_year
  
  for (year in years_to_update) {
    cat(sprintf("Downloading CFB play-by-play data for %d...\n", year))
    
    tryCatch({
      cfb_pbp <- cfbd_pbp_data(
        year = year,
        season_type = "regular",
        week = NULL
      )
      
      # Write to database (replace if exists for current year, append for others)
      write_mode <- if(year == current_year) "overwrite" else "append"
      
      dbWriteTable(
        con, 
        name = c("raw", "cfb_pbp_data"), 
        value = cfb_pbp,
        overwrite = (year == min(years_to_update)),
        append = (year != min(years_to_update))
      )
      
      cat(sprintf("✅ CFB %d data loaded successfully\n", year))
      
    }, error = function(e) {
      cat(sprintf("❌ Error loading CFB %d data: %s\n", year, e$message))
    })
  }
  
  # CFB Recruiting data
  cat("Downloading CFB recruiting data...\n")
  tryCatch({
    recruiting_data <- cfbd_recruiting_player(
      year = years_to_update,
      recruit_type = "HighSchool"
    )
    
    dbWriteTable(
      con,
      name = c("raw", "cfb_recruiting_data"),
      value = recruiting_data,
      overwrite = TRUE
    )
    
    cat("✅ CFB recruiting data loaded successfully\n")
    
  }, error = function(e) {
    cat(sprintf("❌ Error loading CFB recruiting data: %s\n", e$message))
  })
}

# NFL Data Ingestion  
ingest_nfl_data <- function(con) {
  cat("Starting NFL data ingestion...\n")
  
  # NFL Play-by-play data (last 3 seasons)
  current_year <- as.integer(format(Sys.Date(), "%Y"))
  seasons_to_update <- (current_year-2):current_year
  
  tryCatch({
    nfl_pbp <- nflfastR::load_pbp(seasons = seasons_to_update)
    
    dbWriteTable(
      con,
      name = c("raw", "nfl_pbp_data"),
      value = nfl_pbp,
      overwrite = TRUE
    )
    
    cat("✅ NFL play-by-play data loaded successfully\n")
    
  }, error = function(e) {
    cat(sprintf("❌ Error loading NFL data: %s\n", e$message))
  })
  
  # NFL Player data
  tryCatch({
    nfl_players <- nflfastR::load_players()
    
    dbWriteTable(
      con,
      name = c("raw", "nfl_players"),
      value = nfl_players,
      overwrite = TRUE
    )
    
    cat("✅ NFL players data loaded successfully\n")
    
  }, error = function(e) {
    cat(sprintf("❌ Error loading NFL players data: %s\n", e$message))
  })
}

# Main execution
main <- function() {
  cat("=== CFB/NFL Data Pipeline Started ===\n")
  cat(sprintf("Timestamp: %s\n", Sys.time()))
  
  # Connect to database
  con <- get_db_connection()
  on.exit(dbDisconnect(con))
  
  # Create raw schema if it doesn't exist
  dbExecute(con, "CREATE SCHEMA IF NOT EXISTS raw;")
  
  # Ingest data
  ingest_cfb_data(con)
  ingest_nfl_data(con)
  
  cat("=== Data Pipeline Completed ===\n")
}

# Run if called directly
if (!interactive()) {
  main()
}
