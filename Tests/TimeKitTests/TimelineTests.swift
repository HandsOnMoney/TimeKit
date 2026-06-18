import Testing
import Foundation
@testable import TimeKit

// MARK: - Test fixture

struct TestPeriod: TimePeriod {
    let id: UUID
    var start: Date
    var end: Date

    init(start: Date, end: Date) {
        self.id = UUID()
        self.start = start
        self.end = end
    }

    mutating func change(start: Date, end: Date) {
        self.start = start
        self.end = end
    }
}

// MARK: - Helpers

private func isoDate(year: Int, month: Int, day: Int) -> Date {
    isoCalendar.date(from: DateComponents(year: year, month: month, day: day))!
}

private let isoCalendar: Calendar = {
    var cal = Calendar(identifier: .gregorian)
    cal.locale = Locale(identifier: "en_US_POSIX")
    cal.timeZone = TimeZone(identifier: "UTC")!
    return cal
}()

private func makeMonthTimeline(now: Date? = nil) -> Timeline<TestPeriod> {
    let fixedNow = now ?? isoDate(year: 2024, month: 6, day: 15)
    let calc = CadenceCalc(
        length: .month,
        calendar: isoCalendar,
        gap: DateComponents(day: 1),
        now: { fixedNow }
    )
    return Timeline<TestPeriod>(cadenceCalc: calc, makePeriod: { TestPeriod(start: $0, end: $1) })
}

// MARK: - Timeline Tests

@Suite("Timeline")
struct TimelineTests {

    // MARK: Initial state

    @Test func startsEmpty() {
        // Arrange
        let timeline = makeMonthTimeline()
        // Act & Assert
        #expect(timeline.isEmpty)
        #expect(timeline.count == 0)
    }

    // MARK: extend(_:Date)

    @Test func extendSingleDateCreatesPeriodContainingIt() {
        // Arrange
        var timeline = makeMonthTimeline()
        let target = isoDate(year: 2024, month: 6, day: 15)
        // Act
        _ = timeline.extend(target)
        // Assert
        #expect(timeline.count == 1)
        #expect(timeline[0].start == isoDate(year: 2024, month: 6, day: 1))
        #expect(timeline[0].end == isoDate(year: 2024, month: 6, day: 30))
    }

    @Test func extendSameDateTwiceDoesNotDuplicate() {
        // Arrange
        var timeline = makeMonthTimeline()
        let target = isoDate(year: 2024, month: 6, day: 10)
        // Act
        _ = timeline.extend(target)
        _ = timeline.extend(target)
        // Assert
        #expect(timeline.count == 1)
    }

    // MARK: extend(start:end:)

    @Test func extendRangeCreatesMultiplePeriods() {
        // Arrange
        var timeline = makeMonthTimeline()
        let start = isoDate(year: 2024, month: 4, day: 1)
        let end = isoDate(year: 2024, month: 6, day: 30)
        // Act
        _ = timeline.extend(start: start, end: end)
        // Assert
        #expect(timeline.count == 3)
    }

    @Test func extendRangePeriodsAreSortedByStart() {
        // Arrange
        var timeline = makeMonthTimeline()
        let start = isoDate(year: 2024, month: 1, day: 1)
        let end = isoDate(year: 2024, month: 3, day: 31)
        // Act
        _ = timeline.extend(start: start, end: end)
        // Assert
        for i in 0..<(timeline.count - 1) {
            #expect(timeline[i].start < timeline[i + 1].start)
        }
    }

    @Test func extendRangeReturnsNewlyCreatedPeriods() {
        // Arrange
        var timeline = makeMonthTimeline()
        let start = isoDate(year: 2024, month: 1, day: 1)
        let end = isoDate(year: 2024, month: 3, day: 31)
        // Act
        let inserted = timeline.extend(start: start, end: end)
        // Assert
        #expect(inserted.count == 3)
    }

    @Test func extendRangeAcrossYearBoundaryCreatesCorrectCount() {
        // Arrange
        var timeline = makeMonthTimeline()
        let start = isoDate(year: 2023, month: 11, day: 1)
        let end = isoDate(year: 2024, month: 2, day: 29)
        // Act
        _ = timeline.extend(start: start, end: end)
        // Assert
        #expect(timeline.count == 4)
    }

    // MARK: first(near:)

    @Test func firstNearDateReturnsContainingPeriod() {
        // Arrange
        var timeline = makeMonthTimeline()
        _ = timeline.extend(isoDate(year: 2024, month: 6, day: 15))
        // Act
        let result = timeline.first(near: isoDate(year: 2024, month: 6, day: 20))
        // Assert
        #expect(result != nil)
        #expect(result?.start == isoDate(year: 2024, month: 6, day: 1))
    }

    @Test func firstNearDateOnStartBoundaryReturnsPeriod() {
        // Arrange
        var timeline = makeMonthTimeline()
        _ = timeline.extend(isoDate(year: 2024, month: 6, day: 15))
        // Act
        let result = timeline.first(near: isoDate(year: 2024, month: 6, day: 1))
        // Assert
        #expect(result != nil)
    }

    @Test func firstNearDateOnEndBoundaryReturnsPeriod() {
        // Arrange
        var timeline = makeMonthTimeline()
        _ = timeline.extend(isoDate(year: 2024, month: 6, day: 15))
        // Act
        let result = timeline.first(near: isoDate(year: 2024, month: 6, day: 30))
        // Assert
        #expect(result != nil)
    }

    @Test func firstNearDateOutsideAllPeriodsReturnsNil() {
        // Arrange
        var timeline = makeMonthTimeline()
        _ = timeline.extend(isoDate(year: 2024, month: 6, day: 15))
        // Act
        let result = timeline.first(near: isoDate(year: 2025, month: 1, day: 1))
        // Assert
        #expect(result == nil)
    }

    @Test func firstNearDateInGapBetweenPeriodsReturnsNil() {
        // Arrange
        var timeline = makeMonthTimeline()
        _ = timeline.extend(start: isoDate(year: 2024, month: 1, day: 1),
                             end: isoDate(year: 2024, month: 2, day: 28))
        // The gap day between Jan 31 (end) and Feb 1 (start of next) is handled
        // by the 1-day gap; Jan 31 is the end of Jan period, Feb 1 starts Feb period.
        // So there is no gap day in this configuration, but if we ask about a date
        // before any period it should return nil.
        let result = timeline.first(near: isoDate(year: 2023, month: 12, day: 15))
        // Assert
        #expect(result == nil)
    }

    // MARK: load(_:)

    @Test func loadReplacesExistingPeriods() {
        // Arrange
        var timeline = makeMonthTimeline()
        _ = timeline.extend(isoDate(year: 2024, month: 6, day: 15))
        let replacement = TestPeriod(start: isoDate(year: 2025, month: 1, day: 1),
                                     end: isoDate(year: 2025, month: 1, day: 31))
        // Act
        timeline.load([replacement])
        // Assert
        #expect(timeline.count == 1)
        #expect(timeline[0].start == isoDate(year: 2025, month: 1, day: 1))
    }

    @Test func loadSortsByStartDateAscending() {
        // Arrange
        var timeline = makeMonthTimeline()
        let p1 = TestPeriod(start: isoDate(year: 2024, month: 3, day: 1),
                             end: isoDate(year: 2024, month: 3, day: 31))
        let p2 = TestPeriod(start: isoDate(year: 2024, month: 1, day: 1),
                             end: isoDate(year: 2024, month: 1, day: 31))
        let p3 = TestPeriod(start: isoDate(year: 2024, month: 2, day: 1),
                             end: isoDate(year: 2024, month: 2, day: 29))
        // Act
        timeline.load([p1, p2, p3])
        // Assert
        #expect(timeline[0].start == isoDate(year: 2024, month: 1, day: 1))
        #expect(timeline[1].start == isoDate(year: 2024, month: 2, day: 1))
        #expect(timeline[2].start == isoDate(year: 2024, month: 3, day: 1))
    }

    @Test func loadEmptyArrayClearsTimeline() {
        // Arrange
        var timeline = makeMonthTimeline()
        _ = timeline.extend(isoDate(year: 2024, month: 6, day: 15))
        // Act
        timeline.load([])
        // Assert
        #expect(timeline.isEmpty)
    }

    // MARK: RandomAccessCollection

    @Test func subscriptAccessesPeriodByIndex() {
        // Arrange
        var timeline = makeMonthTimeline()
        _ = timeline.extend(start: isoDate(year: 2024, month: 1, day: 1),
                             end: isoDate(year: 2024, month: 3, day: 31))
        // Act
        let first = timeline[0]
        let last = timeline[timeline.count - 1]
        // Assert
        #expect(first.start < last.start)
    }

    @Test func startAndEndIndicesMatchCount() {
        // Arrange
        var timeline = makeMonthTimeline()
        _ = timeline.extend(start: isoDate(year: 2024, month: 1, day: 1),
                             end: isoDate(year: 2024, month: 3, day: 31))
        // Act & Assert
        #expect(timeline.startIndex == 0)
        #expect(timeline.endIndex == timeline.count)
    }

    // MARK: change(start:end:of:)

    @Test func changePeriodDatesUpdatesThatPeriod() throws {
        // Arrange
        var timeline = makeMonthTimeline()
        _ = timeline.extend(isoDate(year: 2024, month: 6, day: 15))
        let id = timeline[0].id
        let newStart = isoDate(year: 2024, month: 6, day: 5)
        let newEnd = isoDate(year: 2024, month: 6, day: 25)
        // Act
        _ = try timeline.change(start: newStart, end: newEnd, of: id)
        // Assert
        let updated = timeline.first(near: isoDate(year: 2024, month: 6, day: 10))
        #expect(updated?.start == newStart)
        #expect(updated?.end == newEnd)
    }

    @Test func changePeriodAdjustsPreviousPeriodEnd() throws {
        // Arrange
        var timeline = makeMonthTimeline()
        _ = timeline.extend(start: isoDate(year: 2024, month: 5, day: 1),
                             end: isoDate(year: 2024, month: 6, day: 30))
        let juneID = timeline[1].id
        let newJuneStart = isoDate(year: 2024, month: 6, day: 5)
        // Act
        _ = try timeline.change(start: newJuneStart, end: timeline[1].end, of: juneID)
        // Assert: May period end should be day before new June start
        #expect(timeline[0].end == isoDate(year: 2024, month: 6, day: 4))
    }

    @Test func changePeriodAdjustsNextPeriodStart() throws {
        // Arrange
        var timeline = makeMonthTimeline()
        _ = timeline.extend(start: isoDate(year: 2024, month: 5, day: 1),
                             end: isoDate(year: 2024, month: 6, day: 30))
        let mayID = timeline[0].id
        let newMayEnd = isoDate(year: 2024, month: 5, day: 25)
        // Act
        _ = try timeline.change(start: timeline[0].start, end: newMayEnd, of: mayID)
        // Assert: June period start should be day after new May end
        #expect(timeline[1].start == isoDate(year: 2024, month: 5, day: 26))
    }

    @Test func changeReturnsAllModifiedPeriods() throws {
        // Arrange
        var timeline = makeMonthTimeline()
        _ = timeline.extend(start: isoDate(year: 2024, month: 4, day: 1),
                             end: isoDate(year: 2024, month: 6, day: 30))
        let middleID = timeline[1].id
        let newStart = isoDate(year: 2024, month: 5, day: 5)
        let newEnd = isoDate(year: 2024, month: 5, day: 25)
        // Act
        let modified = try timeline.change(start: newStart, end: newEnd, of: middleID)
        // Assert: target + previous + next = 3 periods modified
        #expect(modified.count == 3)
    }

    // MARK: change — error cases

    @Test func changeUnknownIDThrows() {
        // Arrange
        var timeline = makeMonthTimeline()
        _ = timeline.extend(isoDate(year: 2024, month: 6, day: 15))
        let unknownID = UUID()
        // Act & Assert
        #expect(throws: (any Error).self) {
            try timeline.change(
                start: isoDate(year: 2024, month: 6, day: 1),
                end: isoDate(year: 2024, month: 6, day: 30),
                of: unknownID
            )
        }
    }

    @Test func changeStartBeforePreviousPeriodStartThrows() throws {
        // Arrange
        var timeline = makeMonthTimeline()
        _ = timeline.extend(start: isoDate(year: 2024, month: 5, day: 1),
                             end: isoDate(year: 2024, month: 6, day: 30))
        let juneID = timeline[1].id
        // Move June's start to before May 1 (before prev period's start)
        let invalidStart = isoDate(year: 2024, month: 4, day: 30)
        // Act & Assert
        #expect(throws: TimeError.self) {
            try timeline.change(
                start: invalidStart,
                end: timeline[1].end,
                of: juneID
            )
        }
    }

    @Test func changeEndAfterNextPeriodEndThrows() throws {
        // Arrange
        var timeline = makeMonthTimeline()
        _ = timeline.extend(start: isoDate(year: 2024, month: 5, day: 1),
                             end: isoDate(year: 2024, month: 6, day: 30))
        let mayID = timeline[0].id
        // Move May's end to after June's end
        let invalidEnd = isoDate(year: 2024, month: 7, day: 1)
        // Act & Assert
        #expect(throws: TimeError.self) {
            try timeline.change(
                start: timeline[0].start,
                end: invalidEnd,
                of: mayID
            )
        }
    }

    // MARK: extendBack / extendForward internals via public extend

    @Test func extendBackwardFromExistingPeriodPrependsNewPeriods() {
        // Arrange
        var timeline = makeMonthTimeline()
        _ = timeline.extend(isoDate(year: 2024, month: 6, day: 15))
        // Act
        _ = timeline.extend(isoDate(year: 2024, month: 4, day: 1))
        // Assert
        #expect(timeline.count == 3)
        #expect(timeline[0].start == isoDate(year: 2024, month: 4, day: 1))
    }

    @Test func extendForwardFromExistingPeriodAppendsPeriods() {
        // Arrange
        var timeline = makeMonthTimeline()
        _ = timeline.extend(isoDate(year: 2024, month: 6, day: 15))
        // Act
        _ = timeline.extend(isoDate(year: 2024, month: 8, day: 1))
        // Assert
        #expect(timeline.count == 3)
        #expect(timeline.last?.start == isoDate(year: 2024, month: 8, day: 1))
    }

    @Test func noNewPeriodsInsertedWhenDateAlreadyCovered() {
        // Arrange
        var timeline = makeMonthTimeline()
        _ = timeline.extend(start: isoDate(year: 2024, month: 1, day: 1),
                             end: isoDate(year: 2024, month: 12, day: 31))
        let countBefore = timeline.count
        // Act
        let inserted = timeline.extend(isoDate(year: 2024, month: 6, day: 15))
        // Assert
        #expect(inserted.isEmpty)
        #expect(timeline.count == countBefore)
    }
}
