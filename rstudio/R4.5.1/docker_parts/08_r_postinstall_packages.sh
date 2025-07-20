#!/bin/bash
set -e

echo "📦 Installing core R packages for professional use..."

# Default CRAN fallback
: "${CRAN:=https://cran.rstudio.com}"

###############################################################################
# 🧰 APT: Install missing system dependencies for R packages (Ubuntu 22.04)
###############################################################################

echo "🔧 Installing required system libraries..."

sudo apt-get update -qq && sudo apt-get install -y \
  # General build tools
  build-essential \
  g++ \
  cmake \
  git \
  curl \
  wget \
  unzip \
  libssl-dev \
  libxml2-dev \
  libcurl4-openssl-dev \
  pkg-config \
  zlib1g-dev \
  libbz2-dev \
  libicu-dev \
  libjpeg-dev \
  libpng-dev \
  libtiff5-dev \
  libreadline-dev \
  libx11-dev \
  libxt-dev \
  libgl1-mesa-dev \
  libglu1-mesa-dev \
  libfreetype6-dev \
  libharfbuzz-dev \
  libfribidi-dev \
  # For odbc
  unixodbc-dev \
  # For RPostgres
  libpq-dev \
  # For RMariaDB
  libmariadb-dev libmariadb-dev-compat \
  # For arrow
  libzstd-dev liblz4-dev libsnappy-dev libboost-all-dev \
  libarrow-dev libprotobuf-dev protobuf-compiler \
  libutf8proc-dev libre2-dev libgoogle-glog-dev \
  # For bigrquery (optional: supports GCP authentication)
  libcurl4-openssl-dev \
  # For future, parallelism
  libgomp1

echo "✅ System dependencies installed."

###############################################################################
# 🧪 1. Validate R Graphics and Capabilities
###############################################################################

echo "🧪 Checking R graphics and system capabilities..."
Rscript -e "cat('R capabilities:\n'); print(capabilities()); cat('\nSession Info:\n'); sessionInfo()"

###############################################################################
# 📦 2. Install Core Development & Data Packages
###############################################################################

Rscript -e "install.packages(c(
   'readr', 'readxl',
  'DBI', 'odbc', 'httr', 'jsonlite', 'curl', 'forcats',  'glue',
  'fs', 'rlang', 'remotes', 'tibble'
), repos = '${CRAN}', quiet = TRUE)"

###############################################################################
# 📄 3. Install Reporting, Reproducibility, and Workflow Tools
###############################################################################

Rscript -e "options(repos = c(CRAN = 'https://cran.rstudio.com')); install.packages(c(
  'knitr', 'bookdown', 'tinytex', 'quarto',
  'renv', 'pak', 'digest', 'assertthat'
), quiet = TRUE)"

# TinyTeX (skip if TeX Live is already present)
Rscript -e 'if (!tinytex::is_tinytex()) message("System TeX Live is available, skipping TinyTeX install.")'

###############################################################################
# 🧵 4. Parallelism, Future, Multithreading
###############################################################################

Rscript -e "install.packages(c(
  'future', 'doParallel', 'foreach', 'furrr'
), repos = '${CRAN}', quiet = TRUE)"

###############################################################################
# 🔌 5. Optional: DB/Cloud Integrations
###############################################################################

Rscript -e "install.packages(c(
  'RPostgres', 'RMariaDB', 'duckdb', 'arrow', 'bigrquery'
), repos = '${CRAN}', quiet = TRUE)"

echo "✅ All core packages for professional R use have been installed successfully."

# Optional: List installed packages
Rscript -e "cat('Installed packages:\n'); print(installed.packages()[, c('Package', 'Version')])"
