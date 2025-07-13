#!/bin/bash

# Build the project
swift build -c release

# Create app bundle structure
mkdir -p ScreenTextExtractor.app/Contents/MacOS
mkdir -p ScreenTextExtractor.app/Contents/Resources

# Copy executable
cp .build/release/ScreenTextExtractor ScreenTextExtractor.app/Contents/MacOS/

# Make executable
chmod +x ScreenTextExtractor.app/Contents/MacOS/ScreenTextExtractor

# Create simple icon (using system icon)
cp /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/KEXT.icns ScreenTextExtractor.app/Contents/Resources/AppIcon.icns 2>/dev/null || echo "Icon copy failed, continuing..."

echo "App bundle created: ScreenTextExtractor.app"
echo "You can now:"
echo "1. Test it: open ScreenTextExtractor.app"
echo "2. Move it to Applications: mv ScreenTextExtractor.app /Applications/"