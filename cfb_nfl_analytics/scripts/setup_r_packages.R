#!/usr/bin/env Rscript

# R Package Installation and Setup Script
# Installs all required R packages for the CFB/NFL data pipeline

cat("🔧 Setting up R environment for CFB/NFL data pipeline...\n")

# List of required packages
required_packages <- c(
  "cfbfastR",     # College Football data
  "nflfastR",     # NFL data  
  "DBI",          # Database interface
  "RPostgres",    # PostgreSQL driver
  "dplyr",        # Data manipulation
  "readr",        # CSV reading
  "lubridate",    # Date/time handling
  "jsonlite",     # JSON handling
  "httr",         # HTTP requests
  "rvest",        # Web scraping (if needed)
  "tidyr"         # Data tidying
)

# Function to install package if not already installed
install_if_missing <- function(package) {
  if (!require(package, character.only = TRUE, quietly = TRUE)) {
    cat(sprintf("📦 Installing %s...\n", package))
    install.packages(package, repos = "https://cran.rstudio.com/")
    
    # Verify installation
    if (require(package, character.only = TRUE, quietly = TRUE)) {
      cat(sprintf("✅ %s installed successfully\n", package))
      return(TRUE)
    } else {
      cat(sprintf("❌ Failed to install %s\n", package))
      return(FALSE)
    }
  } else {
    cat(sprintf("✅ %s already installed\n", package))
    return(TRUE)
  }
}

# Install packages
cat("Installing required R packages...\n")
installation_results <- sapply(required_packages, install_if_missing)

# Check results
failed_packages <- names(installation_results)[!installation_results]

if (length(failed_packages) > 0) {
  cat(sprintf("\n❌ Failed to install: %s\n", paste(failed_packages, collapse = ", ")))
  cat("Please install these packages manually:\n")
  for (pkg in failed_packages) {
    cat(sprintf("  install.packages('%s')\n", pkg))
  }
  quit(status = 1)
} else {
  cat("\n✅ All R packages installed successfully!\n")
}

# Test database connection
cat("\n🔍 Testing database connection...\n")

tryCatch({
  library(DBI)
  library(RPostgres)
  
  # Try to connect (will fail if DB not running, but that's expected)
  con <- dbConnect(
    RPostgres::Postgres(),
    host = "localhost",
    port = 5432,
    dbname = "cfb_nfl_analytics", 
    user = "postgres",
    password = Sys.getenv("DBT_POSTGRES_PASSWORD", "your_postgres_password")
  )
  
  # If we get here, connection worked
  dbDisconnect(con)
  cat("✅ Database connection test successful\n")
  
}, error = function(e) {
  cat("⚠️  Database connection test failed (this is normal if PostgreSQL isn't running yet)\n")
  cat("   Make sure PostgreSQL is running before running the data pipeline\n")
})

# Print setup summary
cat("\n🎉 R Environment Setup Complete!\n")
cat("====================================\n")
cat("✅ All required packages installed\n")
cat("✅ Database drivers ready\n")
cat("✅ Ready to run data pipeline\n")
cat("\nNext steps:\n")
cat("1. Ensure PostgreSQL is running\n")
cat("2. Set DBT_POSTGRES_PASSWORD environment variable\n")
cat("3. Run: ./scripts/run_full_pipeline.sh\n")

cat("\nPackage versions:\n")
for (pkg in required_packages) {
  if (pkg %in% rownames(installed.packages())) {
    version <- packageVersion(pkg)
    cat(sprintf("  %s: %s\n", pkg, version))
  }
}
