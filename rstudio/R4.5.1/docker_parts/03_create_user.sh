#!/bin/bash
set -e

echo "👥 Creating multiple users for RStudio Server..."

# Create system groups
groupadd -g 8536 cdsw || true
groupadd -g 8500 rstudio-users || true

# Create users and assign to rstudio-users
if ! id -u cdsw >/dev/null 2>&1; then
    useradd -u 8536 -g cdsw -G rstudio-users -m -s /bin/bash cdsw
    echo "cdsw:cdsw" | chpasswd
    echo "✅ Created user: cdsw"
fi

if ! id -u dev1 >/dev/null 2>&1; then
    useradd -u 8537 -g rstudio-users -G cdsw -m -s /bin/bash dev1
    echo "dev1:dev1" | chpasswd
    echo "✅ Created user: dev1"
fi

if ! id -u dev2 >/dev/null 2>&1; then
    useradd -u 8538 -g rstudio-users -G cdsw -m -s /bin/bash dev2
    echo "dev2:dev2" | chpasswd
    echo "✅ Created user: dev2"
fi

# Create monitored user-settings and assign correct ownership
for user in cdsw dev1 dev2; do
    mkdir -p /home/$user/.rstudio/monitored/user-settings
    echo "alwaysSaveHistory=0" > /home/$user/.rstudio/monitored/user-settings/user-settings
    chown -R $user:rstudio-users /home/$user
    chmod 755 /home/$user
done

# R shared site library access
mkdir -p /usr/local/lib/R/site-library
chown -R root:rstudio-users /usr/local/lib/R
chmod -R 775 /usr/local/lib/R/site-library

echo "✅ All users created successfully"
