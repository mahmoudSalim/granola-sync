import SwiftUI

struct LogViewerView: View {
    @EnvironmentObject var appState: AppState
    @State private var logContent = ""
    @State private var autoScroll = true

    private var logPath: String {
        NSString(string: appState.config.logPath).expandingTildeInPath as String
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Export Log")
                    .font(.largeTitle.bold())
                Spacer()
                Button("Open in Editor") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: logPath))
                }
                .controlSize(.small)
                Button("Clear") { clearLog() }
                    .controlSize(.small)
                Button("Refresh") { loadLog() }
                    .controlSize(.small)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 12)

            if logContent.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.plaintext")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Log is empty")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("Export logs will appear here after the next sync.")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        Text(logContent)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .id("logBottom")
                    }
                    .background(.quaternary.opacity(0.2))
                    .onChange(of: logContent) {
                        if autoScroll {
                            proxy.scrollTo("logBottom", anchor: .bottom)
                        }
                    }
                }
            }
        }
        .onAppear { loadLog() }
    }

    private func loadLog() {
        if FileManager.default.fileExists(atPath: logPath),
           let content = try? String(contentsOfFile: logPath, encoding: .utf8) {
            logContent = content
        } else {
            logContent = ""
        }
    }

    private func clearLog() {
        try? "".write(toFile: logPath, atomically: true, encoding: .utf8)
        logContent = ""
    }
}
