#!/usr/bin/env bash
#
# Daily English Quest - Android Build Script
#
# This script builds the Android APK for the Daily English Quest app.
#
# Usage:
#   ./build.sh              # Build debug APK
#   ./build.sh release      # Build release APK
#   ./build.sh clean        # Clean build artifacts
#
# Prerequisites:
#   - Flutter SDK (installed at FLUTTER_ROOT or ./flutter)
#   - Android SDK
#   - Java JDK

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$SCRIPT_DIR/app"
BUILD_DIR="$SCRIPT_DIR/build"
FLUTTER=""

# Locate Flutter SDK
find_flutter() {
    if [ -n "${FLUTTER_ROOT:-}" ] && [ -x "$FLUTTER_ROOT/bin/flutter" ]; then
        FLUTTER="$FLUTTER_ROOT/bin/flutter"
    elif [ -x "$SCRIPT_DIR/flutter/bin/flutter" ]; then
        FLUTTER="$SCRIPT_DIR/flutter/bin/flutter"
    elif command -v flutter &>/dev/null; then
        FLUTTER="flutter"
    else
        echo "Error: Flutter SDK not found."
        echo ""
        echo "Set FLUTTER_ROOT to the Flutter SDK path, or place it at:"
        echo "  $SCRIPT_DIR/flutter"
        echo ""
        echo "To install Flutter:"
        echo "  macOS:  brew install --cask flutter"
        echo "  Linux:  snap install flutter --classic"
        echo "  Manual: https://docs.flutter.dev/get-started/install"
        exit 1
    fi
}

find_flutter
echo "==> Using Flutter: $FLUTTER"
echo "==> Flutter version: $($FLUTTER --version 2>/dev/null | head -1 || echo 'unknown')"

# Change to app directory
cd "$APP_DIR"

# Parse command
CMD="${1:-debug}"

case "$CMD" in
    clean)
        echo "==> Cleaning build artifacts..."
        $FLUTTER clean
        rm -rf "$BUILD_DIR"
        echo "==> Clean complete."
        exit 0
        ;;

    doctor)
        echo "==> Running flutter doctor..."
        $FLUTTER doctor -v
        exit 0
        ;;

    debug)
        echo "==> Building debug APK..."
        echo ""

        # Get dependencies
        echo "==> Getting dependencies..."
        $FLUTTER pub get

        # Run static analysis
        echo ""
        echo "==> Running static analysis..."
        $FLUTTER analyze || echo "==> Warning: analysis found issues (continuing)"

        # Build APK
        echo ""
        echo "==> Building APK..."
        $FLUTTER build apk --debug

        # Copy to build output
        mkdir -p "$BUILD_DIR"
        APK_PATH="$APP_DIR/build/app/outputs/flutter-apk/app-debug.apk"
        if [ -f "$APK_PATH" ]; then
            cp "$APK_PATH" "$BUILD_DIR/daily-english-quest-debug.apk"
            echo ""
            echo "============================================"
            echo "  Build successful!"
            echo "  APK: $BUILD_DIR/daily-english-quest-debug.apk"
            echo "============================================"
        else
            echo "Error: APK not found at $APK_PATH"
            exit 1
        fi
        ;;

    release)
        echo "==> Building release APK..."
        echo ""

        # Get dependencies
        echo "==> Getting dependencies..."
        $FLUTTER pub get

        # Run static analysis
        echo ""
        echo "==> Running static analysis..."
        $FLUTTER analyze || echo "==> Warning: analysis found issues (continuing)"

        # Run tests
        echo ""
        echo "==> Running tests..."
        $FLUTTER test || echo "==> Warning: some tests failed (continuing)"

        # Build APK
        echo ""
        echo "==> Building release APK..."
        $FLUTTER build apk --release

        # Copy to build output
        mkdir -p "$BUILD_DIR"
        APK_PATH="$APP_DIR/build/app/outputs/flutter-apk/app-release.apk"
        if [ -f "$APK_PATH" ]; then
            cp "$APK_PATH" "$BUILD_DIR/daily-english-quest-release.apk"
            echo ""
            echo "============================================"
            echo "  Build successful!"
            echo "  APK: $BUILD_DIR/daily-english-quest-release.apk"
            echo "============================================"
        else
            echo "Error: APK not found at $APK_PATH"
            exit 1
        fi
        ;;

    appbundle)
        echo "==> Building release App Bundle..."
        echo ""

        echo "==> Getting dependencies..."
        $FLUTTER pub get

        echo ""
        echo "==> Running static analysis..."
        $FLUTTER analyze || echo "==> Warning: analysis found issues (continuing)"

        echo ""
        echo "==> Building App Bundle..."
        $FLUTTER build appbundle --release

        mkdir -p "$BUILD_DIR"
        BUNDLE_PATH="$APP_DIR/build/app/outputs/bundle/release/app-release.aab"
        if [ -f "$BUNDLE_PATH" ]; then
            cp "$BUNDLE_PATH" "$BUILD_DIR/daily-english-quest-release.aab"
            echo ""
            echo "============================================"
            echo "  Build successful!"
            echo "  AAB: $BUILD_DIR/daily-english-quest-release.aab"
            echo "============================================"
        else
            echo "Error: App Bundle not found at $BUNDLE_PATH"
            exit 1
        fi
        ;;

    *)
        echo "Usage: $0 [debug|release|appbundle|clean|doctor]"
        echo ""
        echo "  debug      Build debug APK (default)"
        echo "  release    Build release APK"
        echo "  appbundle  Build release Android App Bundle"
        echo "  clean      Remove build artifacts"
        echo "  doctor     Run flutter doctor"
        exit 1
        ;;
esac
