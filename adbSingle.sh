#!/bin/bash

===========================================

Termux ADB One-Click Setup & User Manual

===========================================

# Configuration file for saving devices
CONFIG_FILE="$HOME/.termux_adb_devices"
LOG_FILE="$HOME/.termux_adb_log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log activities
log_activity() {
    echo "$(date): $1" >> "$LOG_FILE"
}

# Function to save device credentials
save_device() {
    local device_name=$1
    local pair_ip=$2
    local conn_ip=$3
    local pair_code=$4
    
    echo "$device_name|$pair_ip|$conn_ip|$pair_code" >> "$CONFIG_FILE"
    echo -e "${GREEN}Device '$device_name' saved successfully!${NC}"
    log_activity "Saved device: $device_name"
}

# Function to load saved devices
load_devices() {
    if [[ -f "$CONFIG_FILE" ]]; then
        cat "$CONFIG_FILE"
    else
        echo ""
    fi
}

# Function to connect to saved device
connect_saved_device() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${RED}No saved devices found!${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Saved Devices:${NC}"
    echo "=============="
    
    local i=1
    local devices=()
    
    while IFS='|' read -r name pair_ip conn_ip pair_code; do
        if [[ -n "$name" ]]; then
            echo "$i. $name - $conn_ip"
            devices[i]="$name|$pair_ip|$conn_ip|$pair_code"
            ((i++))
        fi
    done < "$CONFIG_FILE"
    
    if [[ $i -eq 1 ]]; then
        echo -e "${RED}No saved devices found!${NC}"
        return 1
    fi
    
    echo
    read -p "Select device to connect (number): " device_num
    
    if [[ ! "$device_num" =~ ^[0-9]+$ ]] || [[ "$device_num" -lt 1 ]] || [[ "$device_num" -ge $i ]]; then
        echo -e "${RED}Invalid selection!${NC}"
        return 1
    fi
    
    IFS='|' read -r name pair_ip conn_ip pair_code <<< "${devices[$device_num]}"
    
    echo -e "${YELLOW}Connecting to $name...${NC}"
    log_activity "Connecting to saved device: $name"
    
    # Try to connect directly
    if adb connect "$conn_ip"; then
        echo -e "${GREEN}✅ Successfully connected to $name!${NC}"
        echo
        adb devices
        log_activity "Successfully connected to $name"
    else
        echo -e "${RED}❌ Connection failed!${NC}"
        echo -e "${YELLOW}Trying to pair first...${NC}"
        
        # Try pairing first
        if adb pair "$pair_ip" "$pair_code"; then
            echo -e "${GREEN}Pairing successful!${NC}"
            if adb connect "$conn_ip"; then
                echo -e "${GREEN}✅ Successfully connected to $name!${NC}"
                log_activity "Re-paired and connected to $name"
            else
                echo -e "${RED}❌ Still unable to connect.${NC}"
            fi
        else
            echo -e "${RED}❌ Pairing also failed. Please check connection.${NC}"
        fi
    fi
}

# Function to delete saved device
delete_saved_device() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${RED}No saved devices found!${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Saved Devices:${NC}"
    echo "=============="
    
    local i=1
    local devices=()
    
    while IFS='|' read -r name pair_ip conn_ip pair_code; do
        if [[ -n "$name" ]]; then
            echo "$i. $name - $conn_ip"
            devices[i]="$name|$pair_ip|$conn_ip|$pair_code"
            ((i++))
        fi
    done < "$CONFIG_FILE"
    
    echo
    read -p "Select device to delete (number): " device_num
    
    if [[ ! "$device_num" =~ ^[0-9]+$ ]] || [[ "$device_num" -lt 1 ]] || [[ "$device_num" -ge $i ]]; then
        echo -e "${RED}Invalid selection!${NC}"
        return 1
    fi
    
    # Create temporary file without the selected device
    temp_file=$(mktemp)
    local j=1
    while IFS='|' read -r name pair_ip conn_ip pair_code; do
        if [[ -n "$name" ]] && [[ $j -ne $device_num ]]; then
            echo "$name|$pair_ip|$conn_ip|$pair_code" >> "$temp_file"
        fi
        ((j++))
    done < "$CONFIG_FILE"
    
    mv "$temp_file" "$CONFIG_FILE"
    echo -e "${GREEN}Device deleted successfully!${NC}"
    log_activity "Deleted device number: $device_num"
}

# Function to show connection status
show_status() {
    echo -e "${BLUE}Current ADB Status:${NC}"
    echo "================="
    adb devices
    echo
    echo -e "${BLUE}Saved Devices:${NC}"
    echo "=============="
    if [[ -f "$CONFIG_FILE" ]]; then
        cat "$CONFIG_FILE" | while IFS='|' read -r name pair_ip conn_ip pair_code; do
            if [[ -n "$name" ]]; then
                echo "📱 $name - $conn_ip"
            fi
        done
    else
        echo "No saved devices"
    fi
}

# Function to setup ADB
setup_adb() {
    clear
    echo -e "${BLUE}Welcome to Termux ADB Setup Tool${NC}"
    echo "---------------------------------"
    echo "This tool will install ADB in Termux and guide you to connect via Wireless Debugging."
    echo
    sleep 2

    # Step 1: Update Termux & install android-tools
    echo -e "${YELLOW}[1/3] Updating Termux & Installing ADB...${NC}"
    pkg update -y && pkg upgrade -y
    pkg install android-tools -y
    echo -e "${GREEN}ADB installed successfully!${NC}"
    echo
    sleep 1
}

# Function for new device setup
setup_new_device() {
    # Step 2: Instructions for Wireless Debugging
    echo -e "${YELLOW}[2/3] Wireless Debugging Setup${NC}"
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
    read -p "Enter a name for this device: " DEVICE_NAME
    
    echo -e "${YELLOW}Pairing device...${NC}"
    if adb pair "$PAIR_IP" "$PAIR_CODE"; then
        echo -e "${GREEN}Device paired successfully!${NC}"
        log_activity "Paired new device: $DEVICE_NAME"
    else
        echo -e "${RED}Pairing failed!${NC}"
        return 1
    fi
    echo
    sleep 1

    # Step 4: Connect device
    read -p "Enter the IP:port for actual connection (example: 192.168.43.195:43107): " CONN_IP
    
    echo -e "${YELLOW}Connecting device...${NC}"
    if adb connect "$CONN_IP"; then
        echo -e "${GREEN}✅ Connection successful!${NC}"
        log_activity "Connected to: $DEVICE_NAME at $CONN_IP"
        
        # Save device credentials
        save_device "$DEVICE_NAME" "$PAIR_IP" "$CONN_IP" "$PAIR_CODE"
    else
        echo -e "${RED}❌ Connection failed!${NC}"
        return 1
    fi
    
    echo
    echo -e "${GREEN}Checking connected devices...${NC}"
    adb devices
}

# Function to show user manual
show_manual() {
    clear
    echo -e "${BLUE}📖 ADB User Manual & Common Commands${NC}"
    echo "=========================================="
    echo
    echo -e "${GREEN}Basic Commands:${NC}"
    echo "----------------"
    echo "1. Open ADB shell: adb shell"
    echo "2. List files: ls /sdcard"
    echo "3. Install APK: adb install myapp.apk"
    echo "4. Pull file from phone: adb pull /sdcard/file.txt"
    echo "5. Push file to phone: adb push file.txt /sdcard/"
    echo "6. Disconnect device: adb disconnect IP:PORT"
    echo "7. Take screenshot: adb exec-out screencap -p > screenshot.png"
    echo "8. Record screen: adb shell screenrecord /sdcard/demo.mp4"
    echo "9. List packages: adb shell pm list packages"
    echo "10. Uninstall app: adb uninstall com.example.app"
    echo
    echo -e "${GREEN}Advanced Commands:${NC}"
    echo "------------------"
    echo "1. Reboot device: adb reboot"
    echo "2. Boot to recovery: adb reboot recovery"
    echo "3. Boot to bootloader: adb reboot bootloader"
    echo "4. View logs: adb logcat"
    echo "5. Backup device: adb backup -all -f backup.ab"
    echo "6. Restore backup: adb restore backup.ab"
    echo
    echo -e "${GREEN}File Management:${NC}"
    echo "-----------------"
    echo "1. Copy file to device: adb push local.txt /sdcard/"
    echo "2. Copy file from device: adb pull /sdcard/remote.txt ."
    echo "3. List device files: adb shell ls /sdcard/"
    echo
    read -p "Press Enter to return to main menu..."
}

# Function to show quick actions
quick_actions() {
    while true; do
        clear
        echo -e "${BLUE}⚡ Quick ADB Actions${NC}"
        echo "==================="
        echo
        echo "1. 📱 List connected devices"
        echo "2. 📁 List sdcard contents"
        echo "3. 📸 Take screenshot"
        echo "4. 📹 Start screen recording (10s)"
        echo "5. 📊 Show device info"
        echo "6. 📦 List installed packages"
        echo "7. 🔙 Back to main menu"
        echo
        
        read -p "Select action (1-7): " action_choice
        
        case $action_choice in
            1)
                echo -e "${YELLOW}Connected devices:${NC}"
                adb devices
                ;;
            2)
                echo -e "${YELLOW}sdcard contents:${NC}"
                adb shell ls -la /sdcard/
                ;;
            3)
                echo -e "${YELLOW}Taking screenshot...${NC}"
                adb exec-out screencap -p > screenshot_$(date +%Y%m%d_%H%M%S).png
                echo -e "${GREEN}Screenshot saved!${NC}"
                ;;
            4)
                echo -e "${YELLOW}Starting screen recording for 10 seconds...${NC}"
                adb shell screenrecord /sdcard/record_$(date +%Y%m%d_%H%M%S).mp4 &
                sleep 10
                adb shell killall screenrecord
                echo -e "${GREEN}Recording saved to device!${NC}"
                ;;
            5)
                echo -e "${YELLOW}Device information:${NC}"
                adb shell getprop | grep -E 'ro.product.model|ro.build.version.sdk|ro.serialno'
                ;;
            6)
                echo -e "${YELLOW}Installed packages:${NC}"
                adb shell pm list packages | head -20
                echo "... (showing first 20 packages)"
                ;;
            7)
                break
                ;;
            *)
                echo -e "${RED}Invalid choice!${NC}"
                ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
    done
}

# Main menu
main_menu() {
    while true; do
        clear
        echo -e "${BLUE}===========================================${NC}"
        echo -e "${BLUE}    Termux ADB Manager v2.0${NC}"
        echo -e "${BLUE}===========================================${NC}"
        echo
        echo -e "${GREEN}🏠 Main Menu${NC}"
        echo "==========="
        echo
        echo "1. 🔧 Setup ADB & Connect New Device"
        echo "2. ⚡ Connect to Saved Device (One-Click)"
        echo "3. 📱 Quick ADB Actions"
        echo "4. 💾 Manage Saved Devices"
        echo "5. 📊 Show Current Status"
        echo "6. 📖 User Manual & Commands"
        echo "7. 🗑️  Clear Logs & Cache"
        echo "8. 🚪 Exit"
        echo
        
        read -p "Select option (1-8): " main_choice
        
        case $main_choice in
            1)
                setup_adb
                setup_new_device
                ;;
            2)
                connect_saved_device
                ;;
            3)
                quick_actions
                ;;
            4)
                manage_devices_menu
                ;;
            5)
                show_status
                ;;
            6)
                show_manual
                ;;
            7)
                clear_logs
                ;;
            8)
                echo -e "${GREEN}Thank you for using Termux ADB Manager!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice! Please try again.${NC}"
                ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
    done
}

# Manage devices menu
manage_devices_menu() {
    while true; do
        clear
        echo -e "${BLUE}💾 Manage Saved Devices${NC}"
        echo "======================"
        echo
        echo "1. 📋 List all saved devices"
        echo "2. ❌ Delete saved device"
        echo "3. 🔙 Back to main menu"
        echo
        
        read -p "Select option (1-3): " manage_choice
        
        case $manage_choice in
            1)
                show_status
                ;;
            2)
                delete_saved_device
                ;;
            3)
                break
                ;;
            *)
                echo -e "${RED}Invalid choice!${NC}"
                ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
    done
}

# Function to clear logs
clear_logs() {
    if [[ -f "$LOG_FILE" ]]; then
        rm "$LOG_FILE"
        echo -e "${GREEN}Logs cleared successfully!${NC}"
    fi
    
    if [[ -f "$CONFIG_FILE" ]]; then
        echo -e "${YELLOW}Note: Saved devices are preserved.${NC}"
    else
        echo -e "${YELLOW}No logs or saved devices found.${NC}"
    fi
}

# Initialize
echo -e "${BLUE}Initializing Termux ADB Manager...${NC}"
log_activity "Script started"

# Check if ADB is installed
if ! command -v adb &> /dev/null; then
    echo -e "${YELLOW}ADB not found. Starting setup...${NC}"
    setup_adb
fi

# Start main menu
main_menu
