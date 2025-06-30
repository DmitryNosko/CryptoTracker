enum TimeRangeType: String, CaseIterable {
    case day = "1d"
    case week = "7d"
    case month = "30d"

    var displayName: String {
        switch self {
        case .day: return "Day"
        case .week: return "Week"
        case .month: return "Month"
        }
    }
}
