#!/bin/bash

set -e

APP_NAME="ScreenTextExtractor"
DMG_NAME="ScreenTextExtractor-1.0"
VOLUME_NAME="ScreenTextExtractor"

echo "Building app..."
./create_app.sh

echo "Creating DMG structure..."
mkdir -p dmg_temp
cp -R ${APP_NAME}.app dmg_temp/

# Create a symbolic link to Applications folder
ln -sf /Applications dmg_temp/Applications

echo "Creating DMG file..."
hdiutil create -volname "${VOLUME_NAME}" \
               -srcfolder dmg_temp \
               -ov \
               -format UDZO \
               "${DMG_NAME}.dmg"

# Clean up
rm -rf dmg_temp

echo "DMG created: ${DMG_NAME}.dmg"
echo ""
echo "Installation instructions:"
echo "1. Open ${DMG_NAME}.dmg"
echo "2. Drag ScreenTextExtractor.app to Applications folder"
echo "3. Launch from Applications or Spotlight"