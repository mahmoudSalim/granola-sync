import SwiftUI

struct SetupWizardView: View {
    @EnvironmentObject var appState: AppState
    @State private var step = 0

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<5) { i in
                    Circle()
                        .fill(i <= step ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 20)

            // Content
            Group {
                switch step {
                case 0: WelcomeStep()
                case 1: DetectGranolaStep()
                case 2: DrivePickerStep()
                case 3: ScheduleStep()
                case 4: CompleteStep()
                default: EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Navigation
            HStack {
                if step > 0 && step < 4 {
                    Button("Back") { step -= 1 }
                        .buttonStyle(.bordered)
                }
                Spacer()
                if step < 4 {
                    Button(step == 3 ? "Finish Setup" : "Continue") {
                        if step == 3 {
                            appState.saveConfig()
                            appState.needsSetup = false
                            appState.refresh()
                        }
                        step += 1
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(step == 2 && appState.config.drivePath.isEmpty)
                } else {
                    Button("Get Started") {
                        appState.needsSetup = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
        }
        .frame(width: 500, height: 400)
    }
}
