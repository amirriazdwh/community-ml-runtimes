#!/bin/bash
set -e

###############################################################################
# 🔧 CONFIGURATION
###############################################################################

RSTUDIO_VERSION=${RSTUDIO_VERSION:-2025.05.1}
RSTUDIO_URL="https://download2.rstudio.org/server/jammy/amd64/rstudio-server-${RSTUDIO_VERSION}-amd64.deb"
DEPS_DIR="./rstudio-deps"

# List of required .deb dependencies for RStudio Server
DEBIAN_PACKAGES=(
  gdebi-core lib32gcc-s1 libclang-dev libpq5 libnss3
  libcurl4-openssl-dev libssl-dev libxml2-dev libfontconfig1-dev
  libfreetype6-dev libpng-dev libjpeg-dev libtiff5-dev
  libx11-dev libxext-dev libxt-dev libxrender-dev libxrandr-dev
  libxfixes-dev libxi-dev libxinerama-dev libxkbcommon-x11-0 libxcb1-dev libxss1
  psmisc procps file git wget curl nano less sudo
)

mkdir -p "${DEPS_DIR}"

###############################################################################
# 📦 DOWNLOAD MISSING DEB PACKAGES
###############################################################################

echo "📦 Checking and downloading missing dependencies..."

for pkg in "${DEBIAN_PACKAGES[@]}"; do
  if dpkg -s "$pkg" >/dev/null 2>&1; then
    echo "✅ $pkg already installed"
  else
    echo "⬇️  $pkg missing — downloading..."
    apt-get download "$pkg"
    mv "${pkg}"_*.deb "${DEPS_DIR}/" 2>/dev/null || echo "⚠️  Could not move ${pkg} (check versioned filename)"
  fi
done

###############################################################################
# 📥 DOWNLOAD RSTUDIO SERVER .deb
###############################################################################

echo "📦 Downloading RStudio Server version: $RSTUDIO_VERSION..."

RSTUDIO_DEB="rstudio-server-${RSTUDIO_VERSION}-amd64.deb"
RSTUDIO_URL="https://download2.rstudio.org/server/jammy/amd64/${RSTUDIO_DEB}"

wget -q --show-progress --https-only "$RSTUDIO_URL" -O "${DEPS_DIR}/${RSTUDIO_DEB}"

# ✅ Check if the file was downloaded correctly
if [ ! -s "${DEPS_DIR}/${RSTUDIO_DEB}" ]; then
  echo "❌ Failed to download RStudio Server from $RSTUDIO_URL"
  exit 1
else
  echo "✅ Downloaded RStudio Server to ${DEPS_DIR}/${RSTUDIO_DEB}"
fi


###############################################################################
# 📦 DONE
###############################################################################

echo "🎁 All dependencies and RStudio Server saved in: ${DEPS_DIR}"
echo "📦 Contents:"
ls -1 "${DEPS_DIR}" | grep '.deb'
