// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation

public struct DailyBrief: Equatable, Sendable {
    public struct Meeting: Equatable, Sendable {
        public let subject: String
        public let start: Date

        public init(subject: String, start: Date) {
            self.subject = subject
            self.start = start
        }
    }

    public let title: String
    public let body: String

    public init(title: String, body: String) {
        self.title = title
        self.body = body
    }

    public static func compose(meetings: [Meeting], unreadEmails: Int, unreadChats: Int,
                               timeStyle: (Date) -> String) -> DailyBrief {
        let sorted = meetings.sorted { $0.start < $1.start }
        let title: String
        if let first = sorted.first {
            title = "First up: \(first.subject) at \(timeStyle(first.start))"
        } else {
            title = "No meetings today"
        }
        var parts: [String] = []
        if sorted.count > 1 {
            parts.append("\(sorted.count) meetings today")
        }
        parts.append(count(unreadEmails, "unread email", "unread emails"))
        parts.append(count(unreadChats, "unread chat", "unread chats"))
        return DailyBrief(title: title, body: parts.joined(separator: ", ") + ".")
    }

    public static func nextFireDate(after now: Date, minuteOfDay: Int, weekdaysOnly: Bool,
                                    calendar: Calendar = .current) -> Date? {
        var day = calendar.startOfDay(for: now)
        for _ in 0..<8 {
            if let fire = calendar.date(bySettingHour: minuteOfDay / 60, minute: minuteOfDay % 60, second: 0, of: day),
               fire > now, !(weekdaysOnly && calendar.isDateInWeekend(fire)) {
                return fire
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { return nil }
            day = next
        }
        return nil
    }

    private static func count(_ n: Int, _ singular: String, _ plural: String) -> String {
        n == 0 ? "no \(plural)" : "\(n) \(n == 1 ? singular : plural)"
    }
}
