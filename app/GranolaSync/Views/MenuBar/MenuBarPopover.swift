import SwiftUI

struct MenuBarPopover: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text("Granola Sync")
                    .font(.headline)
                Spacer()
                Text("v\(appState.config.version > 0 ? "0.1.0" : "0.1.0")")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider()

            // Status rows
            VStack(spacing: 8) {
                StatusRow(label: "Granola Cache", status: appState.granolaStatus)
                StatusRow(label: "Google Drive", status: appState.driveStatus)
                InfoRow(label: "Last Export", value: appState.lastExportDate)
                InfoRow(label: "Meetings", value: "\(appState.meetingCount) exported")
                InfoRow(label: "Schedule", value: appState.config.schedule.displayName)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Export button
            ExportButton()
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

            // Export output
            if !appState.exportOutput.isEmpty {
                ScrollView {
                    Text(appState.exportOutput)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                }
                .frame(maxHeight: 80)
                .background(.quaternary.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
            }

            Divider()

            // Schedule picker
            VStack(alignment: .leading, spacing: 6) {
                Text("Sync Schedule")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Schedule", selection: Binding(
                    get: { appState.config.schedule },
                    set: { appState.updateSchedule($0) }
                )) {
                    ForEach(SyncSchedule.allCases, id: \.self) { option in
                        Text(option.shortName).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Divider()

            // Recent exports
            if !appState.recentExports.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recent Exports")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 2)

                    ForEach(appState.recentExports.prefix(6)) { export in
                        MeetingRow(entry: export)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                Divider()
            }

            // Bottom actions
            VStack(spacing: 2) {
                BottomButton(title: "Open in Google Drive", icon: "folder", shortcut: "G") {
                    appState.openDriveFolder()
                }
                BottomButton(title: "View Log", icon: "doc.plaintext") {
                    appState.openLog()
                }
                BottomButton(title: "Open Window", icon: "macwindow", shortcut: "O") {
                    NSApp.activate(ignoringOtherApps: true)
                    if let window = NSApp.windows.first(where: { $0.title == "Granola Sync" }) {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
                BottomButton(title: "Refresh", icon: "arrow.clockwise", shortcut: "R") {
                    appState.refresh()
                }

                Divider()
                    .padding(.vertical, 2)

                BottomButton(title: "Quit", icon: "xmark.circle", shortcut: "Q") {
                    NSApp.terminate(nil)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .frame(width: 340)
    }
}
