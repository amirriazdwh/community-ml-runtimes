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
    libharfbuzz-dev libfribidi-dev gettext-base \
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

# Create modular R profile configuration directory
mkdir -p /usr/local/lib/R/etc/profiles.d

# Copy and process the base Rprofile.site configuration with variable substitution
envsubst < /tmp/docker_parts/Rprofile.site.base > /usr/local/lib/R/etc/Rprofile.site

cat <<EOF > /usr/local/lib/R/etc/Renviron.site
# R Version Information
R_VERSION='${R_VERSION}'

# Performance optimizations
R_ENABLE_JIT=3
R_COMPILE_PKGS=1

# Memory and parallel processing (balanced settings)
R_GC_MEM_GROW=3
R_NSIZE=350000
R_VSIZE=8000000

# Library paths
R_LIBS_USER='/usr/local/lib/R/site-library'
R_LIBS_SITE='/usr/local/lib/R/site-library'

# System paths (fixed PATH escaping)
PATH="\${PATH}:/usr/local/bin"

# Graphics and display (headless configuration with Cairo)
R_BROWSER='false'
R_PDFVIEWER='false'
R_DEVICE='cairo'

# Network and downloads
R_DOWNLOAD_FILE_METHOD='libcurl'
R_TIMEOUT=300
R_ZIPCMD='/usr/bin/zip'
R_UNZIPCMD='/usr/bin/unzip'

# Python integration (for RStudio and reticulate)
RETICULATE_PYTHON='/usr/bin/python3'

# Config directory handling (for RStudio)
R_USER_CONFIG_DIR='/tmp/r-config'
RSTUDIO_CONFIG_HOME='/tmp/rstudio-config'

# Additional R environment variables
R_HISTSIZE=2000
R_DEFAULT_PACKAGES='datasets,utils,grDevices,graphics,stats,methods'
R_PROFILE_USER='/dev/null'

# LaTeX and document processing
R_LATEXCMD='/usr/bin/pdflatex'
R_MAKEINDEXCMD='/usr/bin/makeindex'
R_DVIPSCMD='/usr/bin/dvips'

# Platform and architecture information
R_PLATFORM='x86_64-pc-linux-gnu'
R_ARCH=''
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