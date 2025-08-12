# Config directory and startup handling
# This file handles the config directory issues mentioned in 07_rstudio_install.sh

# Global R profile to handle config directory issues
local({
  # Function to safely create config directory
  safe_config_dir <- function() {
    tryCatch({
      # Try user's home first
      user_config <- file.path(Sys.getenv("HOME"), ".config")
      if (!dir.exists(user_config)) {
        dir.create(user_config, recursive = TRUE, mode = "0755")
        return(user_config)
      }
      
      # If home config exists, check if writable
      if (file.access(user_config, mode = 2) == 0) {
        return(user_config)
      }
      
      # Fall back to /tmp if user config not writable
      temp_config <- file.path("/tmp", paste0("r-config-", Sys.getenv("USER", "default")))
      if (!dir.exists(temp_config)) {
        dir.create(temp_config, recursive = TRUE, mode = "0755")
      }
      return(temp_config)
      
    }, error = function(e) {
      # Last resort: use /tmp
      return("/tmp")
    })
  }
  
  # Set up config directory
  config_dir <- safe_config_dir()
  Sys.setenv("R_USER_CONFIG_DIR" = config_dir)
  
  # Ensure rstudio config subdirectory exists
  rstudio_config <- file.path(config_dir, "rstudio")
  if (!dir.exists(rstudio_config)) {
    dir.create(rstudio_config, recursive = TRUE, mode = "0755")
  }
})
