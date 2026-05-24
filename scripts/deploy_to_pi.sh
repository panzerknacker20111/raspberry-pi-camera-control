#!/bin/bash

# Deploy picamctl locally on the Raspberry Pi
# Usage: ./deploy_to_pi.sh (run directly on the Pi)

# Get the project root directory (parent of scripts/)
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REMOTE_DIR="/home/${USER}/picamctl"

echo "🚀 Deploying picamctl locally..."

cd "$PROJECT_ROOT"

# Create target directory if it doesn't exist
mkdir -p "${REMOTE_DIR}"

# Copy files
echo "📦 Copying files..."
cp picamctl.py                          "${REMOTE_DIR}/"
cp templates/garage_cam_template.html   "${REMOTE_DIR}/"
cp templates/landing.html               "${REMOTE_DIR}/"
cp templates/vlc_stream.html            "${REMOTE_DIR}/"
cp -r static/                           "${REMOTE_DIR}/"
# Skip settings file - preserve existing Pi settings
# cp picamctl_settings.json             "${REMOTE_DIR}/"
cp systemd/picamctl.service             "${REMOTE_DIR}/"
cp scripts/manage_service.sh            "${REMOTE_DIR}/"
cp requirements.txt                     "${REMOTE_DIR}/"

# Install system dependencies
echo "📦 Installing system dependencies..."
echo "   Running apt-get update..."
sudo apt-get update -qq
echo "   Installing system packages..."
if sudo apt-get install -y -qq python3-pip python3-flask python3-paho-mqtt ffmpeg; then
    echo "   System dependencies installed"
else
    echo "   ⚠️  Some dependencies may have failed - check the apt-get output above"
fi

# Install Python dependencies
echo "📦 Installing Python dependencies..."
cd "${REMOTE_DIR}"
pip3 install -r requirements.txt --break-system-packages
cd "$PROJECT_ROOT"

# Make scripts executable
chmod +x "${REMOTE_DIR}/manage_service.sh"

# Detect Pi model and optimize if Zero 2 W
echo "🔍 Detecting Pi model..."
PI_MODEL=$(cat /proc/device-tree/model 2>/dev/null || echo "Unknown")
echo "Pi Model: $PI_MODEL"

if echo "$PI_MODEL" | grep -q "Zero 2 W"; then
    echo "ℹ️  Detected Raspberry Pi Zero 2 W - Applying optimizations..."
    SETTINGS_FILE="${REMOTE_DIR}/picamctl_settings.json"
    if [ ! -f "$SETTINGS_FILE" ]; then
        echo '{
    "width": 1280,
    "height": 720,
    "framerate": 10
}' > "$SETTINGS_FILE"
        echo "   Created optimized default settings for Pi Zero 2 W"
    else
        echo "   Existing settings found - manual optimization recommended: 1280x720 @ 10fps"
    fi
fi

# Install/update systemd service
echo "⚙️  Installing systemd service..."
sudo cp "${REMOTE_DIR}/picamctl.service" /etc/systemd/system/
sudo systemctl daemon-reload

# Enable and restart service
echo "🔄 Enabling and restarting picamctl service..."
sudo systemctl enable picamctl
sudo systemctl restart picamctl

# Check status
echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Service status:"
sudo systemctl status picamctl --no-pager -l | head -20

echo ""
echo "🌐 Access camera at: http://$(hostname -I | awk '{print $1}'):5000"
echo ""
echo "📝 View logs with:"
echo "   sudo journalctl -u picamctl -f"
