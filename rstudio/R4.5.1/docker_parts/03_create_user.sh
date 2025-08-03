#!/bin/bash
set -e

echo "👥 Creating multiple users for RStudio Server..."

# Create the primary cdsw group first
groupadd -g 8536 cdsw || true

# Create a common group for R users
groupadd -g 8500 rstudio-users || true

# Create cdsw user with its own group
if ! id -u cdsw >/dev/null 2>&1; then
    useradd -u 8536 -g 8536 -G rstudio-users -m -s /bin/bash cdsw
    echo "cdsw:cdsw" | chpasswd
    echo "✅ Created user: cdsw"
fi

# Create dev1 user
if ! id -u dev1 >/dev/null 2>&1; then
    useradd -u 8537 -g rstudio-users -G cdsw -m -s /bin/bash dev1
    echo "dev1:dev1" | chpasswd
    echo "✅ Created user: dev1"
fi

# Create dev2 user
if ! id -u dev2 >/dev/null 2>&1; then
    useradd -u 8538 -g rstudio-users -G cdsw -m -s /bin/bash dev2
    echo "dev2:dev2" | chpasswd
    echo "✅ Created user: dev2"
fi

# Set up home directories and permissions
for user in cdsw dev1 dev2; do
    mkdir -p /home/$user
    mkdir -p /home/$user/.rstudio/monitored/user-settings
    echo "alwaysSaveHistory=0" > /home/$user/.rstudio/monitored/user-settings/user-settings
    chown -R $user:$(id -gn $user) /home/$user
    chmod 755 /home/$user
done

# Ensure all users can access R libraries
mkdir -p /usr/local/lib/R/site-library
chown -R root:rstudio-users /usr/local/lib/R
chmod -R 775 /usr/local/lib/R/site-library

echo "✅ All users created successfully"

