#!/bin/bash
set -e

# RSTUDIO_VERSION=2024.12.1-506
# # Download and install RStudio Server
# echo "📦 Downloading and installing RStudio Server version: $RSTUDIO_VERSION"
# wget https://download2.rstudio.org/server/jammy/amd64/rstudio-server-${RSTUDIO_VERSION}-amd64.deb -O /tmp/rstudio.deb
# gdebi -n /tmp/rstudio.deb
# rm /tmp/rstudio.deb

RSTUDIO_URL=https://s3.amazonaws.com/rstudio-ide-build/server/jammy/amd64/rstudio-server-2025.05.0-496-amd64.deb
echo "📦 Installing RStudio Server 2025.05.0+496" 
wget $RSTUDIO_URL -O /tmp/rstudio.deb
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

# ===========================================
# === LaTeX Toolchain for tikzDevice + PDF ==
# ===========================================
echo "📦 Installing LaTeX stack for tikzDevice..."
apt-get update && \
    apt-get install -y --no-install-recommends \
        texlive texlive-latex-base texlive-latex-extra libgif-dev \
        texlive-fonts-recommended texlive-pictures texinfo ghostscript && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ================================
# === R Reporting & PDF Tools ===
# ================================
Rscript -e "install.packages(c( \
  'rmarkdown', 'knitr', 'bookdown', 'flexdashboard', 'officer', 'flextable', \
  'tinytex', 'kableExtra', 'pagedown', 'gt', 'rmdformats', 'webshot', \
  'xml2', 'rsvg', 'patchwork'), repos=Sys.getenv('CRAN'), quiet=TRUE)"
Rscript -e "webshot::install_phantomjs()"
Rscript -e "tinytex::install_tinytex(force = TRUE)"

# Set bitmapType to 'cairo'
echo "options(bitmapType='cairo')" >> /usr/local/lib/R/etc/Rprofile.site
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
