#!/bin/bash

# Script to build and install SOOTHSAYER ATAK plugin to ALL connected devices/emulators
# Usage: ./install-soothsayer-plugin.sh

set -e

# Find the latest built APK
APK_DIR="app/build/outputs/apk/civ/debug"
PLUGIN_PACKAGE="com.atakmap.android.soothsayer.plugin"
PLUGIN_NAME="SOOTHSAYER"
ATAK_PACKAGE="com.atakmap.app.civ"

echo "=== $PLUGIN_NAME Plugin Builder & Multi-Device Installer ==="
echo ""

# Step 1: Build the plugin
echo "Step 1: Building $PLUGIN_NAME plugin..."
echo "Running: ./gradlew clean assembleCivDebug"
./gradlew clean assembleCivDebug

if [ $? -ne 0 ]; then
    echo "Error: Build failed!"
    exit 1
fi
echo "✓ Build completed successfully"

# Step 2: Find the APK
echo ""
echo "Step 2: Finding plugin APKs..."
if [ ! -d "$APK_DIR" ]; then
    echo "Error: Build directory not found even after successful build."
    exit 1
fi

# Find all recent APK files
APK_FILES=$(ls -t "$APK_DIR"/ATAK-Plugin-${PLUGIN_NAME}-*.apk 2>/dev/null)

if [ -z "$APK_FILES" ]; then
    echo "Error: No plugin APKs found in $APK_DIR"
    exit 1
fi

# Step 3: Get list of connected devices
echo ""
echo "Step 3: Getting list of connected devices/emulators..."
DEVICE_LIST=$(adb devices | grep -v "List of devices attached" | grep "device$" | awk '{print $1}')

if [ -z "$DEVICE_LIST" ]; then
    echo "Error: No devices/emulators found. Please connect a device or start an emulator."
    exit 1
fi

echo "Found devices:"
for DEVICE_ID in $DEVICE_LIST; do
    echo "  - $DEVICE_ID"
done

# Step 4 & 5: Loop through each APK and then each device to uninstall, install, and verify
for APK_FILE in $APK_FILES; do
    echo ""
    echo "====================================================="
    echo "Processing APK: $APK_FILE"
    echo "Size: $(ls -lh "$APK_FILE" | awk '{print $5}')"
    echo "====================================================="

    for DEVICE_ID in $DEVICE_LIST; do
        echo ""
        echo "-----------------------------------------------------"
        echo "Processing device: $DEVICE_ID for $APK_FILE"
        echo "-----------------------------------------------------"

        echo ""
        echo "Step 4.1 ($DEVICE_ID): Checking for existing plugin installation..."
        if adb -s "$DEVICE_ID" shell pm list packages | grep -q "$PLUGIN_PACKAGE"; then
            echo "Found existing plugin on $DEVICE_ID, uninstalling..."
            adb -s "$DEVICE_ID" uninstall "$PLUGIN_PACKAGE"
            echo "Old plugin uninstalled from $DEVICE_ID"
        else
            echo "No existing plugin found on $DEVICE_ID"
        fi

        echo ""
        echo "Step 4.2 ($DEVICE_ID): Installing $PLUGIN_NAME plugin..."
        adb -s "$DEVICE_ID" install -r "$APK_FILE"

        echo ""
        echo "Step 5 ($DEVICE_ID): Verifying installation..."
        if adb -s "$DEVICE_ID" shell pm list packages | grep -q "$PLUGIN_PACKAGE"; then
            echo "✓ $PLUGIN_NAME plugin installed successfully on $DEVICE_ID from $APK_FILE"
            
            # Get version info
            VERSION_INFO=$(adb -s "$DEVICE_ID" shell dumpsys package "$PLUGIN_PACKAGE" | grep -E "versionCode|versionName" | head -2)
            echo ""
            echo "($DEVICE_ID) Version info:"
            echo "$VERSION_INFO"
            
            # Check if ATAK is installed
            echo ""
            if adb -s "$DEVICE_ID" shell pm list packages | grep -q "$ATAK_PACKAGE"; then
                echo "✓ ($DEVICE_ID) ATAK (CIV) is installed"
            else
                echo "⚠ ($DEVICE_ID) ATAK (CIV) not found - please install ATAK first"
            fi
            
        else
            echo "✗ ($DEVICE_ID) Plugin installation FAILED for $APK_FILE. Skipping further checks for this device."
        fi
    done
done

echo ""
echo "====================================================="
echo "=== Multi-Device Installation Complete            ==="
echo "====================================================="
echo ""

echo "Next steps (for each device):"
echo "1. Open ATAK"
echo "2. Go to Settings → Tool Preferences → $PLUGIN_NAME"
echo "3. Configure your API credentials"
echo "4. Use the $PLUGIN_NAME icon in the toolbar to access the plugin"
echo ""
echo "Troubleshooting (for each device):"
echo "- Check 'adb -s <DEVICE_ID> logcat | grep -E \"$PLUGIN_NAME\"' for debug logs"
echo "- Ensure you have a working internet connection"
echo "- Verify your API credentials are correct" 