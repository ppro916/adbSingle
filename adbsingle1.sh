#!/bin/bash
# ===========================================
# Termux ADB One-Click Setup & User Manual
# ===========================================

clear
echo "Welcome to Termux ADB Setup Tool"
echo "---------------------------------"
echo "This tool will install ADB in Termux and guide you to connect via Wireless Debugging."
echo
sleep 2

# Step 1: Update Termux & install android-tools
echo "[1/3] Updating Termux & Installing ADB..."
pkg update -y && pkg upgrade -y
pkg install android-tools -y
echo "ADB installed successfully!"
echo
sleep 1

# Step 2: Instructions for Wireless Debugging
echo "[2/3] Wireless Debugging Setup"
echo "---------------------------------"
echo "1. Go to your phone: Settings → Developer Options → Wireless Debugging → Enable it"
echo "2. Tap 'Pair device with pairing code' and note down:"
echo "   - IP address & port (example: 192.168.43.195:43107)"
echo "   - Pairing code (example: 123456)"
echo
read -p "Press Enter once you have noted the IP & pairing code..."

# Step 3: Pair device
read -p "Enter the IP:port for pairing (example: 192.168.43.195:36349): " PAIR_IP
read -p "Enter the pairing code: " PAIR_CODE
adb pair $PAIR_IP
echo "Device paired successfully!"
echo
sleep 1

# Step 4: Connect device
read -p "Enter the IP:port for actual connection (example: 192.168.43.195:43107): " CONN_IP
adb connect $CONN_IP
echo
echo "Checking connected devices..."
adb devices
echo
echo "✅ Setup Complete!"
echo
echo "User Manual & Tips:"
echo "---------------------------------"
echo "1. Open ADB shell: adb shell"
echo "2. List files: ls /sdcard"
echo "3. Install APK: adb install myapp.apk"
echo "4. Pull file from phone: adb pull /sdcard/file.txt"
echo "5. Push file to phone: adb push file.txt /sdcard/"
echo "6. Disconnect device: adb disconnect $CONN_IP"
echo
echo "For more commands, check: https://developer.android.com/studio/command-line/adb"
echo
echo "You can now easily use Termux ADB with wireless debugging!"
