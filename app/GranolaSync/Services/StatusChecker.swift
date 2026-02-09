import Foundation

enum ConnectionStatus: String {
    case connected = "Connected"
    case disconnected = "Disconnected"
    case checking = "Checking..."
}

class StatusChecker {
    static let shared = StatusChecker()

    func checkGranolaCache(path: String) -> ConnectionStatus {
        let expanded = NSString(string: path).expandingTildeInPath
        return FileManager.default.fileExists(atPath: expanded) ? .connected : .disconnected
    }

    func checkDrive(path: String) -> ConnectionStatus {
        let expanded = NSString(string: path).expandingTildeInPath
        guard !expanded.isEmpty else { return .disconnected }

        let fm = FileManager.default
        guard fm.fileExists(atPath: expanded) else { return .disconnected }

        let testFile = (expanded as NSString).appendingPathComponent(".granola_sync_test")
        do {
            try "test".write(toFile: testFile, atomically: true, encoding: .utf8)
            try fm.removeItem(atPath: testFile)
            return .connected
        } catch {
            return .disconnected
        }
    }

    func loadManifest(path: String) -> ExportManifest {
        let expanded = NSString(string: path).expandingTildeInPath
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: expanded)),
              let manifest = try? JSONDecoder().decode(ExportManifest.self, from: data)
        else { return [:] }
        return manifest
    }
}
