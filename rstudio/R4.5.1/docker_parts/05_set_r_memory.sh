#!/bin/bash

# Dynamically set R_MAX_VSIZE based on available container memory
if [ -f /sys/fs/cgroup/memory/memory.limit_in_bytes ]; then
    CONTAINER_MEM=$(($(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)/1024/1024))
    R_MEM=$((${CONTAINER_MEM}*80/100))
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

    echo "[$TIMESTAMP] [R_PROFILE] Setting R_MAX_VSIZE=${R_MEM}M based on container memory limit" | tee -a /var/log/r_profile_memory.log >&2

    if ! grep -q "R_MAX_VSIZE=" /usr/local/lib/R/etc/Renviron.site; then
        echo "R_MAX_VSIZE=${R_MEM}M" >> /usr/local/lib/R/etc/Renviron.site
    fi
fi

# Rotate the log if it exceeds 1MB
if [ -f /var/log/r_profile_memory.log ] && [ $(stat -c%s /var/log/r_profile_memory.log) -ge 1048576 ]; then
    mv /var/log/r_profile_memory.log /var/log/r_profile_memory.log.old
fi
