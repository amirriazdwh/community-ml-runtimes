# Red Hat Compatible Solutions for Docker Container Build

## Problem Statement
The original implementation used `envsubst` from the `gettext-base` package. For Red Hat host environments, we need to ensure packages are installed within the Ubuntu Docker container, not on the host system.

## ✅ Solution 1: Install envsubst in Ubuntu Container (IMPLEMENTED)

**Status**: ✅ **ACTIVE** - Currently implemented in `04_install_r.sh`

Install `gettext-base` package within the Ubuntu Docker container - this doesn't affect the Red Hat host system.

```bash
# In 04_install_r.sh - installs within Ubuntu container
apt-get update && apt-get install -y --no-install-recommends \
    libcairo2-dev libjpeg-dev libtiff5-dev libpng-dev \
    libfontconfig1-dev libfreetype6-dev librsvg2-dev \
    libharfbuzz-dev libfribidi-dev gettext-base \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Use envsubst normally
envsubst < /tmp/docker_parts/Rprofile.site.base > /usr/local/lib/R/etc/Rprofile.site
```

**Advantages**:
- ✅ Simple and straightforward
- ✅ No impact on Red Hat host system  
- ✅ Full envsubst functionality
- ✅ Easy to maintain and debug
- ✅ Standard Ubuntu package management

**Key Point**: The `gettext-base` package is installed **inside the Ubuntu Docker container**, not on the Red Hat host. This is completely isolated and safe.

---

## 🔄 Solution 2: Pure Bash Variable Substitution (Alternative)

If you prefer zero external dependencies, use native bash:

```bash
# Replace envsubst with pure bash
sed "s|\${CRAN}|${CRAN:-https://cloud.r-project.org/}|g; s|\${R_LIBS_USER}|${R_LIBS_USER:-/usr/local/lib/R/site-library}|g" \
    /tmp/docker_parts/Rprofile.site.base > /usr/local/lib/R/etc/Rprofile.site
```

**Advantages**:
- Zero external dependencies
- Works in any POSIX shell
- Includes fallback defaults
- Most performant solution

---

## 🐍 Solution 3: Python Template Substitution (Alternative)

Use Python's built-in `string.Template` for complex substitutions:

```bash
# Create substitution script
cat > /tmp/substitute_vars.py << 'EOF'
#!/usr/bin/env python3
import os
import sys
from string import Template

# Read template file
with open(sys.argv[1], 'r') as f:
    template_content = f.read()

# Substitute environment variables
template = Template(template_content)
result = template.safe_substitute(os.environ)

# Write to output file
with open(sys.argv[2], 'w') as f:
    f.write(result)
EOF

chmod +x /tmp/substitute_vars.py

# Use it in 04_install_r.sh
python3 /tmp/substitute_vars.py /tmp/docker_parts/Rprofile.site.base /usr/local/lib/R/etc/Rprofile.site
```

**Advantages**:
- Uses Python already in container
- More robust than bash for complex templates
- Handles missing variables gracefully

---

## 📋 Current Implementation Status

### ✅ Completed Changes:
1. **04_install_r.sh**: Added `gettext-base` package installation within Ubuntu container
2. **04_install_r.sh**: Uses `envsubst` for clean variable substitution
3. **Dockerfile**: Already has proper COPY commands for template files

### 🔍 Variables Currently Substituted:
- `${CRAN}` → Environment variable (e.g., `https://cloud.r-project.org/`)
- `${R_LIBS_USER}` → Environment variable (e.g., `/usr/local/lib/R/site-library`)

### 🧪 Testing the Solution:
```bash
# Test envsubst functionality in container
docker run --rm -e CRAN="https://cran.rstudio.com" ubuntu:22.04 bash -c \
  "apt-get update && apt-get install -y gettext-base && echo 'CRAN: \${CRAN}' | envsubst"

# Expected output: CRAN: https://cran.rstudio.com
```

---

## 🚀 Red Hat Deployment Benefits

1. **No Host Dependencies**: Container is completely self-contained
2. **Portable**: Works across different Linux distributions
3. **Secure**: No additional attack surface from external packages
4. **Maintainable**: Uses standard POSIX tools available everywhere
5. **Fast**: No network downloads or package installations during build

---

## 🔧 Migration Guide

If you need to revert or modify:

### To add more variables:
```bash
# Extend the sed command in 04_install_r.sh
sed "s|\${CRAN}|${CRAN:-https://cloud.r-project.org/}|g; \
     s|\${R_LIBS_USER}|${R_LIBS_USER:-/usr/local/lib/R/site-library}|g; \
     s|\${NEW_VAR}|${NEW_VAR:-default_value}|g" \
    /tmp/docker_parts/Rprofile.site.base > /usr/local/lib/R/etc/Rprofile.site
```

### To switch to alternative solution:
1. Uncomment desired alternative in this document
2. Update `04_install_r.sh` accordingly
3. Test with your specific Red Hat environment

---

## ✅ Verification Commands

After container build:
```bash
# Check that Rprofile.site was created correctly
docker run --rm your-image cat /usr/local/lib/R/etc/Rprofile.site

# Verify CRAN setting in R
docker run --rm your-image R --slave -e "getOption('repos')"

# Test R startup
docker run --rm your-image R --version
```
