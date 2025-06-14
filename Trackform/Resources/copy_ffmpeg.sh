#!/bin/bash

# Get the path to the built app
APP_PATH="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app"
RESOURCES_PATH="${APP_PATH}/Contents/Resources"

# Create Resources directory if it doesn't exist
mkdir -p "${RESOURCES_PATH}"

# Copy FFmpeg to the app bundle
cp "${SRCROOT}/TrackForm/Resources/ffmpeg" "${RESOURCES_PATH}/"

# Sign FFmpeg with the same identity as the app
codesign --force --sign "${CODE_SIGN_IDENTITY}" "${RESOURCES_PATH}/ffmpeg" 