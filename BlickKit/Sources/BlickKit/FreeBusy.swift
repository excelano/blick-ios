// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation

public enum Availability: Character, Sendable {
    case free = "0"
    case tentative = "1"
    case busy = "2"
    case away = "3"
    case workingElsewhere = "4"
    case unknown = "?"

    public var blocksMeeting: Bool {
        switch self {
        case .free, .workingElsewhere: false
        case .tentative, .busy, .away, .unknown: true
        }
    }

    public var label: String {
        switch self {
        case .free: "Free"
        case .tentative: "Tentative"
        case .busy: "Busy"
        case .away: "Away"
        case .workingElsewhere: "Working elsewhere"
        case .unknown: "No information"
        }
    }
}

public struct FreeBusy: Sendable, Equatable {
    public let start: Date
    public let interval: TimeInterval
    public let slots: [Availability]

    public init(start: Date, interval: TimeInterval, availabilityView: String) {
        self.start = start
        self.interval = interval
        self.slots = availabilityView.map { Availability(rawValue: $0) ?? .unknown }
    }

    public init(start: Date, interval: TimeInterval, slots: [Availability]) {
        self.start = start
        self.interval = interval
        self.slots = slots
    }

    public func availability(at date: Date) -> Availability {
        let index = Int(floor(date.timeIntervalSince(start) / interval))
        guard slots.indices.contains(index) else { return .unknown }
        return slots[index]
    }

    public func availability(from begin: Date, to end: Date) -> Availability {
        var worst = Availability.free
        var cursor = begin
        while cursor < end {
            let slot = availability(at: cursor)
            if rank(slot) > rank(worst) { worst = slot }
            cursor = cursor.addingTimeInterval(interval)
        }
        return worst
    }

    private func rank(_ a: Availability) -> Int {
        switch a {
        case .free: 0
        case .workingElsewhere: 1
        case .tentative: 2
        case .unknown: 3
        case .busy: 4
        case .away: 5
        }
    }

    public static func firstCommonOpening(in schedules: [FreeBusy], duration: TimeInterval,
                                          notBefore: Date, notAfter: Date) -> Date? {
        guard let reference = schedules.first, duration > 0 else { return nil }
        let interval = reference.interval
        let offset = max(0, notBefore.timeIntervalSince(reference.start))
        var candidate = reference.start.addingTimeInterval(ceil(offset / interval) * interval)
        while candidate.addingTimeInterval(duration) <= notAfter {
            let end = candidate.addingTimeInterval(duration)
            if schedules.allSatisfy({ !$0.availability(from: candidate, to: end).blocksMeeting }) {
                return candidate
            }
            candidate = candidate.addingTimeInterval(interval)
        }
        return nil
    }
}
