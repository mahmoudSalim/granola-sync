import SwiftUI

struct DetectGranolaStep: View {
    @EnvironmentObject var appState: AppState

    private var cacheExists: Bool {
        let path = NSString(string: appState.config.granolaCachePath).expandingTildeInPath
        return FileManager.default.fileExists(atPath: path)
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: cacheExists ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(cacheExists ? .green : .red)

            Text(cacheExists ? "Granola Detected" : "Granola Not Found")
                .font(.title2.bold())

            if cacheExists {
                Text("Found Granola's cache. Your meetings are ready to export.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 380)
            } else {
                Text("Make sure Granola is installed and has been used at least once.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 380)
            }
        }
    }
}
