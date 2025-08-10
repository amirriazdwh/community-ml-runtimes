#!/bin/bash
set -e
###############################################################################
# 🛠️ Build and Install R from Source (Graphics + LaTeX, X11-Free)
###############################################################################

# 🌐 Default environment variables (safe fallback)
: "${R_VERSION:=4.5.1}"
: "${CRAN:=https://cran.rstudio.com}"

echo "🔧 Installing system dependencies for R ${R_VERSION} with graphics and LaTeX support (no X11)..."

###############################################################################
# 📦 R INSTALLATION DEPENDENCIES
###############################################################################

# 🖼️ Stage 3: Graphics, fonts, and SVG support (headless, no X11)
apt-get update && apt-get install -y --no-install-recommends \
    libcairo2-dev libjpeg-dev libtiff5-dev libpng-dev \
    libfontconfig1-dev libfreetype6-dev librsvg2-dev \
    libharfbuzz-dev libfribidi-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 📚 Stage 4: LaTeX and PDF rendering toolchain (for R Markdown, Quarto)
apt-get update && apt-get install -y --no-install-recommends \
    texlive texlive-latex-base texlive-latex-extra \
    texlive-fonts-recommended texlive-pictures \
    texinfo ghostscript \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 🔢 Stage 5: Math, compression, and scientific computing
apt-get update && apt-get install -y --no-install-recommends \
    libopenblas-dev liblapack-dev libarpack2-dev libsuitesparse-dev \
    libicu-dev zlib1g-dev libbz2-dev liblzma-dev libpcre2-dev \
    libreadline-dev libxt-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

###############################################################################
# 📥 Download, Build, and Install R
###############################################################################

echo "📦 Downloading R ${R_VERSION} from CRAN..."
wget -q "${CRAN}/src/base/R-4/R-${R_VERSION}.tar.gz" -O /tmp/R.tar.gz
tar -xf /tmp/R.tar.gz -C /tmp

echo "🛠️  Building R ${R_VERSION} from source..."
(
  cd /tmp/R-${R_VERSION}

  ./configure \
    --prefix=/usr/local \
    --enable-R-shlib \
    --enable-R-static-lib \
    --with-blas="-lopenblas" \
    --with-lapack \
    --enable-memory-profiling \
    --without-x \
    --with-cairo \
    CFLAGS="-g -O3 -pipe -fomit-frame-pointer" \
    CXXFLAGS="-g -O3 -pipe -fomit-frame-pointer"

  make -j"$(nproc --ignore=1)"
  make install
)

# Save config.log for debugging
if [ -f /tmp/R-${R_VERSION}/config.log ]; then
  cp /tmp/R-${R_VERSION}/config.log /var/log/R-${R_VERSION}-config.log
  echo "✅ Copied config.log to /var/log"
else
  echo "⚠️ config.log not found!"
fi

# Clean build files
rm -rf /tmp/R* /tmp/R-${R_VERSION}

###############################################################################
# ⚙️ R Configuration
###############################################################################

mkdir -p /usr/local/lib/R/site-library
chmod -R a+w /usr/local/lib/R/site-library

cat <<EOF > /usr/local/lib/R/etc/Rprofile.site
# Global R configuration for ALL users
# This applies automatically to every R session

# CRAN repository
options(
  repos = c(CRAN = '${CRAN}'),
  download.file.method = 'libcurl',
  timeout = 300
)

# Display and output settings
options(
  max.print = 10000,
  scipen = 6,
  digits = 4,
  width = 120,
  menu.graphics = FALSE,
  browserNLdisabled = TRUE,
  crayon.enabled = TRUE,
  tidyverse.quiet = TRUE,
  warn = 1
)

# Graphics settings
bitmapType = "cairo"

# Performance settings - use all available cores
if (requireNamespace("parallel", quietly = TRUE)) {
  options(
    mc.cores = parallel::detectCores(),
    Ncpus = parallel::detectCores()
  )
}

# Global startup message for interactive sessions
if (interactive()) {
  cat('RStudio Server - Global optimizations active\\n')
  if (requireNamespace("parallel", quietly = TRUE)) {
    cat('Available CPU cores:', parallel::detectCores(), '\\n')
  }
  cat('Graphics device: cairo\\n')
}
EOF

cat <<EOF > /usr/local/lib/R/etc/Renviron.site
R_VERSION='${R_VERSION}'

# Performance optimizations
R_ENABLE_JIT=3
R_COMPILE_PKGS=1

# Memory and parallel processing
R_GC_MEM_GROW=3
R_NSIZE=500000
R_VSIZE=15000000

# Library paths
R_LIBS_USER='/usr/local/lib/R/site-library'
R_LIBS_SITE='/usr/local/lib/R/site-library'

# System paths
PATH=\${PATH}:/usr/local/lib/R/bin

# Graphics and display
R_BROWSER='false'
R_PDFVIEWER='false'

# Network and downloads
R_DOWNLOAD_FILE_METHOD='libcurl'
R_TIMEOUT=300
EOF

# Ensure correct ownership for multi-user setup (rstudio-users group)
chown root:rstudio-users /usr/local/lib/R/etc/Renviron.site
chown root:rstudio-users /usr/local/lib/R/etc/Rprofile.site
chown -R root:rstudio-users /usr/local/lib/R/site-library

# Set group write permissions so all users can install packages
chmod 664 /usr/local/lib/R/etc/Renviron.site
chmod 664 /usr/local/lib/R/etc/Rprofile.site
chmod -R 775 /usr/local/lib/R/site-library

# Ensure R executable has correct permissions
chmod +x /usr/local/bin/R
chmod +x /usr/local/bin/Rscript
chown root:rstudio-users /usr/local/bin/R
chown root:rstudio-users /usr/local/bin/Rscript

###############################################################################
# 📦 Install Essential Graphics R Packages (no X11 required)
###############################################################################
echo "📦 Installing R graphics packages..."
Rscript -e "install.packages(c('Cairo', 'svglite', 'ragg', 'ggplot2', 'gridExtra', 'gridBase', 'tikzDevice'), repos=Sys.getenv('CRAN'), quiet=TRUE)"


echo "✅ R ${R_VERSION} installation complete with headless graphics and LaTeX."