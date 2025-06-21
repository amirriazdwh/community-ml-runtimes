#!/bin/bash
set -e

echo "🔧 Installing system dependencies for R with full graphics support..."

# Install graphics, math, font, and LaTeX libraries
apt-get update && apt-get install -y --no-install-recommends \
  libx11-dev libxt-dev libxext-dev libxrender-dev \
  libxrandr-dev libxfixes-dev libxi-dev libxinerama-dev \
  libxkbcommon-x11-0 libxcb1-dev libxss1 \
  libcairo2-dev libjpeg-dev libtiff5-dev libpng-dev \
  libfontconfig1-dev libfreetype6-dev librsvg2-dev \
  texlive texlive-latex-base texlive-latex-extra \
  texlive-fonts-recommended texlive-pictures \
  texinfo ghostscript \
  libopenblas-dev && \
apt-get clean && rm -rf /var/lib/apt/lists/*

echo "📦 Downloading R ${R_VERSION} from CRAN..."
wget -q "${CRAN}/src/base/R-4/R-${R_VERSION}.tar.gz" -O /tmp/R.tar.gz
tar -xf /tmp/R.tar.gz -C /tmp

echo "🛠️  Building and installing R ${R_VERSION}..."
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

echo "🧹 Cleaning up build files..."
rm -rf /tmp/R* /tmp/R-${R_VERSION}

echo "📁 Setting up R library path..."
mkdir -p /usr/local/lib/R/site-library
chmod -R a+w /usr/local/lib/R/site-library

echo "⚙️ Writing Rprofile.site options..."
cat <<EOF > /usr/local/lib/R/etc/Rprofile.site
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

echo "⚙️ Writing Renviron.site environment settings..."
cat <<EOF > /usr/local/lib/R/etc/Renviron.site
R_VERSION='${R_VERSION}'
R_ENABLE_JIT=3
R_COMPILE_PKGS=1
R_LIBS_USER='/usr/local/lib/R/site-library'
PATH=\${PATH}:/usr/local/lib/R/bin
EOF

echo "👤 Adjusting permissions for cdsw user..."
chown cdsw:cdsw /usr/local/lib/R/etc/Renviron.site
chown cdsw:cdsw /usr/local/lib/R/etc/Rprofile.site
chown -R cdsw:cdsw /usr/local/lib/R/site-library

echo "📦 Installing core graphics R packages..."
Rscript -e "install.packages(c('Cairo', 'svglite', 'tikzDevice', 'ragg', 'ggplot2', 'gridExtra'), repos='${CRAN}', quiet = TRUE)"

echo "✅ R ${R_VERSION} installation complete and fully graphics-enabled."
