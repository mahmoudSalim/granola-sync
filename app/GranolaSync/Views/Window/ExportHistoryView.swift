import SwiftUI

struct ExportHistoryView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Export History")
                .font(.largeTitle.bold())
                .padding(24)
                .padding(.bottom, -8)

            if appState.recentExports.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No exports yet")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("Run an export to see your meeting history here.")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(appState.recentExports) { entry in
                        HStack(spacing: 12) {
                            Image(systemName: "doc.text.fill")
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.displayName)
                                    .font(.body)
                                    .lineLimit(1)
                                Text(entry.exportedAt)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}
