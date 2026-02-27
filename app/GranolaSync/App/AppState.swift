import SwiftUI

@MainActor
class AppState: ObservableObject {
    @Published var config: SyncConfig
    @Published var granolaStatus: ConnectionStatus = .checking
    @Published var driveStatus: ConnectionStatus = .checking
    @Published var lastExportDate: String = "—"
    @Published var meetingCount: Int = 0
    @Published var recentExports: [ManifestEntry] = []
    @Published var isExporting = false
    @Published var exportOutput = ""
    @Published var needsSetup: Bool

    // v1.1 additions
    @Published var meetings: [MeetingSummary] = []
    @Published var syncStats: SyncStats?
    @Published var isLoadingMeetings = false
    @Published var isLoadingStats = false

    // Launchd scheduler
    @Published var launchdInstalled = false
    @Published var launchdLoaded = false

    // Update check
    @Published var updateAvailable: String? = nil
    @Published var updateURL: URL? = nil
    @Published var isUpdating = false
    @Published var isCheckingForUpdates = false
    @Published var updateMessage = ""
    @Published var showUpdateAlert = false
    @Published var updateAlertTitle = ""
    @Published var updateAlertMessage = ""

    private let bridge = PythonBridge()
    private let configService = ConfigService.shared
    private let statusChecker = StatusChecker.shared

    init() {
        let loaded = configService.load()
        self.config = loaded
        self.needsSetup = !configService.configExists
        refresh()
        checkForUpdates()
        ensureLaunchd()
    }

    func refresh() {
        granolaStatus = statusChecker.checkGranolaCache(path: config.granolaCachePath)
        driveStatus = statusChecker.checkDrive(path: config.drivePath)

        let manifest = statusChecker.loadManifest(path: config.manifestPath)
        meetingCount = manifest.count

        let sorted = manifest.sorted { $0.value.exportedAt > $1.value.exportedAt }
        recentExports = Array(sorted.prefix(8).map(\.value))

        if let latest = sorted.first {
            if let date = latest.value.date {
                let fmt = DateFormatter()
                fmt.dateStyle = .medium
                fmt.timeStyle = .short
                lastExportDate = fmt.string(from: date)
            } else {
                lastExportDate = String(latest.value.exportedAt.prefix(10))
            }
        } else {
            lastExportDate = "Never"
        }
    }

    func runExport() {
        guard !isExporting else { return }
        isExporting = true
        exportOutput = ""

        Task {
            do {
                let output = try await bridge.rawExport()
                self.exportOutput = output
            } catch {
                self.exportOutput = "Error: \(error.localizedDescription)"
            }
            self.isExporting = false
            self.refresh()
            self.loadMeetings()
        }
    }

    func exportSelected(ids: [String], force: Bool = false) {
        guard !isExporting else { return }
        isExporting = true
        exportOutput = ""

        Task {
            do {
                let result = try await bridge.exportSelected(ids: ids, force: force)
                self.exportOutput = result.message
            } catch {
                self.exportOutput = "Error: \(error.localizedDescription)"
            }
            self.isExporting = false
            self.refresh()
            self.loadMeetings()
        }
    }

    func loadMeetings() {
        guard !isLoadingMeetings else { return }
        isLoadingMeetings = true

        Task {
            do {
                self.meetings = try await bridge.listMeetings()
            } catch {
                self.meetings = []
            }
            self.isLoadingMeetings = false
        }
    }

    func loadStats() {
        guard !isLoadingStats else { return }
        isLoadingStats = true

        Task {
            do {
                self.syncStats = try await bridge.stats()
            } catch {
                self.syncStats = nil
            }
            self.isLoadingStats = false
        }
    }

    func saveConfig() {
        do {
            try configService.save(config)
        } catch {
            exportOutput = "Failed to save config: \(error.localizedDescription)"
        }
    }

    func updateSchedule(_ schedule: SyncSchedule) {
        config.schedule = schedule
        saveConfig()
        ensureLaunchd()
    }

    func checkLaunchd() {
        let service = LaunchdService.shared
        launchdInstalled = service.isInstalled()
        launchdLoaded = service.isLoaded()
    }

    func ensureLaunchd() {
        Task {
            _ = try? await bridge.launchd(action: "install")
            self.checkLaunchd()
        }
    }

    func toggleLaunchd(enable: Bool) {
        Task {
            _ = try? await bridge.launchd(action: enable ? "install" : "uninstall")
            self.checkLaunchd()
        }
    }

    func openDriveFolder() {
        let expanded = NSString(string: config.drivePath).expandingTildeInPath
        NSWorkspace.shared.open(URL(fileURLWithPath: expanded))
    }

    func openLog() {
        let expanded = NSString(string: config.logPath).expandingTildeInPath
        NSWorkspace.shared.open(URL(fileURLWithPath: expanded))
    }

    /// Silent check on launch — just sets banner state, no alert.
    func checkForUpdates() {
        Task {
            await performUpdateCheck(showAlert: false)
        }
    }

    /// Interactive check from menu item — shows an alert with the result.
    func checkForUpdatesInteractive() {
        guard !isCheckingForUpdates else { return }
        isCheckingForUpdates = true
        Task {
            await performUpdateCheck(showAlert: true)
            self.isCheckingForUpdates = false
        }
    }

    private func performUpdateCheck(showAlert: Bool) async {
        let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

        guard let url = URL(string: "https://api.github.com/repos/mahmoudSalim/granola-sync/releases/latest") else {
            if showAlert {
                self.updateAlertTitle = "Update Check Failed"
                self.updateAlertMessage = "Could not reach GitHub."
                self.showUpdateAlert = true
            }
            return
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tagName = json["tag_name"] as? String,
              let htmlUrl = json["html_url"] as? String else {
            if showAlert {
                self.updateAlertTitle = "Update Check Failed"
                self.updateAlertMessage = "Could not check for updates. Try again later."
                self.showUpdateAlert = true
            }
            return
        }

        let latest = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName

        if latest.compare(current, options: .numeric) == .orderedDescending {
            self.updateAvailable = latest
            self.updateURL = URL(string: htmlUrl)
            if showAlert {
                self.updateAlertTitle = "Update Available"
                self.updateAlertMessage = "Granola Sync v\(latest) is available. You have v\(current)."
                self.showUpdateAlert = true
            }
        } else {
            self.updateAvailable = nil
            self.updateMessage = "You're up to date (v\(current))"
            if showAlert {
                self.updateAlertTitle = "Up to Date"
                self.updateAlertMessage = "You're running the latest version (v\(current))."
                self.showUpdateAlert = true
            }
        }
    }

    @Published var updateReady = false

    func installUpdate() {
        guard !isUpdating else { return }
        isUpdating = true
        updateMessage = "Updating..."
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
        let header = "\n--- Update started at \(timestamp) ---\n"
        exportOutput = header
        appendLog(header)

        Task {
            let success = await runBrewUpgrade()
            if success {
                self.updateMessage = "Updated! Click Relaunch to use the new version."
                self.updateAvailable = nil
                self.updateReady = true
            } else {
                if let url = self.updateURL {
                    NSWorkspace.shared.open(url)
                }
                self.updateMessage = "Brew failed — opened download page."
                self.exportOutput += "Brew update failed. Opened GitHub release page.\n"
            }
            self.isUpdating = false
        }
    }

    func relaunch() {
        let app = "/Applications/Granola Sync.app"
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        task.arguments = ["-c", "sleep 1 && open \"\(app)\""]
        try? task.run()
        NSApp.terminate(nil)
    }

    private func runBrewUpgrade() async -> Bool {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let brewPaths = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]
                guard let brewPath = brewPaths.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else {
                    self?.appendLog("Homebrew not found\n")
                    continuation.resume(returning: false)
                    return
                }

                func runBrew(_ args: [String]) -> (Bool, String) {
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: brewPath)
                    process.arguments = args
                    let pipe = Pipe()
                    process.standardOutput = pipe
                    process.standardError = pipe
                    do {
                        try process.run()
                        process.waitUntilExit()
                        let data = pipe.fileHandleForReading.readDataToEndOfFile()
                        let output = String(data: data, encoding: .utf8) ?? ""
                        return (process.terminationStatus == 0, output)
                    } catch {
                        return (false, error.localizedDescription)
                    }
                }

                self?.appendLog("brew upgrade --cask granola-sync\n")
                let (ok1, out1) = runBrew(["upgrade", "--cask", "granola-sync"])
                self?.appendLog(out1)
                if ok1 {
                    continuation.resume(returning: true)
                    return
                }

                self?.appendLog("brew tap mahmoudSalim/granola\n")
                let (_, tapOut) = runBrew(["tap", "mahmoudSalim/granola"])
                self?.appendLog(tapOut)

                self?.appendLog("brew reinstall --cask granola-sync\n")
                let (ok2, out2) = runBrew(["reinstall", "--cask", "granola-sync"])
                self?.appendLog(out2)
                if ok2 {
                    continuation.resume(returning: true)
                    return
                }

                self?.appendLog("brew uninstall + install --cask granola-sync\n")
                let (_, out3) = runBrew(["uninstall", "--cask", "granola-sync", "--force"])
                self?.appendLog(out3)
                let (ok4, out4) = runBrew(["install", "--cask", "granola-sync"])
                self?.appendLog(out4)
                continuation.resume(returning: ok4)
            }
        }
    }

    nonisolated private func appendLog(_ text: String) {
        // Write to log file
        let logPath = NSString(string: "~/Library/Application Support/GranolaSync/export.log").expandingTildeInPath
        if let handle = FileHandle(forWritingAtPath: logPath) {
            handle.seekToEndOfFile()
            handle.write(Data(text.utf8))
            handle.closeFile()
        } else {
            try? text.write(toFile: logPath, atomically: false, encoding: .utf8)
        }

        DispatchQueue.main.async {
            self.exportOutput += text
        }
    }
}
