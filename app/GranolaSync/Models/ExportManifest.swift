import Foundation

struct ManifestEntry: Codable, Identifiable {
    let filename: String
    let exportedAt: String

    var id: String { filename }

    var displayName: String {
        filename.replacingOccurrences(of: ".docx", with: "")
    }

    var date: Date? {
        ISO8601DateFormatter().date(from: exportedAt) ?? {
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
            return fmt.date(from: exportedAt)
        }()
    }

    enum CodingKeys: String, CodingKey {
        case filename
        case exportedAt = "exported_at"
    }
}

typealias ExportManifest = [String: ManifestEntry]
