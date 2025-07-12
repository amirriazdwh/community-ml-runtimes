#!/bin/bash
set -euo pipefail

echo "🐍 Installing Python 3 and pip from local .deb files..."

DEB_DIR="/opt/python-packages"

# 1. Install all .deb files
echo "📦 Running dpkg -i..."
dpkg -i "$DEB_DIR"/*.deb

# 2. Disable internet-based apt sources to enforce offline-only installation
echo 'Dir::Etc::sourcelist "";' > /etc/apt/apt.conf.d/99offline-python
echo 'Dir::Etc::sourceparts "";' >> /etc/apt/apt.conf.d/99offline-python
echo 'Dir::Etc::main "/dev/null";' >> /etc/apt/apt.conf.d/99offline-python

# 3. Resolve broken dependencies using local-only APT cache
echo "🔍 Resolving dependencies using apt-get install -f (offline)..."
apt-get install -f -y

# 4. Add python → python3 symlink if needed
if [ ! -e /usr/bin/python ] && [ -e /usr/bin/python3 ]; then
    ln -s /usr/bin/python3 /usr/bin/python
    echo "🔗 Created /usr/bin/python → /usr/bin/python3"
fi

echo "✅ Python 3 and pip installed successfully without network access."
