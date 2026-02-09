import SwiftUI

struct StatusRow: View {
    let label: String
    let status: ConnectionStatus

    private var color: Color {
        switch status {
        case .connected: return .green
        case .disconnected: return .red
        case .checking: return .yellow
        }
    }

    var body: some View {
        HStack {
            Text(label)
                .font(.callout)
            Spacer()
            HStack(spacing: 5) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(status.rawValue)
                    .font(.callout)
                    .foregroundStyle(status == .connected ? Color.primary : Color.red)
            }
        }
    }
}
