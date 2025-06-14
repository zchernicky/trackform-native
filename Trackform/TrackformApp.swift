import SwiftUI

@main
struct TrackformApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 400, minHeight: 500)
        }
        .commands {
            CommandGroup(replacing: .appSettings) { }
        }
        .windowStyle(.hiddenTitleBar)
        
        Settings {
            SettingsView()
        }
    }
}

struct SettingsView: View {
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