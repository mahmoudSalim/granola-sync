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

    private let bridge = PythonBridge()
    private let configService = ConfigService.shared
    private let statusChecker = StatusChecker.shared

    init() {
        let loaded = configService.load()
        self.config = loaded
        self.needsSetup = !configService.configExists
        refresh()
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
    }

    func openDriveFolder() {
        let expanded = NSString(string: config.drivePath).expandingTildeInPath
        NSWorkspace.shared.open(URL(fileURLWithPath: expanded))
    }

    func openLog() {
        let expanded = NSString(string: config.logPath).expandingTildeInPath
        NSWorkspace.shared.open(URL(fileURLWithPath: expanded))
    }
}
