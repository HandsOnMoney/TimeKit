import Foundation

public struct CadenceCalc: Sendable {
    let cadence: Cadence
    public let gap: DateComponents?
    private let calendar: Calendar

    private let now: @Sendable () -> Date
    public init(
        length: Cadence,
        calendar: Calendar = .current,
        gap: DateComponents? = DateComponents(day: 1),
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.now = now
        self.cadence = length
        self.gap = gap
        self.calendar = calendar
    }

    public func interval(containing date: Date, forward: Bool) -> (Date, Date) {
        switch cadence {
        case .days(let flexPeriodDuration):
            if forward {
                let start = calendar.startOfDay(for: date)
                let exclusiveEnd = calendar.date(byAdding: .day, value: flexPeriodDuration, to: start)!
                return (start, calendar.startOfDay(for: end(before: exclusiveEnd)))
            } else {
                let end = calendar.startOfDay(for: date)
                let start = calendar.date(byAdding: .day, value: -flexPeriodDuration, to: end)!
                return (start, end)
            }

        case .week:
            let interval = calendar.dateInterval(of: .weekOfYear, for: date)!
            return (interval.start, end(before: interval.end))

        case .month:
            let interval = calendar.dateInterval(of: .month, for: date)!
            return (interval.start, end(before: interval.end))

        case .quarter:
            let comps = calendar.dateComponents([.year, .month], from: date)
            let quarter = ((comps.month! - 1) / 3) * 3 + 1
            let startComps = DateComponents(year: comps.year, month: quarter, day: 1)
            let start = calendar.date(from: startComps)!
            let exclusiveEnd = calendar.date(byAdding: .month, value: 3, to: start)!
            return (start, end(before: exclusiveEnd))

        case .year:
            let interval = calendar.dateInterval(of: .year, for: date)!
            return (interval.start, end(before: interval.end))
        }
    }

    public func current(date: Date? = nil) -> (Date, Date) {
        let dateToUse: Date
        if let date {
            dateToUse = date
        } else {
            dateToUse = now()
        }

        return interval(containing: dateToUse, forward: true)
    }

    public func end(before start: Date) -> Date {
        guard let gap else { return start }
        return calendar.date(byAdding: gap.negated(), to: start)!
    }

    public func start(after end: Date) -> Date {
        guard let gap else { return end }
        return calendar.date(byAdding: gap, to: end)!
    }

    public func previous(before start: Date) -> (Date, Date) {
        let probe = gap != nil ? end(before: start) : start.addingTimeInterval(-1)
        return interval(containing: probe, forward: false)
    }

    public func next(after end: Date) -> (Date, Date) {
        let probe = gap != nil ? start(after: end) : end.addingTimeInterval(1)
        return interval(containing: probe, forward: true)
    }
}
