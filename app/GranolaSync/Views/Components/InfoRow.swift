import SwiftUI

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.callout)
            Spacer()
            Text(value)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}
