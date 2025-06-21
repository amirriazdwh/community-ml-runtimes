#!/bin/bash
set -e

echo "📦 Downloading and installing RStudio Server version: $RSTUDIO_VERSION"

wget https://download2.rstudio.org/server/jammy/amd64/rstudio-server-${RSTUDIO_VERSION}-amd64.deb -O /tmp/rstudio.deb
gdebi -n /tmp/rstudio.deb
rm /tmp/rstudio.deb

mkdir -p /etc/rstudio /var/lib/rstudio-server
chmod 1777 /var/lib/rstudio-server
chown -R cdsw:cdsw /var/lib/rstudio-server

# Create secure-cookie key
echo "🔑 Creating secure-cookie-key..."
mkdir -p /etc/rstudio
head -c 512 /dev/urandom > /etc/rstudio/secure-cookie-key
chmod 0600 /etc/rstudio/secure-cookie-key
chown cdsw:cdsw /etc/rstudio/secure-cookie-key
