#!/bin/bash
set -e

echo "🎬 [Xvfb] Starting virtual framebuffer..."

# Ensure proper X11 temp perms
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix
chown root:root /tmp/.X11-unix

# Kill any existing
[ -f /tmp/.X99-lock ] && rm -f /tmp/.X99-lock

# Start Xvfb on display :99 in background
nohup Xvfb :99 -screen 0 1024x768x24 > /var/log/xvfb.log 2>&1 &

# Register environment variable
echo "DISPLAY=:99" >> /etc/environment
echo "✅ [Xvfb] DISPLAY=:99 ready"
