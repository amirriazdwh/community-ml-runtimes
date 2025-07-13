#!/bin/bash

# Shell script to install R packages for advanced banking, finance, and model validation

echo "Starting R package installation..."

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
  "plotly", "corrplot", "shiny", "flexdashboard", "DT", "highcharter", "patchwork", "cowplot",

  # Financial analysis
  "quantmod", "PerformanceAnalytics", "TTR", "PortfolioAnalytics", "FinancialInstrument", "blotter",
  "Quandl", "BatchGetSymbols",

  # Database and data import/export
  "DBI", "odbc", "RPostgres", "RMariaDB", "duckdb", "arrow", "readr", "readxl", "writexl", "openxlsx",

  # Miscellaneous utilities
  "purrr", "magrittr", "glue", "fs", "rlang", "remotes"
)

install.packages(packages, repos = "https://cloud.r-project.org", dependencies = TRUE)
cat("All advanced banking, financial, and model validation packages installed successfully.\n")
'

echo "R package installation complete."
