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
    // User preferences
    @AppStorage("shouldAlwaysAllow") private var shouldAlwaysAllow = false
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        TabView {
            // General Settings
            Form {
                Section {
                    Toggle("Always Allow File Access", isOn: $shouldAlwaysAllow)
                        .help("When enabled, Trackform will remember file access permissions for future sessions")
                } header: {
                    Text("File Access")
                } footer: {
                    Text("This setting allows Trackform to remember which files you've granted access to.")
                }
            }
            .tabItem {
                Label("General", systemImage: "gear")
            }
            
            // About Section
            VStack(spacing: 20) {
                Image(systemName: "waveform")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                
                Text("Trackform")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Version 1.0.0")
                    .foregroundStyle(.secondary)
                
                Text("A modern MP3 metadata editor")
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 20) {
                    Link(destination: URL(string: "https://github.com/zchernicky/trackform-native")!) {
                        Label("GitHub", systemImage: "link")
                    }
                    .buttonStyle(.plain)
                    
                    Link(destination: URL(string: "https://github.com/zchernicky/trackform-native/issues")!) {
                        Label("Report Issue", systemImage: "exclamationmark.bubble")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 10)
            }
            .padding()
            .tabItem {
                Label("About", systemImage: "info.circle")
            }
        }
        .frame(width: 450, height: 300)
        .padding()
    }
}

#Preview {
    SettingsView()
}