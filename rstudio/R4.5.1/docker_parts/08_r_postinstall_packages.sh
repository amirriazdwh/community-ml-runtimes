#!/bin/bash
set -e

echo "🛠 Preparing apt environment..."
apt-get update && apt-get install -y apt-utils

echo "📦 Installing core R packages for professional use..."

: "${CRAN:=https://cran.rstudio.com}"

echo "🔧 Installing required system libraries..."

# ✅ SINGLE apt-get install block — DO NOT BREAK
apt-get update -qq && apt-get install -y \
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
  unixodbc-dev \
  libpq-dev \
  libmariadb-dev \
  libmariadb-dev-compat \
  libzstd-dev \
  liblz4-dev \
  libsnappy-dev \
  libboost-all-dev \
  libprotobuf-dev \
  protobuf-compiler \
  libutf8proc-dev \
  libre2-dev \
  libgoogle-glog-dev \
  python3-dev \
  python3-venv \
  python3-pip \
  libgomp1 \
  libgsl-dev

echo "✅ System dependencies installed."

echo "🧪 Checking R graphics and system capabilities..."
Rscript -e "cat('R capabilities:\n'); print(capabilities()); cat('\nSession Info:\n'); sessionInfo()"

Rscript -e "install.packages(c(
  'readr', 'readxl',
  'DBI', 'odbc', 'httr', 'jsonlite', 'curl', 'forcats', 'glue',
  'fs', 'rlang', 'remotes', 'tibble'
), repos = '${CRAN}', quiet = TRUE)"

Rscript -e "options(repos = c(CRAN = '${CRAN}')); install.packages(c(
  'knitr', 'bookdown', 'tinytex', 'quarto',
  'renv', 'pak', 'digest', 'assertthat'
), quiet = TRUE)"

Rscript -e 'if (!tinytex::is_tinytex()) message("System TeX Live is available, skipping TinyTeX install.")'

Rscript -e "install.packages(c(
  'future', 'doParallel', 'foreach', 'furrr'
), repos = '${CRAN}', quiet = TRUE)"

Rscript -e "install.packages(c(
  'RPostgres', 'RMariaDB', 'duckdb', 'arrow', 'bigrquery'
), repos = '${CRAN}', quiet = TRUE)"

echo "✅ All core packages for professional R use have been installed successfully."

Rscript -e "cat(\"Installed packages:\\n\"); print(installed.packages()[, c('Package', 'Version')])"
