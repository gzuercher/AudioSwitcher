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

if [[ "${1:-}" == "clean" ]]; then
    rm -rf "${APP}" "${BINARY}"
    echo "Cleaned."
    exit 0
fi

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

# 4. Write Info.plist
cat > "${APP}/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${BUNDLE_NAME}</string>
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

# 5. Ad-hoc code-signing (keeps Gatekeeper quiet on the build machine)
echo "→ Ad-hoc signing..."
codesign --force --deep --sign - "${APP}" 2>/dev/null

echo ""
echo "✓ Built ${APP}"
echo ""
echo "Install: drag ${APP} into ~/Applications/ (or /Applications/)"
echo "   mv ${APP} ~/Applications/"
echo ""
echo "First launch: right-click → Open (one time, because no Developer-ID signature)."
