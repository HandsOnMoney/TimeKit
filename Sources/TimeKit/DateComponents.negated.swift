import Foundation

extension DateComponents {
    public func negated() -> DateComponents {
        var result = self
        result.era = era.map { -$0 }
        result.year = year.map { -$0 }
        result.month = month.map { -$0 }
        result.day = day.map { -$0 }
        result.hour = hour.map { -$0 }
        result.minute = minute.map { -$0 }
        result.second = second.map { -$0 }
        result.nanosecond = nanosecond.map { -$0 }
        result.weekOfYear = weekOfYear.map { -$0 }
        result.weekOfMonth = weekOfMonth.map { -$0 }
        result.weekday = weekday.map { -$0 }
        result.weekdayOrdinal = weekdayOrdinal.map { -$0 }
        result.quarter = quarter.map { -$0 }
        return result
    }
}
