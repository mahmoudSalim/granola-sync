import SwiftUI

struct DrivePickerStep: View {
    @EnvironmentObject var appState: AppState
    @State private var detected = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "externaldrive.fill.badge.checkmark")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("Choose Export Folder")
                .font(.title2.bold())

            Text("Select a folder in Google Drive where exported meetings will be saved.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)

            // Current path
            if !appState.config.drivePath.isEmpty {
                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(.blue)
                    Text(appState.config.drivePath)
                        .font(.callout)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .padding(12)
                .background(.quaternary.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            HStack(spacing: 12) {
                Button("Auto-Detect") {
                    detectDrive()
                }
                .buttonStyle(.bordered)

                Button("Browse...") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = false
                    panel.message = "Select your Google Drive export folder"
                    if panel.runModal() == .OK, let url = panel.url {
                        appState.config.drivePath = url.path
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .onAppear {
            if appState.config.drivePath.isEmpty {
                detectDrive()
            }
        }
    }

    private func detectDrive() {
        let cloudStorage = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/CloudStorage")
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: cloudStorage, includingPropertiesForKeys: nil)
        else { return }

        if let gdrive = contents.first(where: { $0.lastPathComponent.hasPrefix("GoogleDrive-") }) {
            let myDrive = gdrive.appendingPathComponent("My Drive")
            if FileManager.default.fileExists(atPath: myDrive.path) {
                appState.config.drivePath = myDrive.path
                detected = true
            }
        }
    }
}
