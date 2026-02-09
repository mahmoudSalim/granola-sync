import SwiftUI

struct BottomButton: View {
    let title: String
    let icon: String
    let shortcut: String?
    let action: () -> Void

    init(title: String, icon: String, shortcut: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.shortcut = shortcut
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 16)
                Text(title)
                Spacer()
                if let shortcut {
                    Text("⌘\(shortcut)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
