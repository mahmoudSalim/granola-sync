import SwiftUI

struct MeetingDetailView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let docId: String

    @State private var detail: MeetingDetail?
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Button("Close") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                if let detail {
                    if detail.isExported {
                        Button("Re-Export") {
                            appState.exportSelected(ids: [docId], force: true)
                            dismiss()
                        }
                        .disabled(appState.isExporting)

                        Button("Open in Finder") {
                            if let name = detail.exportFilename {
                                let path = NSString(string: appState.config.drivePath)
                                    .expandingTildeInPath + "/" + name
                                NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
                            }
                        }
                    } else {
                        Button("Export") {
                            appState.exportSelected(ids: [docId])
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(appState.isExporting)
                    }
                }
            }
            .padding(16)

            Divider()

            if isLoading {
                VStack {
                    ProgressView()
                    Text("Loading meeting...")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let detail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        detailHeader(detail)
                        if !detail.summaryHtml.isEmpty {
                            summarySection(detail)
                        }
                        if !detail.notesMarkdown.isEmpty {
                            notesSection(detail)
                        }
                        if !detail.transcript.isEmpty {
                            transcriptSection(detail)
                        }
                    }
                    .padding(24)
                }
            }
        }
        .frame(width: 650, height: 600)
        .onAppear { load() }
    }

    private func load() {
        Task {
            do {
                let bridge = PythonBridge()
                self.detail = try await bridge.showMeeting(id: docId)
            } catch {
                self.error = error.localizedDescription
            }
            self.isLoading = false
        }
    }

    @ViewBuilder
    private func detailHeader(_ d: MeetingDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(d.title)
                .font(.title.bold())

            HStack(spacing: 16) {
                if let date = d.date {
                    Text(date, style: .date)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                if let dur = d.durationDisplay {
                    Text(dur)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                if d.isExported {
                    Text("Exported")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.green.opacity(0.15))
                        .foregroundStyle(.green)
                        .clipShape(Capsule())
                }
            }

            if !d.attendees.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "person.2")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(d.attendees.map(\.name).joined(separator: ", "))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func summarySection(_ d: MeetingDetail) -> some View {
        Divider()
        VStack(alignment: .leading, spacing: 8) {
            Text("Summary")
                .font(.headline)
            // Strip HTML tags for display
            Text(d.summaryHtml
                .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines))
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func notesSection(_ d: MeetingDetail) -> some View {
        Divider()
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
            Text(d.notesMarkdown)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func transcriptSection(_ d: MeetingDetail) -> some View {
        Divider()
        VStack(alignment: .leading, spacing: 8) {
            Text("Transcript (\(d.transcript.count) segments)")
                .font(.headline)

            ForEach(d.transcript) { chunk in
                HStack(alignment: .top, spacing: 8) {
                    if !chunk.timeDisplay.isEmpty {
                        Text(chunk.timeDisplay)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.tertiary)
                            .frame(width: 60, alignment: .trailing)
                    }
                    Text(chunk.speakerLabel)
                        .font(.caption.bold())
                        .foregroundStyle(chunk.speaker == "microphone" ? .blue : .secondary)
                        .frame(width: 55, alignment: .leading)
                    Text(chunk.text)
                        .font(.callout)
                }
            }
        }
    }
}
