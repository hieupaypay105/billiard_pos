#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Change directory to the script's directory (apps/billiard_desktop)
cd "$(dirname "$0")"

echo "=== STEP 1: Cleaning and fetching dependencies ==="
flutter clean
flutter pub get

echo "=== STEP 2: Building Flutter macOS Release ==="
flutter build macos --release

echo "=== STEP 3: Preparing DMG staging directory ==="
STAGING_DIR="build/dmg_staging"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

# Copy the app to the staging directory
cp -R "build/macos/Build/Products/Release/billiard_desktop.app" "$STAGING_DIR/"

# Copy the installation instructions
cp "Huong_dan_Cai_dat.txt" "$STAGING_DIR/"

# Create a symlink to Applications folder
ln -s /Applications "$STAGING_DIR/Applications"

echo "=== STEP 4: Creating DMG package ==="
DMG_NAME="billiard_desktop_installer.dmg"
rm -f "$DMG_NAME"

hdiutil create -volname "Billiard POS Installer" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_NAME"

echo "=== SUCCESS ==="
echo "DMG package created successfully at: $(pwd)/$DMG_NAME"
