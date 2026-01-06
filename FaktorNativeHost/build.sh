#!/bin/bash
# Build script for FaktorNativeHost
# This builds the native messaging host as a standalone executable

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build/NativeHost"
OUTPUT_NAME="FaktorNativeHost"

echo "Building FaktorNativeHost..."
echo "Script directory: $SCRIPT_DIR"
echo "Project directory: $PROJECT_DIR"
echo "Build directory: $BUILD_DIR"

# Create build directory
mkdir -p "$BUILD_DIR"

# Compile the native host
swiftc \
    -O \
    -whole-module-optimization \
    -target arm64-apple-macosx13.0 \
    -target x86_64-apple-macosx13.0 \
    -o "$BUILD_DIR/$OUTPUT_NAME" \
    "$SCRIPT_DIR/main.swift"

# Sign the binary (ad-hoc for development)
codesign -s - "$BUILD_DIR/$OUTPUT_NAME"

echo "Built: $BUILD_DIR/$OUTPUT_NAME"
echo ""
echo "To install to app bundle, copy to:"
echo "  Faktor.app/Contents/MacOS/FaktorNativeHost"
