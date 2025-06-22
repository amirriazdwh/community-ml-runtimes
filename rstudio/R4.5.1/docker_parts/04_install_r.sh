#!/bin/bash
set -e

echo "🔧 Installing system dependencies for R with full graphics and LaTeX support..."

# Core graphics, math, and font libraries
apt-get update && apt-get install -y --no-install-recommends \
  libx11-dev libxt-dev libxext-dev libxrender-dev \
  libxrandr-dev libxfixes-dev libxi-dev libxinerama-dev \
  libxkbcommon-x11-0 libxcb1-dev libxss1 \
  libcairo2-dev libjpeg-dev libtiff5-dev libpng-dev \
  libfontconfig1-dev libfreetype6-dev librsvg2-dev \
  x11proto-core-dev xauth pkg-config libxrender1 \
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
    --enable-R-static-lib \
    --with-blas="-lopenblas" \
    --with-lapack \
    --enable-memory-profiling \
    --with-x=yes \
    --with-cairo \
    CFLAGS="-g -O3 -pipe -fomit-frame-pointer" \
    CXXFLAGS="-g -O3 -pipe -fomit-frame-pointer" \
    LIBS="-lX11 -lXrender"

  echo "🔍 Cairo and X11 config.log diagnostics:"
  grep -A5 'cairo' config.log || true
  grep -A5 'Xlib' config.log || true

  make -j"$(nproc --ignore=1)"
  make install
)

# Save config.log for troubleshooting
if [ -f /tmp/R-${R_VERSION}/config.log ]; then
  cp /tmp/R-${R_VERSION}/config.log /var/log/R-${R_VERSION}-config.log
  echo "✅ Copied config.log to /var/log"
else
  echo "⚠️ config.log not found!"
fi

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
