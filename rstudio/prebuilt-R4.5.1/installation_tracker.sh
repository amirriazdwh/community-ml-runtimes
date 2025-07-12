#!/bin/bash

set -e

PKG="$1"

if [[ -z "$PKG" ]]; then
  echo "Usage: $0 <package-name>"
  exit 1
fi

echo "🔍 Resolving dependencies for $PKG..."
apt-rdepends "$PKG" | tee deps-full.txt

echo "📦 Downloading all .deb files..."
mkdir -p debs
cd debs
# Only select lines that are package names (no spaces, no colons)
apt-get download $(grep -E '^[a-zA-Z0-9.+-]+$' ../deps-full.txt | sort -u)
cd ..

echo "📥 Installing $PKG and dependencies..."
sudo apt-get install -y "$PKG"

echo "✅ Verifying installation..."
dpkg -l "$PKG" | grep ^ii || {
  echo "❌ Installation failed for $PKG"
  exit 2
}

echo "📝 Logging installed packages..."
apt-mark showmanual > manual-packages.txt
dpkg-query -W -f='${Package} ${Version}\n' > installed-packages.txt

echo "✅ Done. Logs and .deb files stored."
