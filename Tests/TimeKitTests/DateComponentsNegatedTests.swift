import Testing
import Foundation
@testable import TimeKit

@Suite("DateComponents.negated")
struct DateComponentsNegatedTests {

    // MARK: Single-field negations

    @Test func negatesDayComponent() {
        // Arrange
        let components = DateComponents(day: 1)
        // Act
        let result = components.negated()
        // Assert
        #expect(result.day == -1)
    }

    @Test func negatesYearComponent() {
        // Arrange
        let components = DateComponents(year: 2)
        // Act
        let result = components.negated()
        // Assert
        #expect(result.year == -2)
    }

    @Test func negatesMonthComponent() {
        // Arrange
        let components = DateComponents(month: 3)
        // Act
        let result = components.negated()
        // Assert
        #expect(result.month == -3)
    }

    @Test func negatesHourComponent() {
        // Arrange
        let components = DateComponents(hour: 4)
        // Act
        let result = components.negated()
        // Assert
        #expect(result.hour == -4)
    }

    @Test func negatesMinuteComponent() {
        // Arrange
        let components = DateComponents(minute: 30)
        // Act
        let result = components.negated()
        // Assert
        #expect(result.minute == -30)
    }

    @Test func negatesSecondComponent() {
        // Arrange
        let components = DateComponents(second: 45)
        // Act
        let result = components.negated()
        // Assert
        #expect(result.second == -45)
    }

    @Test func negatesWeekOfYearComponent() {
        // Arrange
        var components = DateComponents()
        components.weekOfYear = 1
        // Act
        let result = components.negated()
        // Assert
        #expect(result.weekOfYear == -1)
    }

    // MARK: Nil preservation

    @Test func nilComponentsStayNil() {
        // Arrange
        let components = DateComponents(day: 1)
        // Act
        let result = components.negated()
        // Assert
        #expect(result.year == nil)
        #expect(result.month == nil)
        #expect(result.hour == nil)
        #expect(result.minute == nil)
        #expect(result.second == nil)
    }

    @Test func emptyComponentsNegateToEmpty() {
        // Arrange
        let components = DateComponents()
        // Act
        let result = components.negated()
        // Assert
        #expect(result.year == nil)
        #expect(result.month == nil)
        #expect(result.day == nil)
        #expect(result.hour == nil)
    }

    // MARK: Double negation

    @Test func doubleNegationIsIdentity() {
        // Arrange
        let components = DateComponents(year: 1, month: 2, day: 3, hour: 4, minute: 5, second: 6)
        // Act
        let result = components.negated().negated()
        // Assert
        #expect(result.year == components.year)
        #expect(result.month == components.month)
        #expect(result.day == components.day)
        #expect(result.hour == components.hour)
        #expect(result.minute == components.minute)
        #expect(result.second == components.second)
    }

    // MARK: Negative input

    @Test func negatingNegativeValueProducesPositive() {
        // Arrange
        let components = DateComponents(day: -7)
        // Act
        let result = components.negated()
        // Assert
        #expect(result.day == 7)
    }

    @Test func negatingZeroProducesZero() {
        // Arrange
        let components = DateComponents(day: 0)
        // Act
        let result = components.negated()
        // Assert
        #expect(result.day == 0)
    }
}
