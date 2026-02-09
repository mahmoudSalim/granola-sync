import SwiftUI

struct ScheduleStep: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("Export Schedule")
                .font(.title2.bold())

            Text("How often should Granola Sync automatically export new meetings?")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)

            VStack(spacing: 8) {
                ForEach(SyncSchedule.allCases, id: \.self) { option in
                    Button(action: { appState.config.schedule = option }) {
                        HStack {
                            Image(systemName: appState.config.schedule == option
                                  ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(appState.config.schedule == option ? .blue : .secondary)
                            Text(option.displayName)
                                .font(.body)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(appState.config.schedule == option
                                    ? Color.blue.opacity(0.1) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: 300)
        }
    }
}
