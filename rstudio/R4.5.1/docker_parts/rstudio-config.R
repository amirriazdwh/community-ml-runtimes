# RStudio Server specific configurations
# This file is loaded by Rprofile.site via the profiles.d mechanism
# It contains RStudio-specific settings that should be separated from general R settings

# Set bitmapType to 'cairo' for all R sessions (for graphics)
options(bitmapType = 'cairo')

# RStudio Server specific settings
options(
  # Better graphics device for server environment
  device = function(...) {
    if (capabilities("cairo")) {
      grDevices::png(..., type = "cairo")
    } else {
      grDevices::png(...)
    }
  }
)

# RStudio IDE enhancements
if (exists(".rs.api.versionInfo")) {
  options(
    # Better completion
    help_type = "html",
    # Improved error handling in RStudio
    error = function() {
      if (interactive()) {
        traceback(2)
      }
    }
  )
}
