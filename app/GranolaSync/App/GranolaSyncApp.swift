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

        // Keep app as accessory (no dock icon unless window is open)
        Settings { EmptyView() }
    }
}
