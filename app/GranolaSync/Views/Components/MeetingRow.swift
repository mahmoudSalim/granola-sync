import SwiftUI

struct MeetingRow: View {
    let entry: ManifestEntry

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "doc.text.fill")
                .font(.caption2)
                .foregroundStyle(.blue.opacity(0.7))
            Text(entry.displayName)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
        }
        .padding(.vertical, 1)
    }
}
