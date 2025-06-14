# Trackform

Trackform is a modern macOS application for managing MP3 metadata (ID3 tags). Built with SwiftUI, it provides a clean and intuitive interface for viewing and editing metadata in your music files.

## Features

- **Metadata Editing**: Edit common MP3 metadata fields:
  - Title
  - Artist
  - Year
  - Genre
- **Modern Interface**: Clean SwiftUI interface with native macOS design
- **Safe Operations**: Non-destructive metadata editing using FFmpeg
- **Self-Contained**: Bundled with FFmpeg for reliable metadata handling
- **File Access**: Secure file handling with proper permissions

## Requirements

- macOS 14.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

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

## System Permissions

When running the app for the first time, you may be prompted to grant additional permissions:

1. **Developer Tools Access**: 
   - Required for running the bundled FFmpeg binary
   - This is a one-time permission that allows the app to execute system-level operations
   - You can safely grant this permission as it's only used for metadata operations

2. **File Access**:
   - The app will request access to files you select
   - You can choose to allow access for the current session only
   - Or enable "Always Allow File Access" in settings for persistent access

## Usage

1. Launch Trackform
2. Click "Open File" to select an MP3 file
3. The app will automatically load existing metadata
4. Edit the metadata fields as needed
5. Click "Save Metadata" to apply the changes
6. Optionally enable "Always Allow File Access" in settings for persistent file access

### Building from Source

1. Ensure you have Xcode 15.0 or later installed
2. Clone the repository
3. Open the project in Xcode
4. Build the project (⌘B)
5. Run the app (⌘R)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.