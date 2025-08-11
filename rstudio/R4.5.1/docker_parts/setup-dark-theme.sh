#!/bin/bash
# RStudio Dark Theme Setup Script
# Run this inside your container to apply the dark login theme

echo "🎨 Setting up RStudio Server Dark Login Theme..."

# Create necessary directories
mkdir -p /etc/rstudio/www/css
mkdir -p /etc/rstudio/templates

# Copy theme files (these should be copied during container build)
echo "📁 Copying theme files..."

# Create the CSS file directly if not exists
cat > /etc/rstudio/rstudio-dark-theme.css << 'EOF'
/* RStudio Server Dark Login Theme */
body {
    background: linear-gradient(135deg, #0f0f23 0%, #1a1a2e 50%, #16213e 100%);
    margin: 0;
    padding: 0;
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    min-height: 100vh;
}

.login-wrapper, .container {
    background: transparent;
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
}

.login-form, .login-panel {
    background: rgba(30, 30, 50, 0.95) !important;
    border: 1px solid #444 !important;
    border-radius: 12px !important;
    padding: 40px !important;
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4) !important;
    backdrop-filter: blur(10px);
    max-width: 400px;
    width: 100%;
}

h3, h4, .login-header {
    color: #ffffff !important;
    text-align: center;
    margin-bottom: 30px;
    font-weight: 300;
}

input[type="text"], input[type="password"] {
    background: rgba(255, 255, 255, 0.1) !important;
    border: 1px solid #555 !important;
    border-radius: 6px !important;
    padding: 14px !important;
    color: #ffffff !important;
    width: 100% !important;
    font-size: 14px !important;
    box-sizing: border-box !important;
}

input[type="text"]:focus, input[type="password"]:focus {
    outline: none !important;
    border-color: #4a9eff !important;
    box-shadow: 0 0 0 2px rgba(74, 158, 255, 0.2) !important;
}

input::placeholder {
    color: #aaa !important;
}

label {
    color: #cccccc !important;
    font-size: 14px !important;
}

button, .btn {
    background: linear-gradient(135deg, #4a9eff 0%, #0066cc 100%) !important;
    border: none !important;
    border-radius: 6px !important;
    padding: 14px 24px !important;
    color: white !important;
    font-size: 16px !important;
    font-weight: 500 !important;
    cursor: pointer !important;
    transition: all 0.3s ease !important;
}

button:hover, .btn:hover {
    background: linear-gradient(135deg, #5aa6ff 0%, #0070dd 100%) !important;
    transform: translateY(-1px) !important;
    box-shadow: 0 4px 12px rgba(74, 158, 255, 0.3) !important;
}

.checkbox label, .form-group label {
    color: #cccccc !important;
}

small, .help-block {
    color: #888 !important;
}
EOF

echo "✅ Dark theme CSS created at /etc/rstudio/rstudio-dark-theme.css"

# Update rserver.conf to use custom CSS
echo "🔧 Updating rserver.conf..."
if ! grep -q "www-login-css" /etc/rstudio/rserver.conf; then
    echo "www-login-css=/etc/rstudio/rstudio-dark-theme.css" >> /etc/rstudio/rserver.conf
    echo "✅ Added custom CSS to rserver.conf"
fi

# Restart RStudio Server to apply changes
echo "🔄 Restarting RStudio Server..."
systemctl restart rstudio-server

echo "🎉 Dark theme setup complete! Your RStudio login should now have a beautiful dark theme."
echo "🌐 Access RStudio at: http://localhost:8787"
