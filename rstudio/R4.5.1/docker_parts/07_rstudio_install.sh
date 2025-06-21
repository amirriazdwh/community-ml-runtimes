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

# Advanced R Features
# X11 and Cairo Support for Advanced Plotting (R devices like X11, Cairo, etc.)
apt-get update && \
    apt-get install -y --no-install-recommends \
        xorg libx11-dev libxt-dev libxext-dev libxrender-dev \
        libcairo2-dev libjpeg-dev libtiff5-dev libgif-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Cairo R package
Rscript -e "if (!require('Cairo')) install.packages('Cairo', repos='${CRAN}')"

# Optional: Install additional graphics-related packages
Rscript -e "install.packages(c('ggplot2', 'gridExtra', 'gridBase'), repos='${CRAN}')"
Rscript -e "install.packages(c('svglite', 'tikzDevice'), repos='${CRAN}')"

# Ensure Cairo fallback
echo '' >> /usr/local/lib/R/etc/Rprofile.site
echo 'options(bitmapType="cairo")' >> /usr/local/lib/R/etc/Rprofile.site

# R Reporting & PDF Tools
Rscript -e "install.packages(c( \
  'rmarkdown', 'knitr', 'bookdown', 'flexdashboard', 'officer', 'flextable', \
  'tinytex', 'kableExtra', 'pagedown', 'gt', 'rmdformats', 'webshot', \
  'xml2', 'rsvg', 'ggplot2', 'patchwork'), repos='${CRAN}')"
Rscript -e "webshot::install_phantomjs()"
Rscript -e "tinytex::install_tinytex()"

# Cleanup cache and temp files
rm -rf /tmp/* /var/tmp/* /root/.cache /home/cdsw/.cache /var/lib/apt/lists/*

# Pre-configure GUI for cdsw user
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
