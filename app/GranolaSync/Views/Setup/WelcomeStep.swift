import SwiftUI

struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.blue)

            Text("Welcome to Granola Sync")
                .font(.title.bold())

            Text("Automatically export your Granola meetings to Google Drive as beautifully formatted documents.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)

            VStack(alignment: .leading, spacing: 8) {
                FeatureRow(icon: "doc.text.fill", text: "Export meetings as .docx files")
                FeatureRow(icon: "clock.arrow.circlepath", text: "Automatic scheduled exports")
                FeatureRow(icon: "icloud.and.arrow.up", text: "Direct to Google Drive")
            }
            .padding(.top, 8)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 20)
            Text(text)
                .font(.callout)
        }
    }
}
