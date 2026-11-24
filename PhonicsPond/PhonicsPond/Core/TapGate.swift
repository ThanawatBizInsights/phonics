import Foundation

/// Ignores a second tap that arrives too soon (rapid double taps on "next" or a stone).
struct TapGate: Equatable {
    private(set) var last: Date = .distantPast
    var interval: TimeInterval = 0.4

    mutating func allow(now: Date = Date()) -> Bool {
        guard now.timeIntervalSince(last) >= interval else { return false }
        last = now
        return true
    }
}
