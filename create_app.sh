#!/bin/bash

set -e

# Build the project
swift build -c release

# Create app bundle structure
mkdir -p ScreenTextExtractor.app/Contents/MacOS
mkdir -p ScreenTextExtractor.app/Contents/Resources

# Copy executable
cp .build/release/ScreenTextExtractor ScreenTextExtractor.app/Contents/MacOS/

# Make executable
chmod +x ScreenTextExtractor.app/Contents/MacOS/ScreenTextExtractor

# Compile asset catalog to generate AppIcon.icns
echo "Compiling asset catalog..."
xcrun actool ScreenTextExtractor/Assets.xcassets \
    --compile ScreenTextExtractor.app/Contents/Resources \
    --platform macosx \
    --minimum-deployment-target 15.0 \
    --app-icon AppIcon \
    --output-partial-info-plist ScreenTextExtractor.app/Contents/Resources/Info-partial.plist

# Create proper Info.plist
cat > ScreenTextExtractor.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>ScreenTextExtractor</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleIdentifier</key>
	<string>com.schroneko.ScreenTextExtractor</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>ScreenTextExtractor</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSMinimumSystemVersion</key>
	<string>15.0</string>
	<key>NSMainNibFile</key>
	<string></string>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
	<key>NSSupportsAutomaticTermination</key>
	<true/>
	<key>NSSupportsSuddenTermination</key>
	<true/>
	<key>NSAppleEventsUsageDescription</key>
	<string>This app needs access to Apple Events for global hotkey functionality.</string>
	<key>NSScreenCaptureUsageDescription</key>
	<string>This app needs screen capture access to capture selected screen regions for OCR text extraction.</string>
	<key>LSUIElement</key>
	<true/>
</dict>
</plist>
EOF

echo "App bundle created: ScreenTextExtractor.app"
echo "You can now:"
echo "1. Test it: open ScreenTextExtractor.app"
echo "2. Move it to Applications: mv ScreenTextExtractor.app /Applications/"