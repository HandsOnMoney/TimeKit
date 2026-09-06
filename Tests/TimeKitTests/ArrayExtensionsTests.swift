import Testing
import Foundation
@testable import TimeKit

// MARK: - Fixtures

private struct Event {
    let date: Date
    let value: Int
}

private struct Entry {
    let date: Date
    let tag: String
}

private func d(_ seconds: Double) -> Date {
    Date(timeIntervalSinceReferenceDate: seconds)
}

// MARK: - lowerBound

@Suite("Array.lowerBound")
struct ArrayLowerBoundTests {

    @Test func emptyArray_returnsNegativeOne() {
        // Arrange
        let events: [Event] = []
        // Act
        let result = events.lowerBound(target: d(10), by: \.date)
        // Assert
        #expect(result == -1)
    }

    @Test func singleElement_equalToTarget_returnsZero() {
        // Arrange
        let events = [Event(date: d(10), value: 0)]
        // Act
        let result = events.lowerBound(target: d(10), by: \.date)
        // Assert
        #expect(result == 0)
    }

    @Test func singleElement_beforeTarget_returnsZero() {
        // Arrange
        let events = [Event(date: d(5), value: 0)]
        // Act
        let result = events.lowerBound(target: d(10), by: \.date)
        // Assert
        #expect(result == 0)
    }

    @Test func singleElement_afterTarget_returnsNegativeOne() {
        // Arrange
        let events = [Event(date: d(15), value: 0)]
        // Act
        let result = events.lowerBound(target: d(10), by: \.date)
        // Assert
        #expect(result == -1)
    }

    @Test func allElementsBeforeTarget_returnsLastIndex() {
        // Arrange
        let events = [Event(date: d(1), value: 0), Event(date: d(2), value: 1), Event(date: d(3), value: 2)]
        // Act
        let result = events.lowerBound(target: d(10), by: \.date)
        // Assert
        #expect(result == 2)
    }

    @Test func allElementsAfterTarget_returnsNegativeOne() {
        // Arrange
        let events = [Event(date: d(10), value: 0), Event(date: d(20), value: 1), Event(date: d(30), value: 2)]
        // Act
        let result = events.lowerBound(target: d(5), by: \.date)
        // Assert
        #expect(result == -1)
    }

    @Test func targetBetweenElements_returnsLastIndexBeforeTarget() {
        // Arrange
        let events = [
            Event(date: d(1), value: 0),
            Event(date: d(3), value: 1),
            Event(date: d(7), value: 2),
            Event(date: d(9), value: 3)
        ]
        // Act
        let result = events.lowerBound(target: d(5), by: \.date)
        // Assert
        #expect(result == 1) // d(3) is last ≤ d(5)
    }

    @Test func targetAtFirstElement_returnsZero() {
        // Arrange
        let events = [Event(date: d(1), value: 0), Event(date: d(5), value: 1), Event(date: d(9), value: 2)]
        // Act
        let result = events.lowerBound(target: d(1), by: \.date)
        // Assert
        #expect(result == 0)
    }

    @Test func targetAtLastElement_returnsLastIndex() {
        // Arrange
        let events = [Event(date: d(1), value: 0), Event(date: d(5), value: 1), Event(date: d(9), value: 2)]
        // Act
        let result = events.lowerBound(target: d(9), by: \.date)
        // Assert
        #expect(result == 2)
    }
}

// MARK: - lowerBoundElement

@Suite("Array.lowerBoundElement")
struct ArrayLowerBoundElementTests {

    @Test func emptyArray_returnsNil() {
        // Arrange
        let events: [Event] = []
        // Act & Assert
        #expect(events.lowerBoundElement(target: d(10), by: \.date) == nil)
    }

    @Test func allElementsAfterTarget_returnsNil() {
        // Arrange
        let events = [Event(date: d(10), value: 1), Event(date: d(20), value: 2)]
        // Act & Assert
        #expect(events.lowerBoundElement(target: d(5), by: \.date) == nil)
    }

    @Test func targetMatchesElement_returnsThatElement() {
        // Arrange
        let events = [Event(date: d(5), value: 42), Event(date: d(10), value: 99)]
        // Act
        let result = events.lowerBoundElement(target: d(5), by: \.date)
        // Assert
        #expect(result?.value == 42)
    }

    @Test func targetBetweenElements_returnsLastElementBeforeTarget() {
        // Arrange
        let events = [Event(date: d(1), value: 10), Event(date: d(3), value: 30), Event(date: d(7), value: 70)]
        // Act
        let result = events.lowerBoundElement(target: d(5), by: \.date)
        // Assert
        #expect(result?.value == 30)
    }

    @Test func targetAfterAllElements_returnsLastElement() {
        // Arrange
        let events = [Event(date: d(1), value: 10), Event(date: d(3), value: 30)]
        // Act
        let result = events.lowerBoundElement(target: d(100), by: \.date)
        // Assert
        #expect(result?.value == 30)
    }
}

// MARK: - mergeReduce

@Suite("Array.mergeReduce")
struct ArrayMergeReduceTests {

    @Test func bothEmpty_returnsEmpty() {
        // Arrange
        let events: [Event] = []
        let entries: [Entry] = []
        // Act
        let result = events.mergeReduce(with: entries, by: \.date, andBy: \.date) { _, _, _ -> Int in 0 }
        // Assert
        #expect(result.isEmpty)
    }

    @Test func selfEmpty_allCallsReceiveNilSelf() {
        // Arrange
        let events: [Event] = []
        let entries = [Entry(date: d(1), tag: "A"), Entry(date: d(2), tag: "B")]
        var selfNilCount = 0
        // Act
        _ = events.mergeReduce(with: entries, by: \.date, andBy: \.date) { _, a, _ -> Int in
            if a == nil { selfNilCount += 1 }
            return 0
        }
        // Assert
        #expect(selfNilCount == entries.count)
    }

    @Test func selfEmpty_drainsFully_fromOther() {
        // Arrange
        let events: [Event] = []
        let entries = [Entry(date: d(1), tag: "A"), Entry(date: d(2), tag: "B"), Entry(date: d(3), tag: "C")]
        var collectedTags: [String] = []
        // Act
        _ = events.mergeReduce(with: entries, by: \.date, andBy: \.date) { _, _, b -> Int in
            if let b { collectedTags.append(b.tag) }
            return 0
        }
        // Assert
        #expect(collectedTags == ["A", "B", "C"])
    }

    @Test func otherEmpty_allCallsReceiveNilOther() {
        // Arrange
        let events = [Event(date: d(1), value: 10), Event(date: d(2), value: 20)]
        let entries: [Entry] = []
        var otherNilCount = 0
        // Act
        _ = events.mergeReduce(with: entries, by: \.date, andBy: \.date) { _, _, b -> Int in
            if b == nil { otherNilCount += 1 }
            return 0
        }
        // Assert
        #expect(otherNilCount == events.count)
    }

    @Test func otherEmpty_drainsFully_fromSelf() {
        // Arrange
        let events = [Event(date: d(1), value: 10), Event(date: d(2), value: 20)]
        let entries: [Entry] = []
        var collectedValues: [Int] = []
        // Act
        _ = events.mergeReduce(with: entries, by: \.date, andBy: \.date) { _, a, _ -> Int in
            if let a { collectedValues.append(a.value) }
            return 0
        }
        // Assert
        #expect(collectedValues == [10, 20])
    }

    @Test func interleaved_callsInDateOrder() {
        // Arrange
        let events = [Event(date: d(1), value: 1), Event(date: d(3), value: 3)]
        let entries = [Entry(date: d(2), tag: "B"), Entry(date: d(4), tag: "D")]
        var order: [String] = []
        // Act
        _ = events.mergeReduce(with: entries, by: \.date, andBy: \.date) { _, a, b -> Int in
            if let a { order.append("S\(a.value)") }
            if let b { order.append("O\(b.tag)") }
            return 0
        }
        // Assert
        #expect(order == ["S1", "OB", "S3", "OD"])
    }

    @Test func tie_transformReceivesBothNonNil_inOneCall() {
        // Arrange
        let events = [Event(date: d(5), value: 42)]
        let entries = [Entry(date: d(5), tag: "X")]
        var callCount = 0
        var seenBothNonNil = false
        // Act
        _ = events.mergeReduce(with: entries, by: \.date, andBy: \.date) { _, a, b -> Int in
            callCount += 1
            if a != nil && b != nil { seenBothNonNil = true }
            return 0
        }
        // Assert
        #expect(callCount == 1)
        #expect(seenBothNonNil)
    }

    @Test func accumulatorPassedToNextCall() {
        // Arrange
        let events = [Event(date: d(1), value: 10), Event(date: d(2), value: 20), Event(date: d(3), value: 30)]
        let entries: [Entry] = []
        // Act
        let result = events.mergeReduce(with: entries, by: \.date, andBy: \.date) { acc, a, _ -> Int in
            (acc ?? 0) + (a?.value ?? 0)
        }
        // Assert
        #expect(result == [10, 30, 60])
    }

    @Test func selfDrainsFirst_remainingOtherProcessedWithNilSelf() {
        // Arrange
        let events = [Event(date: d(1), value: 1)]
        let entries = [Entry(date: d(2), tag: "B"), Entry(date: d(3), tag: "C")]
        var drainedTags: [String] = []
        // Act
        _ = events.mergeReduce(with: entries, by: \.date, andBy: \.date) { _, a, b -> Int in
            if a == nil, let b { drainedTags.append(b.tag) }
            return 0
        }
        // Assert
        #expect(drainedTags == ["B", "C"])
    }

    @Test func otherDrainsFirst_remainingSelfProcessedWithNilOther() {
        // Arrange
        let events = [Event(date: d(2), value: 20), Event(date: d(3), value: 30)]
        let entries = [Entry(date: d(1), tag: "A")]
        var drainedValues: [Int] = []
        // Act
        _ = events.mergeReduce(with: entries, by: \.date, andBy: \.date) { _, a, b -> Int in
            if b == nil, let a { drainedValues.append(a.value) }
            return 0
        }
        // Assert
        #expect(drainedValues == [20, 30])
    }
}
