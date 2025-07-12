#!/bin/bash
set -euo pipefail

echo "📦 Strict offline install from: /opt/ubuntu-packages"

DEB_DIR="/opt/ubuntu-packages"

# Check if directory has .deb files
if compgen -G "$DEB_DIR/*.deb" > /dev/null; then
  echo "📁 Found .deb packages in $DEB_DIR"
else
  echo "❌ No .deb packages found in $DEB_DIR"
  exit 1
fi

# First attempt: install using dpkg
dpkg -i $DEB_DIR/*.deb || true

# Second pass: fix missing dependencies (but *strictly* using local .deb cache)
echo "🧩 Fixing dependencies using only offline .deb files..."

# Restrict APT to local debs only (no internet)
echo 'Dir::Etc::sourcelist "";' > /etc/apt/apt.conf.d/99offline
echo 'Dir::Etc::sourceparts "";' >> /etc/apt/apt.conf.d/99offline
echo 'Dir::Etc::main "/dev/null";' >> /etc/apt/apt.conf.d/99offline
echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/99local
echo 'Acquire::Retries "0";' >> /etc/apt/apt.conf.d/99local
echo 'Acquire::http::No-Cache "true";' >> /etc/apt/apt.conf.d/99local
echo 'Acquire::AllowInsecureRepositories "true";' >> /etc/apt/apt.conf.d/99local

# Final pass: apt-get install missing parts strictly offline
if ! apt-get install -f -y; then
  echo "❌ Offline install failed: Some dependencies are missing."
  echo "💡 Ensure all .deb files are included in /opt/ubuntu-packages."
  exit 1
fi

echo "✅ Offline install successful using only local .deb files."
