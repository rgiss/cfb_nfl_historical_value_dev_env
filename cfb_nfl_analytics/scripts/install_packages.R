#!/usr/bin/env Rscript

# Install required R packages for the CFB/NFL analytics pipeline
cat("Installing required R packages...\n")

packages <- c(
  'RPostgres',  # PostgreSQL driver for R
  'DBI',        # Database interface
  'cfbfastR',   # College football data
  'nflfastR',   # NFL data
  'dplyr',      # Data manipulation
  'lubridate'   # Date handling
)

for (pkg in packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat(paste("Installing", pkg, "...\n"))
    install.packages(pkg, repos = 'https://cran.r-project.org/')
  } else {
    cat(paste("✓", pkg, "already installed\n"))
  }
}

cat("✅ All required R packages are now available!\n")
