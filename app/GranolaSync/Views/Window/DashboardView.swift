import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title
                Text("Dashboard")
                    .font(.largeTitle.bold())
                    .padding(.bottom, 4)

                // Status cards
                HStack(spacing: 16) {
                    StatusCard(
                        title: "Granola",
                        status: appState.granolaStatus,
                        icon: "doc.text.magnifyingglass"
                    )
                    StatusCard(
                        title: "Google Drive",
                        status: appState.driveStatus,
                        icon: "externaldrive.fill.badge.checkmark"
                    )
                    StatusCard(
                        title: "Meetings",
                        value: "\(appState.meetingCount)",
                        icon: "person.3.fill"
                    )
                }

                // Export section
                GroupBox("Quick Export") {
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(label: "Last Export", value: appState.lastExportDate)
                        InfoRow(label: "Schedule", value: appState.config.schedule.displayName)

                        ExportButton()
                            .padding(.top, 4)

                        if !appState.exportOutput.isEmpty {
                            Text(appState.exportOutput)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.quaternary.opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    .padding(4)
                }

                // Recent exports
                if !appState.recentExports.isEmpty {
                    GroupBox("Recent Exports") {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(appState.recentExports.prefix(10)) { entry in
                                MeetingRow(entry: entry)
                            }
                        }
                        .padding(4)
                    }
                }
            }
            .padding(24)
        }
    }
}

struct StatusCard: View {
    let title: String
    var status: ConnectionStatus? = nil
    var value: String? = nil
    let icon: String

    private var color: Color {
        if let status {
            switch status {
            case .connected: return .green
            case .disconnected: return .red
            case .checking: return .yellow
            }
        }
        return .blue
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let status {
                Text(status.rawValue)
                    .font(.callout.bold())
                    .foregroundStyle(status == .connected ? Color.primary : Color.red)
            }
            if let value {
                Text(value)
                    .font(.title2.bold())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
