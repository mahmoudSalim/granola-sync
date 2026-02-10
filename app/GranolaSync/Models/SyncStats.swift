import Foundation

struct SyncStats: Codable {
    let totalMeetings: Int
    let totalExported: Int
    let totalPending: Int
    let meetingsByMonth: [MonthCount]
    let meetingsByWeekday: [WeekdayCount]
    let topAttendees: [AttendeeCount]
    let avgDurationMinutes: Double
    let totalDurationHours: Double
    let storageUsedMb: Double
    let lastExportAt: String?
    let activityHeatmap: [DayCount]

    struct MonthCount: Codable, Identifiable {
        let month: String
        let count: Int
        var id: String { month }
    }

    struct WeekdayCount: Codable, Identifiable {
        let day: String
        let count: Int
        var id: String { day }
    }

    struct AttendeeCount: Codable, Identifiable {
        let name: String
        let count: Int
        var id: String { name }
    }

    struct DayCount: Codable, Identifiable {
        let date: String
        let count: Int
        var id: String { date }
    }

    enum CodingKeys: String, CodingKey {
        case totalMeetings = "total_meetings"
        case totalExported = "total_exported"
        case totalPending = "total_pending"
        case meetingsByMonth = "meetings_by_month"
        case meetingsByWeekday = "meetings_by_weekday"
        case topAttendees = "top_attendees"
        case avgDurationMinutes = "avg_duration_minutes"
        case totalDurationHours = "total_duration_hours"
        case storageUsedMb = "storage_used_mb"
        case lastExportAt = "last_export_at"
        case activityHeatmap = "activity_heatmap"
    }
}
