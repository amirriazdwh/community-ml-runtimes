#!/bin/bash
set -e

apt-get update && apt-get install -y --no-install-recommends \
  libx11-dev libxt-dev libxext-dev libxrender-dev \
  libxrandr-dev libxfixes-dev libxi-dev libxinerama-dev \
  libxkbcommon-x11-0 libxcb1-dev libxss1 \
  libcairo2-dev libjpeg-dev libtiff5-dev libpng-dev \
  libfontconfig1-dev libfreetype6-dev


# Download and extract R source
wget -q ${CRAN}/src/base/R-4/R-${R_VERSION}.tar.gz -O /tmp/R.tar.gz
tar -xf /tmp/R.tar.gz -C /tmp

# Build and install R
# (
#   cd /tmp/R-${R_VERSION}
#   ./configure \
#     --prefix=/usr/local \
#     --enable-R-shlib \
#     --with-blas=openblas \
#     --with-lapack \
#     --enable-memory-profiling \
#     --with-x=no \
#     CFLAGS="-g -O3 -pipe -fomit-frame-pointer" \
#     CXXFLAGS="-g -O3 -pipe -fomit-frame-pointer"
#   make -j"$(nproc --ignore=1)"
#   make install
# )

# Build and install R with X11 and OpenBLAS
(
  cd /tmp/R-${R_VERSION}
  ./configure \
    --prefix=/usr/local \
    --enable-R-shlib \
    --with-blas="-lopenblas" \
    --with-lapack \
    --enable-memory-profiling \
    --with-x=yes \
    CFLAGS="-g -O3 -pipe -fomit-frame-pointer" \
    CXXFLAGS="-g -O3 -pipe -fomit-frame-pointer"
  make -j"$(nproc --ignore=1)"
  make install
)



# Cleanup
rm -rf /tmp/R* /tmp/R-${R_VERSION}

# R library path setup
mkdir -p /usr/local/lib/R/site-library
chmod -R a+w /usr/local/lib/R/site-library

# Global default repo + global options
cat <<EOF >> /usr/local/lib/R/etc/Rprofile.site
options(
  repos = c(CRAN = '${CRAN}'),
  scipen = 999,
  digits = 4,
  width = 120,
  tidyverse.quiet = TRUE,
  warn = 1
)
bitmapType = "cairo"
EOF

# Runtime environment variables inside R
cat <<EOF >> /usr/local/lib/R/etc/Renviron.site
R_HOME='/usr/local/lib/R'
R_VERSION='${R_VERSION}'
R_ENABLE_JIT=3
R_COMPILE_PKGS=1
R_LIBS_USER='/usr/local/lib/R/site-library'
PATH=\${PATH}:/usr/local/lib/R/bin
EOF

# Make sure cdsw can write to this file at runtime
chown cdsw:cdsw /usr/local/lib/R/etc/Renviron.site
