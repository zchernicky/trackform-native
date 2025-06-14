# Trackform

A macOS application for editing MP3 metadata using FFmpeg.

## Requirements

- macOS 14.0 or later
- Xcode 15.0 or later

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/trackform-native.git
   cd trackform-native
   ```

2. Open the project in Xcode:
   ```bash
   open Trackform.xcodeproj
   ```

3. Build and run the project (⌘R)

## Usage

1. Launch Trackform
2. Click "Open File" to select an MP3 file
3. Edit the metadata fields as needed
4. Click "Save Metadata" to apply the changes

## Features

- Edit common MP3 metadata fields:
  - Title
  - Artist
  - Year
  - Genre
- Modern SwiftUI interface
- Non-destructive metadata editing
- Progress indicators for long operations
- Self-contained (includes FFmpeg)

## License

This project is licensed under the MIT License - see the LICENSE file for details. 