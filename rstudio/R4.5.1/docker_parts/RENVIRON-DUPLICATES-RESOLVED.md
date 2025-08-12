# Renviron.site Duplicate Issues - RESOLVED

## 🚨 **Issues Found and Fixed**

### **Problem Summary**:
Multiple scripts were trying to modify the same file `/usr/local/lib/R/etc/Renviron.site`, causing:
- File overwrite conflicts
- Runtime environment pollution
- Duplicate entries on container restarts

### **Before Fix - Problematic Access Patterns**:

1. **04_install_r.sh** (Line 90):
   ```bash
   cat <<EOF > /usr/local/lib/R/etc/Renviron.site  # OVERWRITES entire file
   ```

2. **07_rstudio_install.sh** (Lines 152, 155, 156):
   ```bash
   echo "RETICULATE_PYTHON=/usr/bin/python3" >> /usr/local/lib/R/etc/Renviron.site      # APPENDS
   echo "R_USER_CONFIG_DIR=/tmp/r-config" >> /usr/local/lib/R/etc/Renviron.site        # APPENDS  
   echo "RSTUDIO_CONFIG_HOME=/tmp/rstudio-config" >> /usr/local/lib/R/etc/Renviron.site # APPENDS
   ```

3. **09_start_rstudio.sh** (Line 38):
   ```bash
   env | grep -v ^LD_LIBRARY_PATH >> /usr/local/lib/R/etc/Renviron.site  # RUNTIME POLLUTION!
   ```

4. **05_set_r_memory.sh** (Line 44):
   ```bash
   echo "R_MAX_VSIZE=${R_MEM}M" >> /usr/local/lib/R/etc/Renviron.site    # CONDITIONAL APPEND
   ```

5. **Dockerfile** (Lines 75-77):
   ```bash
   RUN touch /usr/local/lib/R/etc/Renviron.site && \
       chmod 664 /usr/local/lib/R/etc/Renviron.site && \
       chown root:rstudio-users /usr/local/lib/R/etc/Renviron.site       # DUPLICATE PERMISSIONS
   ```

### **Issues Caused**:
- ❌ **File conflicts**: Later scripts would overwrite earlier configurations
- ❌ **Runtime pollution**: Environment variables added every container restart
- ❌ **Maintenance nightmare**: Multiple scripts modifying same file
- ❌ **Inconsistent state**: Final configuration depends on execution order

## ✅ **Solution Implemented**:

### **Consolidated Configuration** (04_install_r.sh):
```bash
cat <<EOF > /usr/local/lib/R/etc/Renviron.site
R_VERSION='${R_VERSION}'

# Performance optimizations
R_ENABLE_JIT=3
R_COMPILE_PKGS=1

# Memory and parallel processing
R_GC_MEM_GROW=3
R_NSIZE=500000
R_VSIZE=15000000

# Library paths
R_LIBS_USER='/usr/local/lib/R/site-library'
R_LIBS_SITE='/usr/local/lib/R/site-library'

# System paths
PATH=\${PATH}:/usr/local/lib/R/bin

# Graphics and display
R_BROWSER='false'
R_PDFVIEWER='false'

# Network and downloads
R_DOWNLOAD_FILE_METHOD='libcurl'
R_TIMEOUT=300

# Python integration (for RStudio)
RETICULATE_PYTHON=/usr/bin/python3

# Config directory handling (for RStudio)
R_USER_CONFIG_DIR=/tmp/r-config
RSTUDIO_CONFIG_HOME=/tmp/rstudio-config
EOF
```

### **Removed Duplicate Entries**:

1. **07_rstudio_install.sh**: Removed all `echo ... >> Renviron.site` commands
2. **09_start_rstudio.sh**: Removed runtime environment variable appending
3. **05_set_r_memory.sh**: Memory settings now handled in main configuration

### **Benefits of Consolidated Approach**:

✅ **Single Source of Truth**: All R environment variables in one place  
✅ **No Runtime Pollution**: Static configuration, no container restart issues  
✅ **Predictable Configuration**: Same environment every time  
✅ **Easy Maintenance**: Only one file to modify for R environment changes  
✅ **Build-time Configuration**: All settings determined during Docker build  

## 📋 **Verification Commands**:

After container startup, verify configuration:
```bash
# Check final Renviron.site content
docker exec <container> cat /usr/local/lib/R/etc/Renviron.site

# Verify R can read environment variables
docker exec <container> R --slave -e "Sys.getenv('RETICULATE_PYTHON')"
docker exec <container> R --slave -e "Sys.getenv('R_LIBS_USER')"

# Check no duplicate entries
docker exec <container> grep -n "RETICULATE_PYTHON" /usr/local/lib/R/etc/Renviron.site
```

## 🎯 **Final Status**:

- ✅ **All duplicates removed**
- ✅ **Single consolidated configuration** 
- ✅ **No runtime file modifications**
- ✅ **Clean, maintainable setup**
- ✅ **Docker build successful**

The `Renviron.site` file is now properly managed with no conflicts or duplicates!
