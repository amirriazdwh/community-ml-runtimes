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

# Export environment variables for all users
env | grep -v ^LD_LIBRARY_PATH >> /usr/local/lib/R/etc/Renviron.site

# Start RStudio Server in multi-user mode
echo "[INFO] Starting RStudio Server..."
exec /usr/lib/rstudio-server/bin/rserver \
  --server-daemonize=0 \
  --www-address=0.0.0.0 \
  --www-port=8787 \
  --secure-cookie-key-file=/etc/rstudio/secure-cookie-key
