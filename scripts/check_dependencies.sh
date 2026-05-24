#!/bin/bash

# Check and install dependencies for H.264 HLS streaming
# Run this script directly on the Raspberry Pi

echo "🔍 Checking dependencies on Raspberry Pi..."

# Helper function
check_and_install_apt() {
    local pkg="$1"
    local bin="$2"
    echo "Checking $pkg..."
    if which "$bin" > /dev/null 2>&1; then
        echo "✅ $pkg is installed"
        return 0
    else
        echo "❌ $pkg is NOT installed"
        echo "Installing $pkg..."
        sudo apt-get update && sudo apt-get install -y "$pkg"
        if [ $? -eq 0 ]; then
            echo "✅ $pkg installed successfully"
        else
            echo "❌ Failed to install $pkg"
            exit 1
        fi
    fi
}

# ffmpeg
check_and_install_apt ffmpeg ffmpeg
ffmpeg -version | head -1

echo ""
# rpicam-vid
echo "Checking rpicam-vid..."
if which rpicam-vid > /dev/null 2>&1; then
    echo "✅ rpicam-vid is installed"
else
    echo "⚠️  rpicam-vid is NOT installed"
    echo "Install with: sudo apt install -y rpicam-apps"
fi

echo ""
# Python3
check_and_install_apt python3 python3
python3 --version

echo ""
# pip3
check_and_install_apt python3-pip pip3

echo ""
# Flask
echo "Checking Flask..."
if python3 -c "import flask" 2>/dev/null; then
    echo "✅ Flask is installed"
    python3 -c "import flask; print(f'Flask version: {flask.__version__}')"
else
    echo "❌ Flask is NOT installed"
    echo "Installing Flask..."
    pip3 install flask --break-system-packages
    if [ $? -eq 0 ]; then
        echo "✅ Flask installed successfully"
    else
        echo "❌ Failed to install Flask"
        exit 1
    fi
fi

echo ""
# paho-mqtt
echo "Checking paho-mqtt..."
if pip3 show paho-mqtt > /dev/null 2>&1; then
    echo "✅ paho-mqtt is installed"
else
    echo "❌ paho-mqtt is NOT installed"
    echo "Installing paho-mqtt..."
    pip3 install paho-mqtt --break-system-packages
    if [ $? -eq 0 ]; then
        echo "✅ paho-mqtt installed successfully"
    else
        echo "❌ Failed to install paho-mqtt"
        exit 1
    fi
fi

echo ""
# mosquitto-clients
check_and_install_apt mosquitto-clients mosquitto_pub

echo ""
# Kamera
echo "Checking camera module..."
vcgencmd get_camera

echo ""
# Pi-Modell erkennen
echo "Detecting Pi model..."
cat /proc/device-tree/model 2>/dev/null || echo "Unknown model"
echo ""

if grep -q "Zero 2 W" /proc/device-tree/model 2>/dev/null; then
    echo "⚠️  Detected Raspberry Pi Zero 2 W - Optimizing for lower resources..."
    echo "Recommendation: Use 720p resolution and 10-15 FPS for best performance."
fi

echo ""
echo "✅ All dependencies checked!"
