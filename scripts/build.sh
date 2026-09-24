#!/usr/bin/env bash
set -euo pipefail

# ANSI color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

APP_NAME="RouterCheck"
CONFIG="Debug"
SWIFT_CONFIG="debug"
DO_CLEAN=false
TARGET_VERSION=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --release|--Release|-r)
            CONFIG="Release"
            SWIFT_CONFIG="release"
            shift
            ;;
        --debug|--Debug|-d)
            CONFIG="Debug"
            SWIFT_CONFIG="debug"
            shift
            ;;
        --clean|-c)
            DO_CLEAN=true
            shift
            ;;
        --version|-v)
            TARGET_VERSION="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: ./scripts/build.sh [OPTIONS]"
            echo "  --debug, -d              : Compile in Debug configuration (Default)"
            echo "  --release, -r            : Compile in Release configuration"
            echo "  --clean, -c              : Clean build cache before compiling"
            echo "  --version, -v <version>  : Override version string for Info.plist"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown parameter: $1${NC}"
            exit 1
            ;;
    esac
done

if [ "$DO_CLEAN" = true ]; then
    echo -e "${YELLOW}🧹 Cleaning build caches...${NC}"
    rm -rf "$PROJECT_ROOT/.build" "$PROJECT_ROOT/build"
fi

# Detect version and build number
if [ -z "$TARGET_VERSION" ]; then
    TARGET_VERSION=$(cat "$PROJECT_ROOT/VERSION" 2>/dev/null || echo "1.0.0")
fi
BUILD_NUM=$(cat "$PROJECT_ROOT/BUILD_NUMBER" 2>/dev/null || echo "1")

BUILD_DIR="$PROJECT_ROOT/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo -e "${BLUE}${BOLD}🔨 Building $APP_NAME... [Config: $CONFIG, Version: v$TARGET_VERSION (Build $BUILD_NUM)]${NC}"
START_TIME=$(date +%s)

# Compile using Swift Package Manager
swift build -c "$SWIFT_CONFIG"

BIN_PATH="$(swift build -c "$SWIFT_CONFIG" --show-bin-path)/$APP_NAME"

if [ ! -f "$BIN_PATH" ]; then
    echo -e "${RED}❌ Binary not found at: $BIN_PATH${NC}"
    exit 1
fi

echo -e "${BLUE}📦 Assembling $APP_NAME.app bundle...${NC}"
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

cp "$BIN_PATH" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

if [ -f "$PROJECT_ROOT/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_ROOT/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

cat <<EOF > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.routercheck.macos</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>Router Check</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$TARGET_VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_NUM</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
</dict>
</plist>
EOF

# Local ad-hoc codesigning
echo -e "${BLUE}🔏 Ad-hoc code signing...${NC}"
codesign --force --deep --sign - "$APP_BUNDLE" > /dev/null 2>&1 || true

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

if [ -d "$APP_BUNDLE" ]; then
    echo -e "${GREEN}✅ Build completed successfully! (${DURATION}s)${NC}"
    echo -e "   📦 Location: ${BOLD}$APP_BUNDLE${NC}"
else
    echo -e "${RED}❌ Build finished but $APP_BUNDLE was not found!${NC}"
    exit 1
fi
