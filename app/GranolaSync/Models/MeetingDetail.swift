import Foundation

struct MeetingDetail: Codable {
    let docId: String
    let title: String
    let createdAt: String
    let attendees: [Attendee]
    let durationSeconds: Int?
    let summaryHtml: String
    let notesMarkdown: String
    let transcript: [TranscriptChunk]
    let isExported: Bool
    let exportFilename: String?

    struct Attendee: Codable, Identifiable {
        let name: String
        let email: String
        var id: String { email.isEmpty ? name : email }
    }

    struct TranscriptChunk: Codable, Identifiable {
        let speaker: String
        let text: String
        let timestamp: String

        var id: String { timestamp + speaker }

        var timeDisplay: String {
            guard !timestamp.isEmpty else { return "" }
            let fmt = ISO8601DateFormatter()
            fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            guard let d = fmt.date(from: timestamp.replacingOccurrences(of: "Z", with: "+00:00"))
                    ?? fmt.date(from: timestamp) else { return "" }
            let tf = DateFormatter()
            tf.dateFormat = "HH:mm:ss"
            return tf.string(from: d)
        }

        var speakerLabel: String {
            speaker == "microphone" ? "You" : "Speaker"
        }
    }

    var date: Date? {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fmt.date(from: createdAt.replacingOccurrences(of: "Z", with: "+00:00"))
            ?? fmt.date(from: createdAt)
    }

    var durationDisplay: String? {
        guard let secs = durationSeconds else { return nil }
        let mins = secs / 60
        if mins < 60 { return "\(mins) minutes" }
        return "\(mins / 60)h \(mins % 60)m"
    }

    enum CodingKeys: String, CodingKey {
        case docId = "doc_id"
        case title
        case createdAt = "created_at"
        case attendees
        case durationSeconds = "duration_seconds"
        case summaryHtml = "summary_html"
        case notesMarkdown = "notes_markdown"
        case transcript
        case isExported = "is_exported"
        case exportFilename = "export_filename"
    }
}
