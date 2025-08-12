# R Profile Modular Configuration Solution

## Problem Identified
Multiple Docker scripts were writing to `/usr/local/lib/R/etc/Rprofile.site`, causing conflicts and overwrites:

1. **04_install_r.sh** (line 84): `cat <<EOF > /usr/local/lib/R/etc/Rprofile.site`
2. **07_rstudio_install.sh** (line 73): `echo "options(bitmapType='cairo')" >> /usr/local/lib/R/etc/Rprofile.site`
3. **07_rstudio_install.sh** (line 163): `cat > /usr/local/lib/R/etc/Rprofile.site << 'RPROFILE'`

## Solution Implemented
Created a **modular R profile system** with separate configuration files:

### Main Files Created:
1. **`Rprofile.site.base`** - Base R configuration (CRAN, performance, memory)
2. **`rstudio-config.R`** - RStudio Server specific settings (cairo, graphics)
3. **`config-handling.R`** - Config directory handling logic

### Directory Structure:
```
/usr/local/lib/R/etc/
├── Rprofile.site              # Main file (loads modular configs)
├── Renviron.site              # Environment variables
└── profiles.d/                # Modular configuration directory
    ├── rstudio-config.R       # RStudio-specific settings
    └── config-handling.R      # Config directory handling
```

### How It Works:
1. **Base Rprofile.site** contains core R settings and a loader for modular configs
2. **profiles.d/** directory contains specific configuration modules
3. Each script copies its configuration to the modular directory instead of overwriting the main file
4. Variable substitution using `envsubst` for dynamic values like `${CRAN}`

### Benefits:
- ✅ **No more conflicts** - Each script manages its own config file
- ✅ **Maintainable** - Easy to see what each script contributes
- ✅ **Extensible** - New scripts can add configs without conflicts
- ✅ **Debuggable** - Clear separation of concerns
- ✅ **Order-independent** - Scripts can run in any order

### Files Modified:
- **04_install_r.sh**: Now uses `envsubst` to copy base configuration
- **07_rstudio_install.sh**: Copies modular configs instead of overwriting main file

This ensures the R profile configuration is built properly without conflicts!
