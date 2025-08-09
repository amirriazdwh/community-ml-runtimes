#!/bin/bash
set -e

RSTUDIO_VERSION=2025.05.1-513
# Download and install RStudio Server
echo "📦 Downloading and installing RStudio Server version: $RSTUDIO_VERSION"
wget https://download2.rstudio.org/server/jammy/amd64/rstudio-server-${RSTUDIO_VERSION}-amd64.deb -O /tmp/rstudio.deb
gdebi -n /tmp/rstudio.deb
rm /tmp/rstudio.deb

# Verify RStudio Server installation
if ! systemctl status rstudio-server &>/dev/null; then
    echo "⚠️ RStudio Server installation may have issues"
fi

# Setup runtime directories with proper multi-user permissions
mkdir -p /etc/rstudio /var/lib/rstudio-server
chmod 775 /var/lib/rstudio-server
chown -R root:rstudio-users /var/lib/rstudio-server

# Create secure cookie key with proper multi-user permissions
echo "🔑 Creating secure-cookie-key..."
head -c 512 /dev/urandom > /etc/rstudio/secure-cookie-key
chmod 0600 /etc/rstudio/secure-cookie-key
chown root:rstudio-users /etc/rstudio/secure-cookie-key

# Increase file descriptor limits for all users
cat <<EOF >> /etc/security/limits.conf
cdsw soft nofile 65535
cdsw hard nofile 65535
dev1 soft nofile 65535
dev1 hard nofile 65535
dev2 soft nofile 65535
dev2 hard nofile 65535
* soft nofile 65535
* hard nofile 65535
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
echo "📦 Installing R packages for reporting and PDF generation..."
Rscript -e "install.packages(c( \
  'rmarkdown', 'knitr', 'bookdown', 'flexdashboard', 'officer', 'flextable', \
  'kableExtra', 'pagedown', 'gt', 'rmdformats', 'webshot', \
  'xml2', 'rsvg', 'patchwork'), repos=Sys.getenv('CRAN'), quiet=TRUE)" || {
    echo "⚠️ Some R packages failed to install, continuing..."
}
Rscript -e "webshot::install_phantomjs()" || echo "⚠️ PhantomJS installation failed"
# Note: Using system LaTeX instead of tinytex to avoid conflicts

# Set bitmapType to 'cairo' for all R sessions
echo "options(bitmapType='cairo')" >> /usr/local/lib/R/etc/Rprofile.site

# ===============================
# === Create RStudio User Preferences (JSON Format for 2025.x) ===
# ===============================
echo "� Creating global RStudio preferences for all users..."

# Create system-wide RStudio configuration directory
mkdir -p /etc/rstudio

# Create global preference defaults that apply to all users
cat <<GLOBAL_PREFS > /etc/rstudio/rstudio-prefs.json
{
  "font_size_points": 9,
  "font": "Fira Code",
  "global_theme": "Modern",
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
  "show_hidden_files": false,
  "always_save_history": false,
  "reuse_sessions_for_project_links": true,
  "enable_code_indexing": true
}
GLOBAL_PREFS

# Create user settings template for legacy format compatibility
cat <<USER_SETTINGS > /etc/rstudio/user-settings
alwaysSaveHistory=0
loadRData=0
saveAction=0
showLineNumbers=1
highlightSelectedLine=1
softWrapRFiles=0
showMargin=1
marginColumn=120
enableCodeIndexing=1
showHiddenFiles=0
fontSize=9
font=Fira Code
theme=Tomorrow Night Bright
uiTheme=Modern
globalTheme=Modern
enableCodeCompletion=1
scrollPastEnd=1
USER_SETTINGS

# Create a system-wide profile script that sets user preferences on login
cat <<PROFILE > /etc/profile.d/rstudio-defaults.sh
#!/bin/bash
# Set up RStudio user preferences on first login
# Only run for regular users (UID >= 1000) and skip root
if [ "\$USER" != "root" ] && [ "\$(id -u)" -ge 1000 ] && [ -w "\$HOME" ] && [ ! -f "\$HOME/.rstudio-prefs-set" ]; then
    mkdir -p "\$HOME/.config/rstudio" 2>/dev/null || true
    if [ -f "/etc/rstudio/rstudio-prefs.json" ]; then
        cp /etc/rstudio/rstudio-prefs.json "\$HOME/.config/rstudio/" 2>/dev/null || true
        chown "\$USER:\$USER" "\$HOME/.config/rstudio/rstudio-prefs.json" 2>/dev/null || true
    fi
    touch "\$HOME/.rstudio-prefs-set" 2>/dev/null || true
fi
PROFILE
chmod +x /etc/profile.d/rstudio-defaults.sh

echo "✅ Global RStudio preferences configured for all users"

# Cleanup cache and temp files (but preserve user homes during installation)
rm -rf /tmp/* /var/tmp/* /root/.cache /var/lib/apt/lists/*
