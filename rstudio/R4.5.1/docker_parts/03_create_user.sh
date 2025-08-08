#!/bin/bash
set -e

echo "👥 Creating multiple users for RStudio Server..."

# Create system groups
groupadd -g 8500 rstudio-users || true
groupadd -g 8536 cdsw || true
groupadd -g 8537 dev1 || true
groupadd -g 8538 dev2 || true

# Create users with proper group assignments
if ! id -u cdsw >/dev/null 2>&1; then
    useradd -u 8536 -g cdsw -G rstudio-users -m -s /bin/bash cdsw
    echo "cdsw:cdsw" | chpasswd
    echo "✅ Created user: cdsw"
fi

if ! id -u dev1 >/dev/null 2>&1; then
    useradd -u 8537 -g dev1 -G rstudio-users -m -s /bin/bash dev1
    echo "dev1:dev1" | chpasswd
    echo "✅ Created user: dev1"
fi

if ! id -u dev2 >/dev/null 2>&1; then
    useradd -u 8538 -g dev2 -G rstudio-users -m -s /bin/bash dev2
    echo "dev2:dev2" | chpasswd
    echo "✅ Created user: dev2"
fi

# Create monitored user-settings and assign correct ownership
for user in cdsw dev1 dev2; do
    echo "🔧 Setting up RStudio directories for user: $user"
    
    # Create RStudio configuration directories
    mkdir -p /home/$user/.rstudio/monitored/user-settings
    
    # Verify directory creation
    if [ ! -d "/home/$user/.rstudio/monitored/user-settings" ]; then
        echo "⚠️ Failed to create RStudio directories for $user"
        continue
    fi
    
    echo "alwaysSaveHistory=0" > /home/$user/.rstudio/monitored/user-settings/user-settings
    
    # Set proper ownership - home directories should be owned by the user
    chown -R $user:$user /home/$user
    chmod 755 /home/$user
done

# ===============================
# === GUI Preferences for All Users ==
# ===============================
# Create RStudio preferences for all users
for user in cdsw dev1 dev2; do
    echo "🎨 Setting up RStudio preferences for user: $user"
    mkdir -p /home/$user/.config/rstudio
    cat <<PREFS > /home/$user/.config/rstudio/rstudio-prefs.json
{
  "font_size_points": 10,
  "ui_theme": "Modern",
  "editor_theme": "Tomorrow Night Bright",
  "show_line_numbers": true,
  "highlight_selected_line": true,
  "soft_wrap_r_files": false,
  "save_workspace": "never",
  "load_workspace": false,
  "scroll_past_end": true,
  "show_margin": true,
  "margin_column": 120,
  "enable_code_completion": true,
  "show_hidden_files": false
}
PREFS
    
    # Verify config directory creation
    if [ ! -d "/home/$user/.config/rstudio" ]; then
        echo "⚠️ Failed to create config directory for $user"
        continue
    fi
    
    # Set proper ownership for user's config directory
    chown -R $user:$user /home/$user/.config
    chmod -R 755 /home/$user/.config
done

# R shared site library access
mkdir -p /usr/local/lib/R/site-library
chown -R root:rstudio-users /usr/local/lib/R
chmod -R 775 /usr/local/lib/R/site-library

echo "✅ All users created successfully"
