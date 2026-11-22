// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation

public enum ReminderPreset: String, CaseIterable, Sendable {
    case inOneHour
    case thisEvening
    case tomorrowMorning
    case nextWeek

    public static let eveningHour = 18
    public static let morningHour = 8

    public var title: String {
        switch self {
        case .inOneHour: "In 1 hour"
        case .thisEvening: "This evening"
        case .tomorrowMorning: "Tomorrow morning"
        case .nextWeek: "Next week"
        }
    }

    public func date(from now: Date, calendar: Calendar = .current) -> Date? {
        switch self {
        case .inOneHour:
            return now.addingTimeInterval(3600)
        case .thisEvening:
            guard let evening = calendar.date(bySettingHour: Self.eveningHour, minute: 0, second: 0, of: now),
                  evening > now.addingTimeInterval(2 * 3600) else { return nil }
            return evening
        case .tomorrowMorning:
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) else {
                return nil
            }
            return calendar.date(bySettingHour: Self.morningHour, minute: 0, second: 0, of: tomorrow)
        case .nextWeek:
            guard let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: calendar.startOfDay(for: now)) else {
                return nil
            }
            return calendar.nextDate(after: dayAfterTomorrow.addingTimeInterval(-1),
                                     matching: DateComponents(hour: Self.morningHour, weekday: 2),
                                     matchingPolicy: .nextTime)
        }
    }

    public static func available(at now: Date, calendar: Calendar = .current) -> [(preset: ReminderPreset, date: Date)] {
        allCases.compactMap { preset in
            preset.date(from: now, calendar: calendar).map { (preset, $0) }
        }
    }
}
