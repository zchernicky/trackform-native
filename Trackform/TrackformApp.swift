import SwiftUI

/// Main entry point for the Trackform application
@main
struct TrackformApp: App {
    var body: some Scene {
        // Main window configuration
        WindowGroup {
            ContentView()
                .frame(minWidth: 400, minHeight: 500)
        }
        .commands {
            // Remove default app settings menu item
            CommandGroup(replacing: .appSettings) { }
        }
        .windowStyle(.hiddenTitleBar)
        
        // Settings window configuration
        Settings {
            SettingsView()
        }
    }
}

/// View for application settings
struct SettingsView: View {
    // User preference for file access permissions
    @AppStorage("shouldAlwaysAllow") private var shouldAlwaysAllow = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Always Allow File Access", isOn: $shouldAlwaysAllow)
                    .help("When enabled, Trackform will remember file access permissions for future sessions")
            }
        }
        .padding()
        .frame(width: 400, height: 100)
    }
}