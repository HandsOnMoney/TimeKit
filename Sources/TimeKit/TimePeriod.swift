import Foundation

public protocol TimePeriod: Identifiable {
    var start: Date { get }
    var end: Date { get }
    
    mutating func change(start: Date, end: Date)
}
