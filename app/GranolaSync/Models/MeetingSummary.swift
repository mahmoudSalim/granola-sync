import Foundation

struct MeetingSummary: Codable, Identifiable, Hashable {
    let docId: String
    let title: String
    let createdAt: String
    let attendees: [String]
    let durationSeconds: Int?
    let hasTranscript: Bool
    let hasSummary: Bool
    let hasNotes: Bool
    let isExported: Bool
    let exportFilename: String?

    var id: String { docId }

    var date: Date? {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fmt.date(from: createdAt.replacingOccurrences(of: "Z", with: "+00:00"))
            ?? fmt.date(from: createdAt)
    }

    var dateDisplay: String {
        guard let d = date else { return String(createdAt.prefix(10)) }
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        return fmt.string(from: d)
    }

    var durationDisplay: String? {
        guard let secs = durationSeconds else { return nil }
        let mins = secs / 60
        if mins < 60 { return "\(mins)m" }
        return "\(mins / 60)h \(mins % 60)m"
    }

    var attendeeDisplay: String {
        guard !attendees.isEmpty else { return "" }
        if attendees.count <= 3 { return attendees.joined(separator: ", ") }
        return attendees.prefix(3).joined(separator: ", ") + " +\(attendees.count - 3)"
    }

    enum CodingKeys: String, CodingKey {
        case docId = "doc_id"
        case title
        case createdAt = "created_at"
        case attendees
        case durationSeconds = "duration_seconds"
        case hasTranscript = "has_transcript"
        case hasSummary = "has_summary"
        case hasNotes = "has_notes"
        case isExported = "is_exported"
        case exportFilename = "export_filename"
    }
}
