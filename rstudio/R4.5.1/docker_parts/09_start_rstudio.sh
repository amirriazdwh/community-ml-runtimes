#!/bin/bash
set -euo pipefail

# Fixed environment for Cloudera CML sessions
export USER=cdsw
export HOME=/home/cdsw
export PATH=$PATH:/usr/lib/rstudio-server/bin

# Ensure home directory exists
mkdir -p "$HOME"
chown -R "$USER:$USER" "$HOME"

# Create shared tmp session directory with secure permissions
mkdir -p /tmp/rstudio/sessions/active
chmod 1777 /tmp/rstudio/sessions/active

# Create user session dir and symlink to shared sessions
mkdir -p "${HOME}/.rstudio/sessions"
if [ -L "${HOME}/.rstudio/sessions/active" ]; then
    rm -f "${HOME}/.rstudio/sessions/active"
elif [ -d "${HOME}/.rstudio/sessions/active" ]; then
    rm -rf "${HOME}/.rstudio/sessions/active"
fi
ln -s /tmp/rstudio/sessions/active "${HOME}/.rstudio/sessions/active"

# Ensure secure-cookie-key exists
if [ ! -f /etc/rstudio/secure-cookie-key ]; then
  echo "[INFO] Creating missing secure-cookie-key..."
  mkdir -p /etc/rstudio
  head -c 512 /dev/urandom > /etc/rstudio/secure-cookie-key
  chmod 0600 /etc/rstudio/secure-cookie-key
  chown "$USER:$USER" /etc/rstudio/secure-cookie-key
fi

# Export env (except problematic ones) into R
if [ -w /usr/local/lib/R/etc/Renviron.site ]; then
  env | grep -v ^LD_LIBRARY_PATH >> /usr/local/lib/R/etc/Renviron.site
else
  echo "[WARN] Skipping env export: /usr/local/lib/R/etc/Renviron.site not writable"
fi

# Start RStudio Server in foreground with retry fallback
echo "[INFO] Launching RStudio Server as $USER..."
exec /usr/lib/rstudio-server/bin/rserver \
  --server-daemonize=0 \
  --auth-none=1 \
  --server-user="$USER" \
  --www-address=0.0.0.0 \
  --www-port=8787 \
  --secure-cookie-key-file=/etc/rstudio/secure-cookie-key || {
    echo "[ERROR] RStudio Server failed to start. Retrying in 5s..." >&2
    sleep 5
    exec /usr/lib/rstudio-server/bin/rserver \
      --server-daemonize=0 \
      --auth-none=1 \
      --server-user="$USER" \
      --www-address=0.0.0.0 \
      --www-port=8787 \
      --secure-cookie-key-file=/etc/rstudio/secure-cookie-key
  }
