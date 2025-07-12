#!/bin/bash
set -euo pipefail

# 🗂️ Define base and target directories
BASE_DIR="/home/amirriaz/cloudera_community/community-ml-runtimes/rstudio/R4.5.1"
DOWNLOAD_DIR="$BASE_DIR/ubuntu-packages"

# ✅ Ensure the target directory exists
mkdir -p "$DOWNLOAD_DIR"

# 🚀 Change into the download directory
cd "$DOWNLOAD_DIR" || {
    echo "❌ Failed to enter directory: $DOWNLOAD_DIR"
    exit 1
}

echo "📁 Current working directory set to: $DOWNLOAD_DIR"


# 🧹 Clean up existing APT cache to prevent reuse
sudo apt-get clean
sudo rm -rf /var/cache/apt/archives/*.deb

# 🔄 Update package index
echo "📦 Updating APT package lists..."
sudo apt-get update

# 💾 Download all packages but do not install
echo "⬇️ Downloading .deb packages to: $DOWNLOAD_DIR ..."
sudo apt-get install --download-only -y \
    tzdata locales sudo \
    wget ca-certificates gdebi-core \
    psmisc procps file git less nano \
    build-essential gcc g++ gfortran make \
    libsasl2-modules-gssapi-mit krb5-user \
    libssl-dev libcurl4-openssl-dev libxml2-dev \
    libfontconfig1-dev libharfbuzz-dev libfribidi-dev \
    libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev \
    libicu-dev zlib1g-dev libbz2-dev liblzma-dev \
    libpcre2-dev libreadline-dev libxt-dev libcairo2-dev \
    libopenblas-dev liblapack-dev libarpack2-dev libsuitesparse-dev \
    libclang-dev lsb-release

# 📥 Copy the downloaded .deb files into your target folder
echo "📁 Copying downloaded packages to: $DOWNLOAD_DIR ..."
cp /var/cache/apt/archives/*.deb "$DOWNLOAD_DIR"

echo "✅ Done! All .deb files saved to: $DOWNLOAD_DIR"



