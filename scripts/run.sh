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
DO_BUILD=true
FOREGROUND=false

for arg in "$@"; do
    case "$arg" in
        --release|-r)
            CONFIG="Release"
            ;;
        --debug|-d)
            CONFIG="Debug"
            ;;
        --no-build|-n)
            DO_BUILD=false
            ;;
        --foreground|-f)
            FOREGROUND=true
            ;;
        --help|-h)
            echo "Usage: ./scripts/run.sh [OPTIONS]"
            echo "  --debug, -d       : Build and launch Debug configuration (Default)"
            echo "  --release, -r     : Build and launch Release configuration"
            echo "  --foreground, -f  : Run in terminal foreground (shows live stdout/stderr)"
            echo "  --no-build, -n    : Run existing binary without rebuilding"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown parameter: $arg${NC}"
            exit 1
            ;;
    esac
done

# 1. Terminate any previous instance
"$SCRIPT_DIR/stop.sh"

# 2. Build if requested
if [ "$DO_BUILD" = true ]; then
    if [ "$CONFIG" = "Release" ]; then
        "$SCRIPT_DIR/build.sh" --release
    else
        "$SCRIPT_DIR/build.sh" --debug
    fi
fi

APP_BUNDLE="$PROJECT_ROOT/build/$APP_NAME.app"
BINARY_PATH="$APP_BUNDLE/Contents/MacOS/$APP_NAME"

if [ ! -d "$APP_BUNDLE" ] || [ ! -f "$BINARY_PATH" ]; then
    echo -e "${RED}❌ Application bundle not found: $APP_BUNDLE${NC}"
    echo "Please run './scripts/build.sh' first."
    exit 1
fi

if [ "$FOREGROUND" = true ]; then
    echo -e "${BLUE}🚀 Launching $APP_NAME in foreground (Press Ctrl+C to terminate)...${NC}"
    "$BINARY_PATH"
else
    echo -e "${BLUE}🚀 Launching $APP_NAME...${NC}"
    open "$APP_BUNDLE"

    sleep 0.8
    NEW_PID=$(pgrep -x "$APP_NAME" 2>/dev/null || true)
    if [ -n "$NEW_PID" ]; then
        echo -e "${GREEN}✅ $APP_NAME is up and running! (PID: $NEW_PID)${NC}"
        echo -e "   ℹ️  Check the menu bar and dock for the active status icon."
    else
        echo -e "${YELLOW}⚠️  Application launched; check your menu bar.${NC}"
    fi
fi
