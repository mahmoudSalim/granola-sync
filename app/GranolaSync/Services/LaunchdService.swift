import Foundation

class LaunchdService {
    static let shared = LaunchdService()

    private let bridge = PythonBridge()

    func install() async throws {
        _ = try await bridge.status()
    }

    func isInstalled() -> Bool {
        let plistPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/com.granola-sync.export.plist")
        return FileManager.default.fileExists(atPath: plistPath.path)
    }

    func isLoaded() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["list", "com.granola-sync.export"]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        try? process.run()
        process.waitUntilExit()
        return process.terminationStatus == 0
    }
}
