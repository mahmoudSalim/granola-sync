import Foundation

struct SyncConfig: Codable {
    var version: Int = 1
    var drivePath: String = ""
    var granolaCachePath: String = "~/Library/Application Support/Granola/cache-v3.json"
    var granolaAuthPath: String = "~/Library/Application Support/Granola/supabase.json"
    var manifestPath: String = "~/Library/Application Support/GranolaSync/manifest.json"
    var scheduleInterval: Int = 1_209_600
    var notificationsEnabled: Bool = true
    var exportFormat: String = "docx"
    var apiUrl: String = "https://api.granola.ai/v1"
    var logPath: String = "~/Library/Application Support/GranolaSync/export.log"

    enum CodingKeys: String, CodingKey {
        case version
        case drivePath = "drive_path"
        case granolaCachePath = "granola_cache_path"
        case granolaAuthPath = "granola_auth_path"
        case manifestPath = "manifest_path"
        case scheduleInterval = "schedule_interval"
        case notificationsEnabled = "notifications_enabled"
        case exportFormat = "export_format"
        case apiUrl = "api_url"
        case logPath = "log_path"
    }

    var schedule: SyncSchedule {
        get { SyncSchedule(rawValue: scheduleInterval) ?? .every2Weeks }
        set { scheduleInterval = newValue.rawValue }
    }

    static let configDir: URL = {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/GranolaSync")
    }()

    static let configPath: URL = {
        configDir.appendingPathComponent("config.json")
    }()
}
