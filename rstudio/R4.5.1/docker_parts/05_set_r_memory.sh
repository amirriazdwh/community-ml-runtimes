#!/bin/bash

# Try cgroup v1
if [ -f /sys/fs/cgroup/memory/memory.limit_in_bytes ]; then
    CONTAINER_MEM=$(($(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)/1024/1024))

# Try cgroup v2
elif [ -f /sys/fs/cgroup/memory.max ]; then
    MEM_RAW=$(cat /sys/fs/cgroup/memory.max)
    if [ "$MEM_RAW" != "max" ]; then
        CONTAINER_MEM=$(($MEM_RAW/1024/1024))
    fi
fi

# Fallback: use host system memory
if [ -z "$CONTAINER_MEM" ] && command -v free &> /dev/null; then
    CONTAINER_MEM=$(free -m | awk '/^Mem:/ { print $2 }')
fi

if [ -z "$CONTAINER_MEM" ]; then
    R_MEM=8192  # Default to 8GB
else
    R_MEM=$(($CONTAINER_MEM * 80 / 100))
fi

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

echo "[$TIMESTAMP] [R_PROFILE] Setting R_MAX_VSIZE=${R_MEM}M based on memory" | tee -a /var/log/r_profile_memory.log >&2

if ! grep -q "R_MAX_VSIZE=" /usr/local/lib/R/etc/Renviron.site; then
    echo "R_MAX_VSIZE=${R_MEM}M" >> /usr/local/lib/R/etc/Renviron.site
fi

echo ""
echo "🔧 [INFO] R_MAX_VSIZE has been set to ${R_MEM}M (80% of available memory)"
echo ""

# Rotate log if over 1MB
if [ -f /var/log/r_profile_memory.log ] && [ $(stat -c%s /var/log/r_profile_memory.log) -ge 1048576 ]; then
    mv /var/log/r_profile_memory.log /var/log/r_profile_memory.log.old
fi
