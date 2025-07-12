#!/bin/bash
set -e

echo "🔧 Installing system dependencies for advanced R graphics..."

# Install core X11 and graphics libraries with xvfb for headless R
apt-get update && \
apt-get install -y --no-install-recommends \
    xorg xvfb \
    libx11-dev libxt-dev libxext-dev libxrender-dev \
    libxrandr-dev libxfixes-dev libxi-dev libxinerama-dev \
    libxkbcommon-x11-0 libxcb1-dev libxss1 \
    libcairo2-dev libjpeg-dev libtiff5-dev libgif-dev \
    libfontconfig1-dev libfreetype6-dev libpng-dev && \
apt-get clean && rm -rf /var/lib/apt/lists/*

# Install LaTeX toolchain for tikzDevice
echo "📦 Installing LaTeX stack for tikzDevice..."
apt-get update && \
apt-get install -y --no-install-recommends \
    texlive texlive-latex-base texlive-latex-extra \
    texlive-fonts-recommended texlive-pictures texinfo ghostscript && \
apt-get clean && rm -rf /var/lib/apt/lists/*

# Install R graphics-related packages
echo "📦 Installing R graphics packages..."
#this is dupplication.
#Rscript -e "install.packages(c('svglite', 'tikzDevice'), repos=Sys.getenv('CRAN'), quiet=TRUE)"
#Rscript -e "install.packages(c('gridExtra', 'gridBase'), repos=Sys.getenv('CRAN'), quiet=TRUE)"
# duplicate end here. 
# Set bitmapType to 'cairo' for headless graphics
echo "options(bitmapType='cairo')" >> /usr/local/lib/R/etc/Rprofile.site

# Set DISPLAY for Xvfb (this persists only for shell-based R)
echo 'export DISPLAY=:99' > /etc/profile.d/x11.sh
chmod +x /etc/profile.d/x11.sh

echo "✅ Advanced R graphics setup complete."
