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
    
    # Create user-settings file with comprehensive preferences
    cat <<SETTINGS > /home/$user/.rstudio/monitored/user-settings/user-settings
alwaysSaveHistory=0
loadRData=0
saveAction=0
showLineNumbers=1
highlightSelectedLine=1
highlightSelectedWord=1
softWrapRFiles=0
showMargin=1
marginColumn=120
enableCodeIndexing=1
showHiddenFiles=0
fontSize=10
theme=Tomorrow Night Bright
uiTheme=Modern
SETTINGS
    
    # Set proper ownership - home directories should be owned by the user
    chown -R $user:$user /home/$user
    chmod 755 /home/$user
done

# R shared site library access
mkdir -p /usr/local/lib/R/site-library
chown -R root:rstudio-users /usr/local/lib/R
chmod -R 775 /usr/local/lib/R/site-library

echo "✅ All users created successfully"
