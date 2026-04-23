#!/usr/bin/env bash
# Build AudioSwitcher as a macOS .app bundle (drag-and-drop installable).
#
# Usage:
#   ./build.sh           Build AudioSwitcher.app (and ./AudioSwitcher binary)
#   ./build.sh clean     Remove build artifacts

set -euo pipefail

BUNDLE_NAME="AudioSwitcher"
BUNDLE_ID="com.audioswitcher"
VERSION="1.0"
MIN_MACOS="13.0"
SOURCE="AudioSwitcher.swift"
BINARY="AudioSwitcher"
APP="${BUNDLE_NAME}.app"
BUILD_DIR=".build"
ICON_SOURCE="generate_icon.swift"
ICON_NAME="AppIcon"

if [[ "${1:-}" == "clean" ]]; then
    rm -rf "${APP}" "${BINARY}" "${BUILD_DIR}"
    echo "Cleaned."
    exit 0
fi

mkdir -p "${BUILD_DIR}"

# 1. Compile the Swift source (release build)
echo "→ Compiling ${SOURCE}..."
swiftc -O -o "${BINARY}" "${SOURCE}" -framework Cocoa -framework Carbon

# 2. Create bundle skeleton
echo "→ Creating ${APP}..."
rm -rf "${APP}"
mkdir -p "${APP}/Contents/MacOS"
mkdir -p "${APP}/Contents/Resources"

# 3. Copy binary into the bundle
cp "${BINARY}" "${APP}/Contents/MacOS/${BUNDLE_NAME}"

# 4. Build the icon (PNG → iconset → .icns)
echo "→ Generating icon..."
swiftc -O -o "${BUILD_DIR}/generate_icon" "${ICON_SOURCE}" -framework Cocoa
"${BUILD_DIR}/generate_icon" "${BUILD_DIR}/icon.png"

ICONSET="${BUILD_DIR}/${BUNDLE_NAME}.iconset"
rm -rf "${ICONSET}"
mkdir -p "${ICONSET}"
# (display_size, actual_pixels, suffix)
for spec in "16 16 " "16 32 @2x" "32 32 " "32 64 @2x" "128 128 " "128 256 @2x" "256 256 " "256 512 @2x" "512 512 " "512 1024 @2x"; do
    read -r display actual suffix <<< "${spec}"
    sips -z "${actual}" "${actual}" "${BUILD_DIR}/icon.png" \
        --out "${ICONSET}/icon_${display}x${display}${suffix}.png" >/dev/null
done

iconutil -c icns -o "${BUILD_DIR}/${ICON_NAME}.icns" "${ICONSET}"
cp "${BUILD_DIR}/${ICON_NAME}.icns" "${APP}/Contents/Resources/${ICON_NAME}.icns"

# 5. Write Info.plist
cat > "${APP}/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${BUNDLE_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>${ICON_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${BUNDLE_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${BUNDLE_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>${MIN_MACOS}</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticTermination</key>
    <false/>
    <key>NSSupportsSuddenTermination</key>
    <false/>
</dict>
</plist>
EOF

# 6. Ad-hoc code-signing (keeps Gatekeeper quiet on the build machine)
echo "→ Ad-hoc signing..."
codesign --force --deep --sign - "${APP}" 2>/dev/null

echo ""
echo "✓ Built ${APP}"
echo ""
echo "Install: drag ${APP} into ~/Applications/ (or /Applications/)"
echo "   mv ${APP} ~/Applications/"
echo ""
echo "First launch: right-click → Open (one time, because no Developer-ID signature)."
