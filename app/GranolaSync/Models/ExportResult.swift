import Foundation

struct ExportResult: Codable {
    let success: Bool
    let exported: Int
    let skipped: Int
    let apiFetched: Int
    let errors: [String]
    let files: [String]
    let message: String

    enum CodingKeys: String, CodingKey {
        case success, exported, skipped, errors, files, message
        case apiFetched = "api_fetched"
    }
}
