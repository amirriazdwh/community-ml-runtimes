#!/bin/bash
set -e

# 🗂️ Use a safe custom path without overwriting HOME
BASE_DIR="/home/amirriaz/cloudera_community/community-ml-runtimes/rstudio/R4.5.1/docker_parts"
DOWNLOAD_DIR="$BASE_DIR/ubuntu-packages"

# ✅ Ensure all parent directories exist
mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR"

echo "📦 Updating apt cache..."
sudo apt-get update

echo "⬇️ Downloading .deb files (not installing)..."
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

echo "✅ All downloaded packages are cached in /var/cache/apt/archives"
echo "📂 You can copy them to $DOWNLOAD_DIR using:"
echo "   cp /var/cache/apt/archives/*.deb \"$DOWNLOAD_DIR\""
