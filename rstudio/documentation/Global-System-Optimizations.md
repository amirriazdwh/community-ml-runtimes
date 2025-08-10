# Global System Optimizations - RStudio Server

## Overview
All optimizations now apply **globally to ALL users** without requiring individual user configuration.

## 1. Global File Descriptor Limits

**File:** `/etc/security/limits.conf`

```conf
# Global resource limits for all users
# These apply automatically to ALL users without individual entries

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
```

**Benefits:**
- ✅ Applies to ALL existing and future users automatically
- ✅ No need to add individual user entries
- ✅ Scalable for any number of users

## 2. Systemd Global Limits

**File:** `/etc/systemd/user.conf.d/limits.conf`
```conf
[Manager]
# Global limits for all user services
DefaultLimitNOFILE=65535
DefaultLimitNPROC=32768
DefaultLimitCORE=0
DefaultLimitMEMLOCK=infinity
```

**File:** `/etc/systemd/system.conf.d/limits.conf`
```conf
[Manager]
# Global limits for all system services
DefaultLimitNOFILE=65535
DefaultLimitNPROC=32768
DefaultLimitCORE=0
DefaultLimitMEMLOCK=infinity
```

## 3. PAM Configuration

**Files:** `/etc/pam.d/common-session*`
```
session required pam_limits.so
```

**Purpose:** Ensures limits.conf is enforced for all login sessions.

## 4. RStudio Server Global Configuration

**File:** `/etc/rstudio/rserver.conf`

```conf
# === Global Performance Optimizations ===

# Session management (applies to ALL users)
session-timeout-minutes=0
session-disconnect-on-suspend=0
session-quit-child-processes-on-exit=1

# Resource limits (global - no per-user limits needed)
session-memory-limit-mb=0
session-cpu-limit-percent=0

# Security and performance
server-app-armor-enabled=0
server-set-umask=0

# Logging optimizations
monitor-log-level=warn
```

## 5. Global R Configuration

**File:** `/etc/R/Rprofile.site`

```r
# Global R configuration for ALL users
# This applies automatically to every R session

# CRAN repository
options(
  repos = c(CRAN = 'https://cloud.r-project.org/'),
  download.file.method = 'libcurl',
  timeout = 300
)

# Performance settings - use all available cores
options(
  warn = 1,
  mc.cores = parallel::detectCores(),
  Ncpus = parallel::detectCores()
)
```

## 6. Kernel-Level Optimizations

**File:** `/etc/sysctl.conf`

```conf
# === RStudio Server Global Optimizations ===

# File system optimizations (global for all users)
fs.file-max = 2097152
fs.nr_open = 2097152
fs.inotify.max_user_watches = 524288

# Memory management optimizations
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5

# Process and threading limits
kernel.pid_max = 4194304
kernel.threads-max = 4194304
```

> **Note:** These require host-level application (Docker limitations prevent container-level sysctl changes)

## Verification Commands

```bash
# Check global limits for any user
docker exec -u [username] rstudio-server bash -c "ulimit -n; ulimit -u"

# Verify PAM configuration
docker exec rstudio-server grep pam_limits /etc/pam.d/common-session*

# Check R global configuration
docker exec -u [username] rstudio-server R --slave -e "getOption('mc.cores')"

# Verify systemd limits
docker exec rstudio-server cat /etc/systemd/user.conf.d/limits.conf
```

## Key Benefits

### ✅ Scalability
- **No per-user configuration needed**
- Automatically applies to new users
- Single point of configuration management

### ✅ Maintenance
- All settings in standard system configuration files
- Easy to update globally
- Version control friendly

### ✅ Performance
- Optimal file descriptor limits for all users
- Global R performance settings
- Efficient resource utilization

### ✅ Consistency
- Same optimizations for all users
- Uniform experience across the system
- Predictable behavior

## Implementation Status

| Component | Status | File Location |
|-----------|--------|---------------|
| Global File Limits | ✅ Applied | `/etc/security/limits.conf` |
| Systemd Limits | ✅ Applied | `/etc/systemd/*/limits.conf` |
| PAM Integration | ✅ Applied | `/etc/pam.d/common-session*` |
| RStudio Config | ✅ Applied | `/etc/rstudio/rserver.conf` |
| Global R Config | ✅ Applied | `/etc/R/Rprofile.site` |
| Kernel Limits | ⚠️ Ready | `/etc/sysctl.conf` (host-level) |

## Next Steps

1. **Test with any user** - All optimizations are global
2. **Add new users** - They automatically inherit all optimizations  
3. **Apply kernel settings** - At Docker host level for maximum effect
4. **Monitor performance** - All users benefit from the same optimizations

---

**Result:** The system now has **global optimizations** that apply to **ALL users automatically** without individual configuration!
