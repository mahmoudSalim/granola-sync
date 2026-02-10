import Foundation

actor PythonBridge {
    enum BridgeError: Error, LocalizedError {
        case binaryNotFound(searched: [String])
        case executionFailed(String)
        case decodingFailed(String)

        var errorDescription: String? {
            switch self {
            case .binaryNotFound(let searched):
                return "granola-sync binary not found. Searched:\n" + searched.joined(separator: "\n")
            case .executionFailed(let msg): return "Execution failed: \(msg)"
            case .decodingFailed(let msg): return "Decoding failed: \(msg)"
            }
        }
    }

    private func findBinary() -> (URL?, [String]) {
        let home = FileManager.default.homeDirectoryForCurrentUser
        var searched: [String] = []

        // 1. Bundled in .app/Contents/Resources/python-env/
        let bundled = Bundle.main.bundleURL
            .appendingPathComponent("Contents/Resources/python-env/bin/granola-sync")
        searched.append(bundled.path)
        if FileManager.default.isExecutableFile(atPath: bundled.path) {
            return (bundled, searched)
        }

        // 2. Dev mode: .venv in project root (app is at build/X.app)
        let projectRoot = Bundle.main.bundleURL
            .deletingLastPathComponent()  // build/
            .deletingLastPathComponent()  // project root
        let devBinary = projectRoot.appendingPathComponent(".venv/bin/granola-sync")
        searched.append(devBinary.path)
        if FileManager.default.isExecutableFile(atPath: devBinary.path) {
            return (devBinary, searched)
        }

        // 3. Common install locations
        let candidates = [
            home.appendingPathComponent(".local/bin/granola-sync"),
            URL(fileURLWithPath: "/usr/local/bin/granola-sync"),
            URL(fileURLWithPath: "/opt/homebrew/bin/granola-sync"),
        ]
        for url in candidates {
            searched.append(url.path)
            if FileManager.default.isExecutableFile(atPath: url.path) {
                return (url, searched)
            }
        }

        // 4. which fallback
        searched.append("which granola-sync")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["granola-sync"]
        let pipe = Pipe()
        process.standardOutput = pipe
        try? process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !path.isEmpty {
            return (URL(fileURLWithPath: path), searched)
        }

        return (nil, searched)
    }

    private func run(_ arguments: [String]) async throws -> Data {
        let (binary, searched) = findBinary()
        guard let binary else {
            throw BridgeError.binaryNotFound(searched: searched)
        }

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = binary
                process.arguments = arguments

                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = pipe

                do {
                    try process.run()
                    process.waitUntilExit()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()

                    if process.terminationStatus != 0 {
                        let output = String(data: data, encoding: .utf8) ?? "Unknown error"
                        continuation.resume(throwing: BridgeError.executionFailed(output))
                    } else {
                        continuation.resume(returning: data)
                    }
                } catch {
                    continuation.resume(throwing: BridgeError.executionFailed(error.localizedDescription))
                }
            }
        }
    }

    func export() async throws -> ExportResult {
        let data = try await run(["export", "--json"])
        do {
            return try JSONDecoder().decode(ExportResult.self, from: data)
        } catch {
            throw BridgeError.decodingFailed(String(data: data, encoding: .utf8) ?? "")
        }
    }

    func status() async throws -> [String: Any] {
        let data = try await run(["status", "--json"])
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BridgeError.decodingFailed("Expected JSON object")
        }
        return json
    }

    func rawExport() async throws -> String {
        let data = try await run(["export"])
        return String(data: data, encoding: .utf8) ?? ""
    }

    func exportSelected(ids: [String], force: Bool = false) async throws -> ExportResult {
        var args = ["export", "--json", "--ids", ids.joined(separator: ",")]
        if force { args.append("--force") }
        let data = try await run(args)
        do {
            return try JSONDecoder().decode(ExportResult.self, from: data)
        } catch {
            throw BridgeError.decodingFailed(String(data: data, encoding: .utf8) ?? "")
        }
    }

    func listMeetings() async throws -> [MeetingSummary] {
        let data = try await run(["list", "--json"])
        do {
            return try JSONDecoder().decode([MeetingSummary].self, from: data)
        } catch {
            throw BridgeError.decodingFailed(String(data: data, encoding: .utf8) ?? "")
        }
    }

    func showMeeting(id: String) async throws -> MeetingDetail {
        let data = try await run(["show", id, "--json"])
        do {
            return try JSONDecoder().decode(MeetingDetail.self, from: data)
        } catch {
            throw BridgeError.decodingFailed(String(data: data, encoding: .utf8) ?? "")
        }
    }

    func stats() async throws -> SyncStats {
        let data = try await run(["stats", "--json"])
        do {
            return try JSONDecoder().decode(SyncStats.self, from: data)
        } catch {
            throw BridgeError.decodingFailed(String(data: data, encoding: .utf8) ?? "")
        }
    }

    func launchd(action: String) async throws -> String {
        let data = try await run(["launchd", action])
        return String(data: data, encoding: .utf8) ?? ""
    }

    var isAvailable: Bool {
        findBinary().0 != nil
    }
}
