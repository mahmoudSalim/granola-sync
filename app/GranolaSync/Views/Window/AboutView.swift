import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 128, height: 128)

            Text("Granola Sync")
                .font(.largeTitle.bold())

            Text("v1.1.1")
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

            Text("MIT License")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
