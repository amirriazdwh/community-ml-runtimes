#!/bin/bash
set -e

# Download and install RStudio Server
echo "📦 Downloading and installing RStudio Server version: $RSTUDIO_VERSION"
wget https://download2.rstudio.org/server/jammy/amd64/rstudio-server-${RSTUDIO_VERSION}-amd64.deb -O /tmp/rstudio.deb
gdebi -n /tmp/rstudio.deb
rm /tmp/rstudio.deb

# Setup runtime directories
mkdir -p /etc/rstudio /var/lib/rstudio-server
chmod 1777 /var/lib/rstudio-server
chown -R cdsw:cdsw /var/lib/rstudio-server

# Create secure cookie key
echo "🔑 Creating secure-cookie-key..."
head -c 512 /dev/urandom > /etc/rstudio/secure-cookie-key
chmod 0600 /etc/rstudio/secure-cookie-key
chown cdsw:cdsw /etc/rstudio/secure-cookie-key

# Increase file descriptor limits
cat <<EOF >> /etc/security/limits.conf
cdsw soft nofile 65535
cdsw hard nofile 65535
EOF

# Enable PAM limits
echo "session required pam_limits.so" >> /etc/pam.d/common-session

# Strip unnecessary symbols to reduce image size
strip /usr/lib/rstudio-server/bin/rserver /usr/lib/rstudio-server/bin/rsession || true
rm -rf /usr/lib/rstudio-server/www/help

# ============================
# === Advanced R Features ===
# ============================

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
Rscript -e "install.packages(c('Cairo', 'ggplot2', 'gridExtra', 'gridBase'), repos=Sys.getenv('CRAN'), quiet=TRUE)"
Rscript -e "install.packages(c('svglite', 'tikzDevice'), repos=Sys.getenv('CRAN'), quiet=TRUE)"

# Set bitmapType to 'cairo'
echo "options(bitmapType='cairo')" >> /usr/local/lib/R/etc/Rprofile.site

# Explicitly launch Xvfb background server for headless X11
cat <<'EOF' > /etc/profile.d/x11.sh
#!/bin/bash
if command -v Xvfb >/dev/null; then
  Xvfb :99 -screen 0 1024x768x16 &>/dev/null &
  export DISPLAY=:99
fi
EOF
chmod +x /etc/profile.d/x11.sh

# ================================
# === R Reporting & PDF Tools ===
# ================================
Rscript -e "install.packages(c( \
  'rmarkdown', 'knitr', 'bookdown', 'flexdashboard', 'officer', 'flextable', \
  'tinytex', 'kableExtra', 'pagedown', 'gt', 'rmdformats', 'webshot', \
  'xml2', 'rsvg', 'patchwork'), repos=Sys.getenv('CRAN'), quiet=TRUE)"
Rscript -e "webshot::install_phantomjs()"
Rscript -e "tinytex::install_tinytex(force = TRUE)"

# Cleanup cache and temp files
rm -rf /tmp/* /var/tmp/* /root/.cache /home/cdsw/.cache /var/lib/apt/lists/*

# ===============================
# === GUI Preferences for cdsw ==
# ===============================
mkdir -p /home/cdsw/.config/rstudio && \
  cat <<PREFS > /home/cdsw/.config/rstudio/rstudio-prefs.json
{
  "font_size_points": 9,
  "font": "Fira Code",
  "ui_theme": "Modern",
  "editor_theme": "Tomorrow Night Bright",
  "show_line_numbers": true,
  "highlight_selected_line": true,
  "soft_wrap_r_files": false,
  "save_workspace": "never",
  "load_workspace": false,
  "scroll_past_end": true,
  "show_margin": true,
  "margin_column": 120,
  "enable_code_completion": true,
  "show_hidden_files": false
}
PREFS
chown -R cdsw:cdsw /home/cdsw/.config
