import Testing
import Foundation
@testable import TimeKit

// MARK: - Helpers

private func date(year: Int, month: Int, day: Int, calendar: Calendar = .iso) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day))!
}

private extension Calendar {
    static let iso: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_US_POSIX")
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()
}

// MARK: - CadenceCalc Tests

@Suite("CadenceCalc")
struct CadenceCalcTests {

    // MARK: interval(containing:forward:) — .month

    @Test func monthForwardStartsOnFirstOfMonth() {
        // Arrange
        let calc = CadenceCalc(length: .month, calendar: .iso, gap: DateComponents(day: 1))
        let midMonth = date(year: 2024, month: 3, day: 15)
        // Act
        let (start, end) = calc.interval(containing: midMonth, forward: true)
        // Assert
        #expect(start == date(year: 2024, month: 3, day: 1))
        #expect(end == date(year: 2024, month: 3, day: 31))
    }

    @Test func monthForwardEndsOnLastDayOfMonth() {
        // Arrange
        let calc = CadenceCalc(length: .month, calendar: .iso, gap: DateComponents(day: 1))
        let midMonth = date(year: 2024, month: 3, day: 15)
        // Act
        let (start, end) = calc.interval(containing: midMonth, forward: true)
        // Assert
        #expect(start == date(year: 2024, month: 3, day: 1))
        #expect(end == date(year: 2024, month: 3, day: 31))
    }

    @Test func monthForwardFebruary28InNonLeapYear() {
        // Arrange
        let calc = CadenceCalc(length: .month, calendar: .iso, gap: DateComponents(day: 1))
        let feb = date(year: 2023, month: 2, day: 10)
        // Act
        let (start, end) = calc.interval(containing: feb, forward: true)
        // Assert
        #expect(start == date(year: 2023, month: 2, day: 1))
        #expect(end == date(year: 2023, month: 2, day: 28))
    }

    @Test func monthForwardFebruary29InLeapYear() {
        // Arrange
        let calc = CadenceCalc(length: .month, calendar: .iso, gap: DateComponents(day: 1))
        let feb = date(year: 2024, month: 2, day: 10)
        // Act
        let (start, end) = calc.interval(containing: feb, forward: true)
        // Assert
        #expect(start == date(year: 2024, month: 2, day: 1))
        #expect(end == date(year: 2024, month: 2, day: 29))
    }

    // MARK: interval(containing:forward:) — .week

    @Test func weekForwardStartsOnSunday() {
        // Arrange
        var cal = Calendar.iso
        cal.firstWeekday = 1 // Sunday
        let calc = CadenceCalc(length: .week, calendar: cal, gap: DateComponents(day: 1))
        let wednesday = date(year: 2024, month: 3, day: 13, calendar: cal)
        // Act
        let (start, end) = calc.interval(containing: wednesday, forward: true)
        // Assert
        let weekday = cal.component(.weekday, from: start)
        #expect(weekday == cal.firstWeekday)
        #expect(end == date(year: 2024, month: 3, day: 16))
    }

    @Test func weekForwardEndIsStartPlusSixDays() {
        // Arrange
        let calc = CadenceCalc(length: .week, calendar: .iso, gap: DateComponents(day: 1))
        let anyDay = date(year: 2024, month: 3, day: 13)
        // Act
        let (start, end) = calc.interval(containing: anyDay, forward: true)
        // Assert
        let diff = Calendar.iso.dateComponents([.day], from: start, to: end).day!
        #expect(diff == 6)
    }

    // MARK: interval(containing:forward:) — .days(count:)

    @Test func daysForwardSpansCorrectNumberOfDays() {
        // Arrange
        let calc = CadenceCalc(length: .days(count: 14), calendar: .iso, gap: DateComponents(day: 1))
        let start = date(year: 2024, month: 1, day: 1)
        // Act
        let (periodStart, periodEnd) = calc.interval(containing: start, forward: true)
        // Assert
        let diff = Calendar.iso.dateComponents([.day], from: periodStart, to: periodEnd).day!
        #expect(diff == 13) // 14-day span minus 1-day gap
    }

    @Test func daysBackwardEndsAtStartOfProvidedDay() {
        // Arrange
        let calc = CadenceCalc(length: .days(count: 7), calendar: .iso, gap: DateComponents(day: 1))
        let anchor = date(year: 2024, month: 1, day: 10)
        // Act
        let (start, end) = calc.interval(containing: anchor, forward: false)
        // Assert
        #expect(start == date(year: 2024, month: 1, day: 3))
        #expect(end == anchor)
    }

    @Test func daysBackwardStartsSevenDaysEarlier() {
        // Arrange
        let calc = CadenceCalc(length: .days(count: 7), calendar: .iso, gap: DateComponents(day: 1))
        let anchor = date(year: 2024, month: 1, day: 10)
        // Act
        let (start, end) = calc.interval(containing: anchor, forward: false)
        // Assert
        #expect(start == date(year: 2024, month: 1, day: 3))
        #expect(end == anchor)
    }

    // MARK: interval(containing:forward:) — .quarter

    @Test func quarterForwardQ1StartsJanuary1() {
        // Arrange
        let calc = CadenceCalc(length: .quarter, calendar: .iso, gap: DateComponents(day: 1))
        let feb = date(year: 2024, month: 2, day: 15)
        // Act
        let (start, end) = calc.interval(containing: feb, forward: true)
        // Assert
        #expect(start == date(year: 2024, month: 1, day: 1))
        #expect(end == date(year: 2024, month: 3, day: 31))
    }

    @Test func quarterForwardQ2StartsApril1() {
        // Arrange
        let calc = CadenceCalc(length: .quarter, calendar: .iso, gap: DateComponents(day: 1))
        let may = date(year: 2024, month: 5, day: 1)
        // Act
        let (start, end) = calc.interval(containing: may, forward: true)
        // Assert
        #expect(start == date(year: 2024, month: 4, day: 1))
        #expect(end == date(year: 2024, month: 6, day: 30))
    }

    @Test func quarterForwardQ3StartsJuly1() {
        // Arrange
        let calc = CadenceCalc(length: .quarter, calendar: .iso, gap: DateComponents(day: 1))
        let aug = date(year: 2024, month: 8, day: 15)
        // Act
        let (start, end) = calc.interval(containing: aug, forward: true)
        // Assert
        #expect(start == date(year: 2024, month: 7, day: 1))
        #expect(end == date(year: 2024, month: 9, day: 30))
    }

    @Test func quarterForwardQ4StartsOctober1() {
        // Arrange
        let calc = CadenceCalc(length: .quarter, calendar: .iso, gap: DateComponents(day: 1))
        let nov = date(year: 2024, month: 11, day: 5)
        // Act
        let (start, end) = calc.interval(containing: nov, forward: true)
        // Assert
        #expect(start == date(year: 2024, month: 10, day: 1))
        #expect(end == date(year: 2024, month: 12, day: 31))
    }

    // MARK: interval(containing:forward:) — .year

    @Test func yearForwardStartsJanuary1() {
        // Arrange
        let calc = CadenceCalc(length: .year, calendar: .iso, gap: DateComponents(day: 1))
        let mid = date(year: 2024, month: 6, day: 15)
        // Act
        let (start, end) = calc.interval(containing: mid, forward: true)
        // Assert
        #expect(start == date(year: 2024, month: 1, day: 1))
        #expect(end == date(year: 2024, month: 12, day: 31))
    }

    @Test func yearForwardEndsDecember31() {
        // Arrange
        let calc = CadenceCalc(length: .year, calendar: .iso, gap: DateComponents(day: 1))
        let mid = date(year: 2024, month: 6, day: 15)
        // Act
        let (start, end) = calc.interval(containing: mid, forward: true)
        // Assert
        #expect(start == date(year: 2024, month: 1, day: 1))
        #expect(end == date(year: 2024, month: 12, day: 31))
    }

    // MARK: end(before:) and start(after:)

    @Test func endBeforeSubtractsGap() {
        // Arrange
        let calc = CadenceCalc(length: .month, calendar: .iso, gap: DateComponents(day: 1))
        let april1 = date(year: 2024, month: 4, day: 1)
        // Act
        let result = calc.end(before: april1)
        // Assert
        #expect(result == date(year: 2024, month: 3, day: 31))
    }

    @Test func endBeforeWithNoGapReturnsSameDate() {
        // Arrange
        let calc = CadenceCalc(length: .month, calendar: .iso, gap: nil)
        let april1 = date(year: 2024, month: 4, day: 1)
        // Act
        let result = calc.end(before: april1)
        // Assert
        #expect(result == april1)
    }

    @Test func startAfterAddsGap() {
        // Arrange
        let calc = CadenceCalc(length: .month, calendar: .iso, gap: DateComponents(day: 1))
        let march31 = date(year: 2024, month: 3, day: 31)
        // Act
        let result = calc.start(after: march31)
        // Assert
        #expect(result == date(year: 2024, month: 4, day: 1))
    }

    @Test func startAfterWithNoGapReturnsSameDate() {
        // Arrange
        let calc = CadenceCalc(length: .month, calendar: .iso, gap: nil)
        let march31 = date(year: 2024, month: 3, day: 31)
        // Act
        let result = calc.start(after: march31)
        // Assert
        #expect(result == march31)
    }

    // MARK: previous(before:) and next(after:)

    @Test func previousMonthBeforeAprilIsMarch() {
        // Arrange
        let calc = CadenceCalc(length: .month, calendar: .iso, gap: DateComponents(day: 1))
        let april1 = date(year: 2024, month: 4, day: 1)
        // Act
        let (start, end) = calc.previous(before: april1)
        // Assert
        #expect(start == date(year: 2024, month: 3, day: 1))
        #expect(end == date(year: 2024, month: 3, day: 31))
    }

    @Test func nextMonthAfterMarchIsApril() {
        // Arrange
        let calc = CadenceCalc(length: .month, calendar: .iso, gap: DateComponents(day: 1))
        let march31 = date(year: 2024, month: 3, day: 31)
        // Act
        let (start, end) = calc.next(after: march31)
        // Assert
        #expect(start == date(year: 2024, month: 4, day: 1))
        #expect(end == date(year: 2024, month: 4, day: 30))
    }

    @Test func previousYearBeforeJan2024IsYear2023() {
        // Arrange
        let calc = CadenceCalc(length: .year, calendar: .iso, gap: DateComponents(day: 1))
        let jan1_2024 = date(year: 2024, month: 1, day: 1)
        // Act
        let (start, end) = calc.previous(before: jan1_2024)
        // Assert
        #expect(start == date(year: 2023, month: 1, day: 1))
        #expect(end == date(year: 2023, month: 12, day: 31))
    }

    @Test func nextYearAfterDec2023Is2024() {
        // Arrange
        let calc = CadenceCalc(length: .year, calendar: .iso, gap: DateComponents(day: 1))
        let dec31_2023 = date(year: 2023, month: 12, day: 31)
        // Act
        let (start, end) = calc.next(after: dec31_2023)
        // Assert
        #expect(start == date(year: 2024, month: 1, day: 1))
        #expect(end == date(year: 2024, month: 12, day: 31))
    }

    // MARK: current(date:)

    @Test func currentUsesInjectedNowWhenNoDateProvided() {
        // Arrange
        let fixedDate = date(year: 2024, month: 6, day: 15)
        let calc = CadenceCalc(length: .month, calendar: .iso, gap: DateComponents(day: 1), now: { fixedDate })
        // Act
        let (start, end) = calc.current()
        // Assert
        #expect(start == date(year: 2024, month: 6, day: 1))
        #expect(end == date(year: 2024, month: 6, day: 30))
    }

    @Test func currentUsesProvidedDateOverNowClosure() {
        // Arrange
        let nowDate = date(year: 2024, month: 6, day: 15)
        let overrideDate = date(year: 2024, month: 9, day: 5)
        let calc = CadenceCalc(length: .month, calendar: .iso, gap: DateComponents(day: 1), now: { nowDate })
        // Act
        let (start, end) = calc.current(date: overrideDate)
        // Assert
        #expect(start == date(year: 2024, month: 9, day: 1))
        #expect(end == date(year: 2024, month: 9, day: 30))
    }

    // MARK: Chaining previous/next

    @Test func chainPreviousMonthsBackThreeMonths() {
        // Arrange
        let calc = CadenceCalc(length: .month, calendar: .iso, gap: DateComponents(day: 1))
        var start = date(year: 2024, month: 4, day: 1)
        var results: [Date] = []
        // Act
        for _ in 0..<3 {
            let prev = calc.previous(before: start)
            results.append(prev.0)
            start = prev.0
        }
        // Assert
        #expect(results[0] == date(year: 2024, month: 3, day: 1))
        #expect(results[1] == date(year: 2024, month: 2, day: 1))
        #expect(results[2] == date(year: 2024, month: 1, day: 1))
    }

    @Test func chainNextMonthsForwardThreeMonths() {
        // Arrange
        let calc = CadenceCalc(length: .month, calendar: .iso, gap: DateComponents(day: 1))
        var end = date(year: 2024, month: 1, day: 31)
        var results: [Date] = []
        // Act
        for _ in 0..<3 {
            let next = calc.next(after: end)
            results.append(next.0)
            end = next.1
        }
        // Assert
        #expect(results[0] == date(year: 2024, month: 2, day: 1))
        #expect(results[1] == date(year: 2024, month: 3, day: 1))
        #expect(results[2] == date(year: 2024, month: 4, day: 1))
    }
}
