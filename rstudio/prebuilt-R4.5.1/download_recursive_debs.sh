#!/bin/bash
set -euo pipefail

PKG_LIST=(
    # Core Python
    python3
    python3-pip
    python3-venv
    python3-setuptools
    python3-wheel
    python3-distutils
    libpython3-dev
    libpython3-stdlib

    # Python deps
    libexpat1
    libmpdec3
    libffi-dev
    libbz2-dev
    liblzma-dev
    libreadline-dev
    zlib1g-dev
)

TARGET_DIR="$HOME/cloudera_community/community-ml-runtimes/rstudio/R4.5.1/python-pkgs-complete"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

echo "📦 Gathering all dependencies recursively..."
ALL_PKGS=$(apt-rdepends "${PKG_LIST[@]}" \
    | grep -v "^ " \
    | grep -v "^PreDepends:" \
    | grep -v "^Depends:" \
    | grep -v "^Conflicts:" \
    | grep -v "^Recommends:" \
    | grep -v "^Suggests:" \
    | sort -u)

echo "⬇️ Downloading .deb files for:"
echo "$ALL_PKGS"

for pkg in $ALL_PKGS; do
    apt-get download "$pkg"
done

echo "✅ All required .deb files downloaded to $TARGET_DIR"
