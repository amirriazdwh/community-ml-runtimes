#!/bin/bash
set -e

echo "📦 Installing core R packages for professional use..."

# Default CRAN fallback
: "${CRAN:=https://cran.rstudio.com}"

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

#odbc failed.

###############################################################################
# 📄 3. Install Reporting, Reproducibility, and Workflow Tools
###############################################################################

# 1. Set CRAN mirror and install packages (safe quoting)
Rscript -e "options(repos = c(CRAN = 'https://cran.rstudio.com')); install.packages(c(
  'knitr', 'bookdown', 'tinytex', 'quarto',
  'renv', 'pak', 'digest', 'assertthat'
), quiet = TRUE)"

# 2. Only initialize TinyTeX if needed — use single quotes to avoid shell interpreting !
Rscript -e 'if (!tinytex::is_tinytex()) message("System TeX Live is available, skipping TinyTeX install.")'


###############################################################################
# 🧵 4. Parallelism, Future, Multithreading
###############################################################################

Rscript -e "install.packages(c(
  'future', 'doParallel', 'foreach', 'furrr'
), repos = 'https://cran.rstudio.com', quiet = TRUE)"


###############################################################################
# 🔌 5. Optional: DB/Cloud Integrations
###############################################################################

Rscript -e "install.packages(c(
  'RPostgres', 'RMariaDB', 'duckdb', 'arrow', 'bigrquery'
), repos = '${CRAN}', quiet = TRUE)"

echo "✅ All core packages for professional R use have been installed successfully."

# Optional: run this to check installed packages
Rscript -e "cat('Installed packages:\n'); print(installed.packages()[, c('Package', 'Version')])"
