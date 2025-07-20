#!/bin/bash

# Shell script to install R packages for advanced banking, finance, model validation, and visualization

echo "🔧 Starting system dependency checks..."

# Step 1: Install system dependencies for key R packages
if [ -f "/etc/debian_version" ]; then
  echo "🟢 Detected Debian/Ubuntu. Installing system libraries..."

  sudo apt-get update -qq && sudo apt-get install -y \
    # General build tools
    build-essential g++ pkg-config cmake git curl wget unzip libssl-dev libxml2-dev libcurl4-openssl-dev \
    
    # For RPostgres
    libpq-dev \
    
    # For RMariaDB
    libmariadb-dev libmariadb-dev-compat \
    
    # For arrow and parquet support
    libzstd-dev liblz4-dev libsnappy-dev libboost-all-dev \
    
    # For prophet (Stan backend)
    libpython3-dev python3-venv python3-pip \
    
    # For odbc
    unixodbc-dev \
    
    # For tseries, urca, and other time series tools
    libgsl-dev

else
  echo "⚠️ Non-Debian system detected. Please install equivalent packages manually."
fi

echo "📦 Starting R package installation..."

Rscript -e '
packages <- c(
  # Data wrangling and manipulation
  "dplyr", "data.table", "tidyr", "lubridate", "stringr", "tibble", "janitor",

  # Time series and forecasting
  "forecast", "fable", "tsibble", "tseries", "prophet", "urca", "zoo", "xts", "seasonal", "tsoutliers",

  # Econometrics and statistics
  "car", "lmtest", "sandwich", "AER", "plm", "strucchange", "dynlm", "MASS", "nortest", "tseries",

  # Credit scoring and model validation
  "scorecard", "Information", "pROC", "ROCR", "caret", "yardstick", "DescTools", "ModelMetrics",
  "randomForest", "xgboost", "glmnet", "e1071",

  # Visualization and reporting
  "plotly", "corrplot", "shiny", "flexdashboard", "DT", "highcharter", "patchwork", "cowplot", "gapmap",

  # Financial analysis
  "quantmod", "PerformanceAnalytics", "TTR", "PortfolioAnalytics", "FinancialInstrument", "blotter",
  "Quandl", "BatchGetSymbols",

  # Database and data import/export
  "DBI", "odbc", "RPostgres", "RMariaDB", "duckdb", "arrow", "readr", "readxl", "writexl", "openxlsx",

  # Miscellaneous utilities
  "purrr", "magrittr", "glue", "fs", "rlang", "remotes"
)

install.packages(packages, repos = "https://cloud.r-project.org", dependencies = TRUE)
cat("✅ All advanced banking, financial, model validation, and visualization packages installed successfully.\n")
'

echo "✅ R package installation complete."
