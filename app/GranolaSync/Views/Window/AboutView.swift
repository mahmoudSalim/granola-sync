import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("Granola Sync")
                .font(.largeTitle.bold())

            Text("v0.1.0")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("Export your Granola meetings to Google Drive as beautifully formatted .docx files.")
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
