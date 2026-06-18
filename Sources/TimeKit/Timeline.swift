import Foundation

public struct Timeline<Period: TimePeriod>: RandomAccessCollection {
    private let cadenceCalc: CadenceCalc

    private var periods: [Period]

    private let makePeriod: (Date, Date) -> Period
    
    public init(cadenceCalc: CadenceCalc, makePeriod: @escaping (Date, Date) -> Period) {
        self.cadenceCalc = cadenceCalc
        self.makePeriod = makePeriod
        self.periods = []
    }
    
    // MARK: RandomAccessCollection conformance
    
    public typealias Index = Int

    public var startIndex: Int { periods.startIndex }
    public var endIndex: Int { periods.endIndex }
    
    public subscript(index: Int) -> Period { periods[index] }
    
    // MARK: Public methods

    public mutating func extend(start: Date, end: Date) -> [Period] {
        var periodsToInsert: [Period] = []
        periodsToInsert.append(contentsOf: extendBack(to: start))
        periodsToInsert.append(contentsOf: extendForward(to: end))
        return periodsToInsert
    }
    
    public mutating func extend(_ date: Date) -> [Period] {
        var periodsToInsert: [Period] = []
        periodsToInsert.append(contentsOf: extendBack(to: date))
        periodsToInsert.append(contentsOf: extendForward(to: date))
        return periodsToInsert
    }
    
    public mutating func change(start: Date, end: Date, of id: Period.ID) throws -> [Period] {
        let newStart = start
        let newEnd = end

        guard let index = periods.firstIndex(where: { $0.id == id }) else {
            throw TimeError.generic(description: "Could not find the period you are trying to change.")
        }

        var periodsToUpdate: [Period] = []

        if index >= 1 {
            let previousPeriodNewEnd = cadenceCalc.end(before: newStart)
            guard periods[index-1].start < previousPeriodNewEnd else {
                throw TimeError.generic(description: "Could not change the start date because the preceding period starts later.")
            }

            periods[index-1].change(start: periods[index-1].start, end: previousPeriodNewEnd)
            periodsToUpdate.append(periods[index-1])
        }

        if index < periods.count-1 {
            let nextPeriodNewStart = cadenceCalc.start(after: newEnd)
            guard nextPeriodNewStart <= periods[index+1].end else {
                throw TimeError.generic(description: "Could not change the end date because the following period ends earlier. Try choosing another date.")
            }
            periods[index+1].change(start: nextPeriodNewStart, end: periods[index+1].end)
            periodsToUpdate.append(periods[index+1])
        }

        periods[index].change(start: newStart, end: newEnd)
        periodsToUpdate.append(periods[index])

        return periodsToUpdate
    }
    
    public mutating func load(_ periods: [Period]) {
        self.periods = periods.sorted(by: { $0.start < $1.start })
    }
    
    public func first(near date: Date) -> Period? {
        periods.first(where: { date >= $0.start && date <= $0.end })
    }
    
    // MARK: internal methods

    mutating func extendBack(to date: Date) -> [Period]{
        var periodsToInsert: [Period] = []

        // Insert periods before the oldest existing period.
        var oldestPeriodStart: Date

        if let existingOldestPeriodStart = periods.first?.start {
            oldestPeriodStart = existingOldestPeriodStart
        } else {
            let (newPeriodStart, newPeriodEnd) = cadenceCalc.current(date: date)
            periodsToInsert.append(makePeriod(newPeriodStart, newPeriodEnd))
            oldestPeriodStart = newPeriodStart
        }

        let oldestTransactionDate = date

        while oldestPeriodStart > oldestTransactionDate {
            let (newPeriodStart, newPeriodEnd) = cadenceCalc.previous(before: oldestPeriodStart)

            oldestPeriodStart = newPeriodStart
            periodsToInsert.append(makePeriod(newPeriodStart, newPeriodEnd))
        }
        
        // Update the array and rebuild the lookup
        periods.insert(contentsOf: periodsToInsert.reversed(), at: 0)

        return periodsToInsert
    }
    
    mutating func extendForward(to date: Date) -> [Period] {
        var periodsToInsert: [Period] = []
        
        // get last existing interval
        // generate periods until today
        var newestPeriodEnd = periods.last?.end ?? Date()

        while newestPeriodEnd < date {
            let (newPeriodStart, newPeriodEnd) = cadenceCalc.next(after: newestPeriodEnd)
            newestPeriodEnd = newPeriodEnd
            periodsToInsert.append(makePeriod(newPeriodStart, newPeriodEnd))
        }
        
        // Update the array and rebuild the lookup
        periods.append(contentsOf: periodsToInsert)

        return periodsToInsert
    }
}
