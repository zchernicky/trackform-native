#!/bin/bash

# Script to copy and sign FFmpeg binary for the Trackform app bundle
# This script is run during the build process to ensure FFmpeg is properly bundled

# Exit on any error
set -e

# Get the path to the built app
APP_PATH="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app"
RESOURCES_PATH="${APP_PATH}/Contents/Resources"

# Verify required environment variables
if [ -z "$BUILT_PRODUCTS_DIR" ] || [ -z "$PRODUCT_NAME" ]; then
    echo "Error: Required environment variables are not set"
    exit 1
fi

# Create Resources directory if it doesn't exist
echo "Creating Resources directory..."
mkdir -p "${RESOURCES_PATH}"

# Copy FFmpeg to the app bundle
echo "Copying FFmpeg binary..."
cp "${SRCROOT}/TrackForm/Resources/ffmpeg" "${RESOURCES_PATH}/"

# Sign FFmpeg with the same identity as the app
if [ -n "$CODE_SIGN_IDENTITY" ]; then
    echo "Signing FFmpeg binary..."
    codesign --force --sign "${CODE_SIGN_IDENTITY}" "${RESOURCES_PATH}/ffmpeg"
else
    echo "Warning: No code signing identity found, FFmpeg will not be signed"
fi

echo "FFmpeg setup complete" 