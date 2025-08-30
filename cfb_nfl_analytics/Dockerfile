FROM rocker/r-ver:4.3.0

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    postgresql-client \
    curl \
    cron \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c('cfbfastR', 'nflfastR', 'DBI', 'RPostgres', 'dplyr', 'readr'), repos='https://cran.rstudio.com/')"

# Set up Python virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python packages
RUN pip install --no-cache-dir \
    dbt-postgres==1.10.10 \
    psycopg2-binary

# Create app directory
WORKDIR /app

# Copy application files
COPY . .

# Make scripts executable
RUN chmod +x scripts/*.sh

# Create logs directory
RUN mkdir -p logs

# Set up cron job
RUN echo "0 6 * * * cd /app && ./scripts/run_pipeline.sh >> logs/cron.log 2>&1" | crontab -

# Default command
CMD ["cron", "-f"]
