import Foundation

enum SyncSchedule: Int, CaseIterable, Codable {
    case every3Days = 259200
    case everyWeek = 604800
    case every2Weeks = 1209600
    case everyMonth = 2592000

    var displayName: String {
        switch self {
        case .every3Days: return "Every 3 days"
        case .everyWeek: return "Every week"
        case .every2Weeks: return "Every 2 weeks"
        case .everyMonth: return "Every month"
        }
    }

    var shortName: String {
        switch self {
        case .every3Days: return "3 days"
        case .everyWeek: return "Weekly"
        case .every2Weeks: return "Biweekly"
        case .everyMonth: return "Monthly"
        }
    }
}
