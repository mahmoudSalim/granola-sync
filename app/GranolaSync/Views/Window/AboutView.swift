import SwiftUI

struct AboutView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 128, height: 128)

            Text("Granola Sync")
                .font(.largeTitle.bold())

            Text("v1.1.3")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("Export your Granola meetings to Google Drive as .docx, .md, or .txt files.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            Divider()
                .frame(maxWidth: 300)

            VStack(spacing: 8) {
                Link("GitHub Repository",
                     destination: URL(string: "https://github.com/mahmoudsalim/granola-sync")!)
                Link("Report an Issue",
                     destination: URL(string: "https://github.com/mahmoudsalim/granola-sync/issues")!)
            }
            .font(.callout)

            if let version = appState.updateAvailable {
                Button {
                    appState.installUpdate()
                } label: {
                    HStack(spacing: 6) {
                        if appState.isUpdating {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text(appState.isUpdating ? "Updating..." : "Update to v\(version)")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(appState.isUpdating)
            } else {
                Button("Check for Updates") {
                    appState.checkForUpdates()
                }
            }

            if !appState.updateMessage.isEmpty {
                Text(appState.updateMessage)
                    .font(.caption)
                    .foregroundStyle(appState.updateAvailable == nil ? .green : .secondary)
            }

            Text("MIT License")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
