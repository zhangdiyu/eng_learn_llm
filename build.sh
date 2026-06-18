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

# Compile-time flags. Android targets enable the bundled local LLM
# (Qwen2.5-1.5B). Web targets must keep it disabled — llamadart cannot
# run in a browser and the model would never be available.
ANDROID_DEFINES="--dart-define=ENABLE_LOCAL_LLM=true"
WEB_DEFINES="--dart-define=ENABLE_LOCAL_LLM=false"

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
        $FLUTTER build apk --debug $ANDROID_DEFINES

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
        $FLUTTER build apk --release $ANDROID_DEFINES

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

    web)
        echo "==> Building web release..."
        echo ""

        # Sanity-check that the entrypoint is the real app, not a counter demo
        # left behind by an accidental `flutter create`. This guard prevents
        # the failure mode that shipped the stock demo to gh-pages.
        MAIN_DART="$APP_DIR/lib/main.dart"
        if ! grep -q "DailyEnglishQuestApp" "$MAIN_DART"; then
            echo "Error: $MAIN_DART does not look like the Daily English Quest app."
            echo "       Refusing to build — restore the real lib/main.dart first."
            exit 1
        fi

        # Web template must be present and tracked. Without it, flutter build
        # silently regenerates the stock template (counter demo branding).
        if [ ! -f "$APP_DIR/web/index.html" ] || [ ! -f "$APP_DIR/web/manifest.json" ]; then
            echo "Error: app/web/ is missing or incomplete."
            echo "       Restore index.html + manifest.json before building."
            exit 1
        fi

        BASE_HREF="${BASE_HREF:-/eng_learn_llm/}"

        echo "==> Cleaning previous build state..."
        $FLUTTER clean

        echo ""
        echo "==> Getting dependencies..."
        $FLUTTER pub get

        echo ""
        echo "==> Building web (--base-href=$BASE_HREF)..."
        $FLUTTER build web --release --base-href="$BASE_HREF" $WEB_DEFINES

        WEB_OUT="$APP_DIR/build/web"
        if [ ! -f "$WEB_OUT/main.dart.js" ]; then
            echo "Error: web build output not found at $WEB_OUT"
            exit 1
        fi

        # Post-build guard: confirm the compiled JS contains app-specific
        # strings, not the counter-demo strings. This is the exact check that
        # would have caught the bad gh-pages deploy.
        if ! grep -q "deepseek" "$WEB_OUT/main.dart.js"; then
            echo "Error: built main.dart.js does not contain 'deepseek'."
            echo "       The build appears to be the Flutter counter demo, not the real app."
            echo "       Refusing to publish."
            exit 1
        fi
        if grep -q "Flutter Demo Home Page" "$WEB_OUT/main.dart.js"; then
            echo "Error: built main.dart.js contains 'Flutter Demo Home Page'."
            echo "       The counter demo leaked into the build. Refusing to publish."
            exit 1
        fi

        # Stage a copy under the repo's top-level build/ for convenience.
        rm -rf "$BUILD_DIR/web"
        mkdir -p "$BUILD_DIR"
        cp -R "$WEB_OUT" "$BUILD_DIR/web"

        echo ""
        echo "============================================"
        echo "  Web build successful!"
        echo "  Output: $WEB_OUT"
        echo "  Staged: $BUILD_DIR/web"
        echo ""
        echo "  To deploy to gh-pages:"
        echo "    git checkout gh-pages"
        echo "    rm -rf ./*  # keep .git"
        echo "    cp -R $WEB_OUT/* ."
        echo "    git add -A && git commit -m 'Deploy web' && git push"
        echo "    git checkout main"
        echo "============================================"
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
        $FLUTTER build appbundle --release $ANDROID_DEFINES

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
        echo "Usage: $0 [debug|release|appbundle|web|clean|doctor]"
        echo ""
        echo "  debug      Build debug APK (default)"
        echo "  release    Build release APK"
        echo "  appbundle  Build release Android App Bundle"
        echo "  web        Build release web bundle (gh-pages ready)"
        echo "  clean      Remove build artifacts"
        echo "  doctor     Run flutter doctor"
        exit 1
        ;;
esac
