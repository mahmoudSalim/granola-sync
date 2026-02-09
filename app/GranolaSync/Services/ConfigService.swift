import Foundation

class ConfigService {
    static let shared = ConfigService()

    func load() -> SyncConfig {
        guard FileManager.default.fileExists(atPath: SyncConfig.configPath.path) else {
            return SyncConfig()
        }
        do {
            let data = try Data(contentsOf: SyncConfig.configPath)
            return try JSONDecoder().decode(SyncConfig.self, from: data)
        } catch {
            return SyncConfig()
        }
    }

    func save(_ config: SyncConfig) throws {
        try FileManager.default.createDirectory(at: SyncConfig.configDir,
                                                  withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(config)
        // Pretty-print the JSON
        let json = try JSONSerialization.jsonObject(with: data)
        let pretty = try JSONSerialization.data(withJSONObject: json,
                                                 options: [.prettyPrinted, .sortedKeys])
        try pretty.write(to: SyncConfig.configPath)
    }

    var configExists: Bool {
        FileManager.default.fileExists(atPath: SyncConfig.configPath.path)
    }
}
