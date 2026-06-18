import Testing
import Foundation
@testable import TimeKit

@Suite("Cadence")
struct CadenceTests {

    // MARK: Equality

    @Test func daysEqualWhenCountMatches() {
        // Arrange
        let a = Cadence.days(count: 7)
        let b = Cadence.days(count: 7)
        // Act & Assert
        #expect(a == b)
    }

    @Test func daysNotEqualWhenCountDiffers() {
        // Arrange
        let a = Cadence.days(count: 7)
        let b = Cadence.days(count: 14)
        // Act & Assert
        #expect(a != b)
    }

    @Test func distinctCasesAreNotEqual() {
        // Arrange
        let cases: [Cadence] = [.days(count: 1), .week, .month, .quarter, .year]
        // Act & Assert
        for i in cases.indices {
            for j in cases.indices where i != j {
                #expect(cases[i] != cases[j])
            }
        }
    }

    // MARK: Hashing

    @Test func sameValuesProduceSameHash() {
        // Arrange
        let a = Cadence.days(count: 5)
        let b = Cadence.days(count: 5)
        // Act
        let hashA = a.hashValue
        let hashB = b.hashValue
        // Assert
        #expect(hashA == hashB)
    }

    @Test func cadenceUsableAsDictionaryKey() {
        // Arrange
        var dict: [Cadence: String] = [:]
        // Act
        dict[.week] = "week"
        dict[.month] = "month"
        // Assert
        #expect(dict[.week] == "week")
        #expect(dict[.month] == "month")
    }

    // MARK: Codable

    @Test func roundTripsViaJSON() throws {
        // Arrange
        let cases: [Cadence] = [.days(count: 3), .week, .month, .quarter, .year]
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        // Act & Assert
        for cadence in cases {
            let data = try encoder.encode(cadence)
            let decoded = try decoder.decode(Cadence.self, from: data)
            #expect(decoded == cadence)
        }
    }

    @Test func daysWithCountRoundTrips() throws {
        // Arrange
        let original = Cadence.days(count: 42)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        // Act
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Cadence.self, from: data)
        // Assert
        #expect(decoded == original)
    }

    @Test func decodingInvalidJSONThrows() {
        // Arrange
        let badJSON = Data("{\"invalid\":true}".utf8)
        // Act & Assert
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(Cadence.self, from: badJSON)
        }
    }
}
