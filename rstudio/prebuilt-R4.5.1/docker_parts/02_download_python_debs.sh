#!/bin/bash
set -euo pipefail

echo "🐍 Downloading Python 3, pip, and all required dependencies for strict offline installation..."

# 🗂️ Set your safe custom path
BASE_DIR="/home/amirriaz/cloudera_community/community-ml-runtimes/rstudio/R4.5.1"
DOWNLOAD_DIR="$BASE_DIR/python-packages"
mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR"

export DEBIAN_FRONTEND=noninteractive

# 📦 Clean existing local cache
sudo apt-get clean
sudo rm -rf /var/cache/apt/archives/*.deb

# 🔄 Update APT metadata
echo "📦 Updating APT package lists..."
sudo apt-get update

# ⬇️ Download Python + all runtime/linking dependencies
sudo apt-get install --download-only -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-setuptools \
    python3-wheel \
    python3-distutils \
    libpython3-dev \
    libpython3-stdlib \
    libexpat1 \
    libmpdec3 \
    libffi-dev \
    libbz2-dev \
    liblzma-dev \
    libreadline-dev \
    libreadline8 \
    libsqlite3-0 \
    zlib1g-dev \
    openssl \
    mime-support \
    media-types \
    libssl-dev \
    ca-certificates \
    libncurses-dev \
    libgdbm-dev \
    libnsl-dev \
    libdb5.3 \
    libdb5.3-dev

# 📂 Copy downloaded .deb files to your local target directory
echo "📦 Copying downloaded .deb files to: $DOWNLOAD_DIR"
cp /var/cache/apt/archives/*.deb "$DOWNLOAD_DIR"

echo "✅ Python 3 + pip + all dependencies downloaded successfully for strict offline use."
