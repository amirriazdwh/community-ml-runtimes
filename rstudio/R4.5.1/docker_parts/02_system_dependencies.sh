#!/bin/bash
set -e

echo "🛠 Installing core system dependencies..."

###############################################################################
# 🧰 SYSTEM DEPENDENCIES
###############################################################################

# 📦 Stage 1: Base system utilities and shell tools
apt-get update && apt-get install -y --no-install-recommends \
    tzdata locales sudo \
    wget ca-certificates gdebi-core \
    psmisc procps file git less nano \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 🔧 Stage 2: Compilers and build tools (needed for compiling R packages)
apt-get update && apt-get install -y --no-install-recommends \
    build-essential gfortran \
    libssl-dev libcurl4-openssl-dev libxml2-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 🔐 Stage 6: Optional enterprise and metadata tools (e.g., Kerberos, Hadoop)
apt-get update && apt-get install -y --no-install-recommends \
    libsasl2-modules-gssapi-mit krb5-user \
    libclang-dev lsb-release \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

###############################################################################
# 🌐 TIMEZONE AND LOCALE CONFIGURATION
###############################################################################

# Use UTC as fallback if TZ not provided
: "${TZ:=Etc/UTC}"
ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata

# Enable en_US.UTF-8 locale if not already present
grep -qxF "en_US.UTF-8 UTF-8" /etc/locale.gen || echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8


###############################################################################
# ⚡ GLOBAL SYSTEM OPTIMIZATIONS (applies to ALL users automatically)
###############################################################################

echo "⚡ Applying global system optimizations..."

# Global file descriptor and process limits (applies to ALL users)
cat > /etc/security/limits.conf << 'EOF'
# /etc/security/limits.conf
#
# Global resource limits for all users
# These apply automatically to ALL users without individual entries
#
# Format: <domain> <type> <item> <value>

# Global file descriptor limits (applies to ALL users)
* soft nofile 65535
* hard nofile 65535

# Global process limits (applies to ALL users)  
* soft nproc 32768
* hard nproc 32768

# Global memory limits
* soft memlock unlimited
* hard memlock unlimited

# Global core dump settings
* soft core 0
* hard core unlimited

# End of file
EOF

# Create systemd global limits (applies to all services)
mkdir -p /etc/systemd/user.conf.d
cat > /etc/systemd/user.conf.d/limits.conf << 'EOF'
[Manager]
# Global limits for all user services
DefaultLimitNOFILE=65535
DefaultLimitNPROC=32768
DefaultLimitCORE=0
DefaultLimitMEMLOCK=infinity
EOF

mkdir -p /etc/systemd/system.conf.d
cat > /etc/systemd/system.conf.d/limits.conf << 'EOF'
[Manager]
# Global limits for all system services
DefaultLimitNOFILE=65535
DefaultLimitNPROC=32768
DefaultLimitCORE=0
DefaultLimitMEMLOCK=infinity
EOF

# Ensure PAM limits module is enabled (makes limits.conf effective)
if ! grep -q 'pam_limits.so' /etc/pam.d/common-session; then
    echo 'session required pam_limits.so' >> /etc/pam.d/common-session
fi

if ! grep -q 'pam_limits.so' /etc/pam.d/common-session-noninteractive; then
    echo 'session required pam_limits.so' >> /etc/pam.d/common-session-noninteractive
fi

# Add kernel-level optimizations to sysctl.conf (for host-level application)
cat >> /etc/sysctl.conf << 'EOF'

# === RStudio Server Global Optimizations ===

# File system optimizations (global for all users)
fs.file-max = 2097152
fs.nr_open = 2097152
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512

# Network optimizations
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_keepalive_time = 600

# Memory management optimizations
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.vfs_cache_pressure = 50
vm.max_map_count = 262144

# Process and threading limits
kernel.pid_max = 4194304
kernel.threads-max = 4194304
EOF

echo "✅ Global system optimizations applied (affects ALL users automatically)"

# Clean up
apt-get clean
rm -rf /var/lib/apt/lists/*

