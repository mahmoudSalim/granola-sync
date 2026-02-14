import SwiftUI

@main
struct GranolaSyncApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        // Main window
        WindowGroup("Granola Sync") {
            MainWindow()
                .environmentObject(delegate.appState ?? AppState())
        }
        .defaultSize(width: 700, height: 500)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    delegate.appState?.checkForUpdatesInteractive()
                }
                .keyboardShortcut("U", modifiers: [.command])
                .disabled(delegate.appState?.isCheckingForUpdates == true)
            }
        }

        // Settings window (Cmd+, or app menu > Settings)
        Settings {
            SettingsView()
                .environmentObject(delegate.appState ?? AppState())
                .frame(minWidth: 500, minHeight: 400)
        }
    }
}
