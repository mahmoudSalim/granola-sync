import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var launchdInstalled: Bool = false
    @State private var launchdLoaded: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Settings")
                    .font(.largeTitle.bold())
                    .padding(.bottom, 4)

                // Google Drive path
                GroupBox("Google Drive") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Export destination folder:")
                            .font(.callout)
                        HStack {
                            TextField("Google Drive path", text: $appState.config.drivePath)
                                .textFieldStyle(.roundedBorder)
                            Button("Browse...") {
                                let panel = NSOpenPanel()
                                panel.canChooseFiles = false
                                panel.canChooseDirectories = true
                                panel.allowsMultipleSelection = false
                                if panel.runModal() == .OK, let url = panel.url {
                                    appState.config.drivePath = url.path
                                    appState.saveConfig()
                                    appState.refresh()
                                }
                            }
                        }
                        StatusRow(label: "Status", status: appState.driveStatus)
                    }
                    .padding(4)
                }

                // Export format
                GroupBox("Export Format") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("File format for exported meetings:")
                            .font(.callout)
                        Picker("Format", selection: $appState.config.exportFormat) {
                            Text(".docx (Word)").tag("docx")
                            Text(".md (Markdown)").tag("md")
                            Text(".txt (Plain text)").tag("txt")
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                    .padding(4)
                }

                // Schedule
                GroupBox("Sync Schedule") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How often to automatically export new meetings:")
                            .font(.callout)
                        Picker("Schedule", selection: Binding(
                            get: { appState.config.schedule },
                            set: { appState.updateSchedule($0) }
                        )) {
                            ForEach(SyncSchedule.allCases, id: \.self) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()

                        // Launchd toggle
                        HStack {
                            Toggle("Scheduled sync active", isOn: Binding(
                                get: { launchdLoaded },
                                set: { newValue in
                                    toggleLaunchd(enable: newValue)
                                }
                            ))
                            Spacer()
                            if launchdInstalled {
                                Text(launchdLoaded ? "Running" : "Stopped")
                                    .font(.caption)
                                    .foregroundStyle(launchdLoaded ? .green : .orange)
                            }
                        }
                    }
                    .padding(4)
                }

                // Granola paths
                GroupBox("Granola") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cache path:")
                            .font(.callout)
                        TextField("Cache path", text: $appState.config.granolaCachePath)
                            .textFieldStyle(.roundedBorder)

                        Text("Auth path:")
                            .font(.callout)
                        TextField("Auth path", text: $appState.config.granolaAuthPath)
                            .textFieldStyle(.roundedBorder)

                        StatusRow(label: "Granola", status: appState.granolaStatus)
                    }
                    .padding(4)
                }

                // Notifications
                GroupBox("Notifications") {
                    Toggle("Show notifications after export", isOn: $appState.config.notificationsEnabled)
                        .padding(4)
                }

                // Save button
                HStack {
                    Spacer()
                    Button("Save") {
                        appState.saveConfig()
                        appState.refresh()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding(24)
        }
        .onAppear { checkLaunchd() }
    }

    private func checkLaunchd() {
        let service = LaunchdService.shared
        launchdInstalled = service.isInstalled()
        launchdLoaded = service.isLoaded()
    }

    private func toggleLaunchd(enable: Bool) {
        launchdLoaded = enable
        let bridge = PythonBridge()
        Task {
            _ = try? await bridge.launchd(action: enable ? "install" : "uninstall")
            await MainActor.run { checkLaunchd() }
        }
    }
}
