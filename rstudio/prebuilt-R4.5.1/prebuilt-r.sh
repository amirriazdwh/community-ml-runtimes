#!/bin/bash
set -euo pipefail

###############################################################################
# 🧱 Build Precompiled R Runtime (Headless, LaTeX, Cairo, No X11)
# Usage:
#   ./build_r_prebuilt.sh 4.5.1 "ggplot2,Cairo,ragg" /opt/r-4.5.1
###############################################################################

R_VERSION="${1:-4.5.1}"
R_PACKAGES="${2:-}"
INSTALL_DIR="${3:-/opt/r-${R_VERSION}}"
CRAN_URL="${CRAN:-https://cran.rstudio.com}"
NUM_CORES=$(nproc || echo 2)
TAR_OUTPUT="./r-prebuilt-${R_VERSION}-ubuntu2204.tar.gz"

echo "🔧 Installing system dependencies for R $R_VERSION..."
apt-get update && apt-get install -y --no-install-recommends \
    build-essential gfortran wget curl ca-certificates gnupg \
    libreadline-dev libbz2-dev liblzma-dev libzstd-dev libicu-dev \
    libpcre2-dev libssl-dev libxml2-dev libcurl4-openssl-dev \
    libpng-dev libjpeg-dev libtiff5-dev libcairo2-dev \
    libfreetype6-dev libfontconfig1-dev librsvg2-dev \
    libharfbuzz-dev libfribidi-dev \
    libopenblas-dev liblapack-dev libarpack2-dev libsuitesparse-dev \
    texlive texlive-fonts-recommended texlive-latex-base texlive-latex-extra \
    texlive-pictures texinfo ghostscript \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

echo "📦 Downloading R ${R_VERSION}..."
cd /tmp
wget -q https://cran.r-project.org/src/base/R-4/R-${R_VERSION}.tar.gz -O R.tar.gz
tar -xf R.tar.gz
cd R-${R_VERSION}

echo "🛠️ Building R ${R_VERSION} (prefix=${INSTALL_DIR})..."
./configure \
    --prefix="${INSTALL_DIR}" \
    --enable-R-shlib \
    --enable-R-static-lib \
    --with-blas="-lopenblas" \
    --with-lapack \
    --enable-memory-profiling \
    --without-x \
    --with-cairo \
    CFLAGS="-O3 -pipe -fomit-frame-pointer" \
    CXXFLAGS="-O3 -pipe -fomit-frame-pointer"

make -j"${NUM_CORES}"
make install

# Create site-library and R configuration
mkdir -p "${INSTALL_DIR}/lib/R/site-library"
cat <<EOF > "${INSTALL_DIR}/lib/R/etc/Rprofile.site"
options(
  repos = c(CRAN = '${CRAN_URL}'),
  scipen = 999,
  digits = 4,
  width = 120,
  tidyverse.quiet = TRUE,
  warn = 1
)
bitmapType = "cairo"
EOF

cat <<EOF > "${INSTALL_DIR}/lib/R/etc/Renviron.site"
R_VERSION='${R_VERSION}'
R_ENABLE_JIT=3
R_COMPILE_PKGS=1
R_LIBS_US


sudo chown -R root:root /opt/r-4.5.1
sudo chown -R cdsw:cdsw /opt/r-4.5.1
cd /opt
sudo tar -czf /home/amirriaz/cloudera_community/community-ml-runtimes/rstudio/R4.5.1/r-prebuilt-4.5.1-ubuntu2204.tar.gz  /opt/r-4.5.1
