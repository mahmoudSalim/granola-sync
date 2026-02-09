import SwiftUI

struct ExportButton: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Button(action: appState.runExport) {
            HStack(spacing: 6) {
                if appState.isExporting {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "square.and.arrow.up")
                }
                Text(appState.isExporting ? "Exporting..." : "Export Now")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(appState.isExporting
                  || appState.granolaStatus != .connected
                  || appState.driveStatus != .connected)
    }
}
