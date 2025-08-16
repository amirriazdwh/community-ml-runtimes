#!/bin/bash
set -e

echo "[INFO] Starting RStudio Server for multi-user environment..."

# Ensure secure-cookie-key exists
if [ ! -f /etc/rstudio/secure-cookie-key ]; then
  echo "[INFO] Creating missing secure-cookie-key..."
  mkdir -p /etc/rstudio
  head -c 512 /dev/urandom > /etc/rstudio/secure-cookie-key
  chmod 0600 /etc/rstudio/secure-cookie-key
  chown root:root /etc/rstudio/secure-cookie-key
fi

# Ensure shared storage directory exists
mkdir -p /var/lib/rstudio-server/shared-storage
chmod 1777 /var/lib/rstudio-server/shared-storage

# Fix runtime permission issues for config directories
echo "[INFO] Fixing config directory permissions..."
mkdir -p /root/.config 2>/dev/null || true
chmod 755 /root/.config 2>/dev/null || true

# Ensure rstudio-server user has proper config directory
mkdir -p /home/rstudio-server/.config 2>/dev/null || true
chown rstudio-server:rstudio-server /home/rstudio-server/.config 2>/dev/null || true
chmod 755 /home/rstudio-server/.config 2>/dev/null || true

# Create a symlink to redirect root config to a writable location if needed
if [ ! -w /root/.config ]; then
    echo "[INFO] Creating fallback config directory..."
    mkdir -p /tmp/rstudio-config
    chmod 777 /tmp/rstudio-config
    ln -sf /tmp/rstudio-config /root/.config-fallback
fi

# Do NOT append the container environment into Renviron.site.
# This can override HOME and other critical vars for user sessions (e.g., forcing HOME=/root in R),
# leading to permission warnings like attempts to create /root/.config. We rely on the build-time
# Renviron.site (generated from the template) and per-session environment provided by RStudio.

# Start RStudio Server in multi-user mode
echo "[INFO] Starting RStudio Server..."
exec /usr/lib/rstudio-server/bin/rserver \
  --server-daemonize=0 \
  --www-address=0.0.0.0 \
  --www-port=8787 \
  --secure-cookie-key-file=/etc/rstudio/secure-cookie-key
