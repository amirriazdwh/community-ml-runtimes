#!/bin/bash
set -e

echo "📦 Installing pre-downloaded .deb packages..."

# Directory where the .deb files are located
DEB_DIR="/opt/ubuntu-packages"

# Install all packages
dpkg -i $DEB_DIR/*.deb || true

# Fix missing dependencies
apt-get update
apt-get install -f -y

echo "✅ All .deb packages installed successfully."
