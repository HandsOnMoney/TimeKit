import Foundation

public enum Cadence: Hashable, Codable, Sendable {
    case days(count: Int)
    case week
    case month
    case quarter
    case year
}
