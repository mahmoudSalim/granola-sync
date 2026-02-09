import SwiftUI

struct CompleteStep: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)

            Text("All Set!")
                .font(.title.bold())

            Text("Granola Sync is configured and ready to export your meetings.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)

            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "Export to", value: shortPath(appState.config.drivePath))
                InfoRow(label: "Schedule", value: appState.config.schedule.displayName)
                InfoRow(label: "Notifications", value: appState.config.notificationsEnabled ? "On" : "Off")
            }
            .padding(16)
            .background(.quaternary.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .frame(maxWidth: 350)

            Text("You can change these settings anytime from the Settings tab.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private func shortPath(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return path.hasPrefix(home) ? "~" + path.dropFirst(home.count) : path
    }
}
