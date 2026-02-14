import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Dashboard")
                    .font(.largeTitle.bold())
                    .padding(.bottom, 4)

                // Update banner
                if let version = appState.updateAvailable {
                    Button {
                        appState.installUpdate()
                    } label: {
                        HStack {
                            if appState.isUpdating {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(.white)
                            } else {
                                Image(systemName: "arrow.up.circle.fill")
                                    .foregroundStyle(.white)
                            }
                            Text(appState.isUpdating ? "Updating..." : "v\(version) available — click to update")
                                .font(.callout.bold())
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .disabled(appState.isUpdating)
                }

                if !appState.updateMessage.isEmpty && appState.updateAvailable == nil {
                    Text(appState.updateMessage)
                        .font(.callout)
                        .foregroundStyle(.green)
                }

                // Connection status
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
                }

                // Stats cards
                if let stats = appState.syncStats {
                    HStack(spacing: 16) {
                        NumberCard(title: "Meetings", value: "\(stats.totalMeetings)", icon: "person.3.fill", color: .blue)
                        NumberCard(title: "Exported", value: "\(stats.totalExported)", icon: "checkmark.circle.fill", color: .green)
                        NumberCard(title: "Pending", value: "\(stats.totalPending)", icon: "clock.fill", color: .orange)
                        NumberCard(title: "Storage", value: "\(stats.storageUsedMb) MB", icon: "internaldrive.fill", color: .purple)
                    }

                    // Monthly chart
                    if !stats.meetingsByMonth.isEmpty {
                        GroupBox("Meetings per month") {
                            Chart(stats.meetingsByMonth) { item in
                                BarMark(
                                    x: .value("Month", item.month),
                                    y: .value("Count", item.count)
                                )
                                .foregroundStyle(.blue.gradient)
                                .cornerRadius(4)
                            }
                            .frame(height: 180)
                            .padding(4)
                        }
                    }

                    // Weekday + attendees side by side
                    HStack(spacing: 16) {
                        if stats.meetingsByWeekday.contains(where: { $0.count > 0 }) {
                            GroupBox("By weekday") {
                                Chart(stats.meetingsByWeekday) { item in
                                    BarMark(
                                        x: .value("Count", item.count),
                                        y: .value("Day", item.day)
                                    )
                                    .foregroundStyle(.teal.gradient)
                                    .cornerRadius(4)
                                }
                                .frame(height: 180)
                                .padding(4)
                            }
                        }

                        if !stats.topAttendees.isEmpty {
                            GroupBox("Top attendees") {
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(stats.topAttendees.prefix(7)) { att in
                                        HStack {
                                            Text(att.name)
                                                .font(.callout)
                                                .lineLimit(1)
                                            Spacer()
                                            Text("\(att.count)")
                                                .font(.callout.bold())
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .padding(4)
                            }
                        }
                    }

                    // Activity heatmap
                    if !stats.activityHeatmap.isEmpty {
                        GroupBox("Activity (last 90 days)") {
                            ActivityHeatmap(data: stats.activityHeatmap)
                                .padding(4)
                        }
                    }

                    // Duration info
                    if stats.avgDurationMinutes > 0 {
                        HStack(spacing: 16) {
                            NumberCard(
                                title: "Avg duration",
                                value: "\(Int(stats.avgDurationMinutes))m",
                                icon: "timer",
                                color: .indigo
                            )
                            NumberCard(
                                title: "Total time",
                                value: "\(stats.totalDurationHours)h",
                                icon: "clock.fill",
                                color: .teal
                            )
                        }
                    }
                }

                // Quick export
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
            }
            .padding(24)
        }
        .onAppear { appState.loadStats() }
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

struct NumberCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ActivityHeatmap: View {
    let data: [SyncStats.DayCount]

    private let columns = 13 // ~13 weeks in 90 days
    private let rows = 7

    var body: some View {
        let grid = buildGrid()
        HStack(spacing: 3) {
            ForEach(0..<columns, id: \.self) { col in
                VStack(spacing: 3) {
                    ForEach(0..<rows, id: \.self) { row in
                        let idx = col * rows + row
                        if idx < data.count {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(colorFor(count: grid[idx]))
                                .frame(width: 14, height: 14)
                        } else {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.clear)
                                .frame(width: 14, height: 14)
                        }
                    }
                }
            }
        }
        .frame(height: 7 * 17)
    }

    private func buildGrid() -> [Int] {
        data.map(\.count)
    }

    private func colorFor(count: Int) -> Color {
        switch count {
        case 0: return .gray.opacity(0.15)
        case 1: return .green.opacity(0.3)
        case 2: return .green.opacity(0.5)
        case 3: return .green.opacity(0.7)
        default: return .green
        }
    }
}
