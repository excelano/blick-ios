// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation

public struct WorkingHours: Equatable, Sendable {
    public let weekdays: Set<Int>
    public let startMinute: Int
    public let endMinute: Int
    public let timeZone: TimeZone

    public init(weekdays: Set<Int>, startMinute: Int, endMinute: Int, timeZone: TimeZone) {
        self.weekdays = weekdays
        self.startMinute = startMinute
        self.endMinute = endMinute
        self.timeZone = timeZone
    }

    public init?(graphDays: [String], startTime: String, endTime: String, windowsTimeZone: String?,
                 fallback: TimeZone = .current) {
        let names = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        let days = Set(graphDays.compactMap { day in names.firstIndex(of: day.lowercased()).map { $0 + 1 } })
        guard !days.isEmpty, let start = Self.minute(of: startTime), let end = Self.minute(of: endTime),
              start != end else { return nil }
        let zone = windowsTimeZone.flatMap(WindowsTimeZone.timeZone(named:)) ?? fallback
        self.init(weekdays: days, startMinute: start, endMinute: end, timeZone: zone)
    }

    public func contains(_ date: Date) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.weekday, .hour, .minute], from: date)
        guard let weekday = parts.weekday, let hour = parts.hour, let minute = parts.minute else { return false }
        let now = hour * 60 + minute
        if startMinute < endMinute {
            return weekdays.contains(weekday) && now >= startMinute && now < endMinute
        }
        let previous = weekday == 1 ? 7 : weekday - 1
        return (weekdays.contains(weekday) && now >= startMinute) || (weekdays.contains(previous) && now < endMinute)
    }

    public func summary(locale: Locale = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        let ordered = (1...7).map { ($0 + calendar.firstWeekday - 2) % 7 + 1 }.filter(weekdays.contains)
        let symbols = calendar.shortWeekdaySymbols
        let days = ordered.map { symbols[$0 - 1] }.joined(separator: ", ")
        func time(_ minute: Int) -> String { String(format: "%d:%02d", minute / 60, minute % 60) }
        return "\(days), \(time(startMinute))–\(time(endMinute))"
    }

    private static func minute(of time: String) -> Int? {
        let parts = time.split(separator: ":")
        guard parts.count >= 2, let hour = Int(parts[0]), let minute = Int(parts[1]),
              (0..<24).contains(hour), (0..<60).contains(minute) else { return nil }
        return hour * 60 + minute
    }
}

public enum WindowsTimeZone {
    public static func timeZone(named name: String) -> TimeZone? {
        if let direct = TimeZone(identifier: name) { return direct }
        return table[name].flatMap(TimeZone.init(identifier:))
    }

    private static let table: [String: String] = [
        "Dateline Standard Time": "Etc/GMT+12",
        "UTC-11": "Etc/GMT+11",
        "Hawaiian Standard Time": "Pacific/Honolulu",
        "Alaskan Standard Time": "America/Anchorage",
        "Pacific Standard Time (Mexico)": "America/Tijuana",
        "Pacific Standard Time": "America/Los_Angeles",
        "US Mountain Standard Time": "America/Phoenix",
        "Mountain Standard Time (Mexico)": "America/Mazatlan",
        "Mountain Standard Time": "America/Denver",
        "Central America Standard Time": "America/Guatemala",
        "Central Standard Time": "America/Chicago",
        "Central Standard Time (Mexico)": "America/Mexico_City",
        "Canada Central Standard Time": "America/Regina",
        "SA Pacific Standard Time": "America/Bogota",
        "Eastern Standard Time (Mexico)": "America/Cancun",
        "Eastern Standard Time": "America/New_York",
        "US Eastern Standard Time": "America/Indianapolis",
        "Venezuela Standard Time": "America/Caracas",
        "Atlantic Standard Time": "America/Halifax",
        "SA Western Standard Time": "America/La_Paz",
        "Central Brazilian Standard Time": "America/Cuiaba",
        "Pacific SA Standard Time": "America/Santiago",
        "Newfoundland Standard Time": "America/St_Johns",
        "E. South America Standard Time": "America/Sao_Paulo",
        "Argentina Standard Time": "America/Buenos_Aires",
        "SA Eastern Standard Time": "America/Cayenne",
        "Greenland Standard Time": "America/Godthab",
        "Montevideo Standard Time": "America/Montevideo",
        "UTC-02": "Etc/GMT+2",
        "Azores Standard Time": "Atlantic/Azores",
        "Cape Verde Standard Time": "Atlantic/Cape_Verde",
        "UTC": "Etc/UTC",
        "GMT Standard Time": "Europe/London",
        "Greenwich Standard Time": "Atlantic/Reykjavik",
        "Morocco Standard Time": "Africa/Casablanca",
        "W. Europe Standard Time": "Europe/Berlin",
        "Central Europe Standard Time": "Europe/Budapest",
        "Romance Standard Time": "Europe/Paris",
        "Central European Standard Time": "Europe/Warsaw",
        "W. Central Africa Standard Time": "Africa/Lagos",
        "GTB Standard Time": "Europe/Bucharest",
        "Middle East Standard Time": "Asia/Beirut",
        "Egypt Standard Time": "Africa/Cairo",
        "E. Europe Standard Time": "Europe/Chisinau",
        "South Africa Standard Time": "Africa/Johannesburg",
        "FLE Standard Time": "Europe/Kiev",
        "Israel Standard Time": "Asia/Jerusalem",
        "Jordan Standard Time": "Asia/Amman",
        "Arabic Standard Time": "Asia/Baghdad",
        "Turkey Standard Time": "Europe/Istanbul",
        "Arab Standard Time": "Asia/Riyadh",
        "Russian Standard Time": "Europe/Moscow",
        "E. Africa Standard Time": "Africa/Nairobi",
        "Iran Standard Time": "Asia/Tehran",
        "Arabian Standard Time": "Asia/Dubai",
        "Azerbaijan Standard Time": "Asia/Baku",
        "Afghanistan Standard Time": "Asia/Kabul",
        "Pakistan Standard Time": "Asia/Karachi",
        "West Asia Standard Time": "Asia/Tashkent",
        "India Standard Time": "Asia/Calcutta",
        "Sri Lanka Standard Time": "Asia/Colombo",
        "Nepal Standard Time": "Asia/Katmandu",
        "Central Asia Standard Time": "Asia/Almaty",
        "Bangladesh Standard Time": "Asia/Dhaka",
        "Myanmar Standard Time": "Asia/Rangoon",
        "SE Asia Standard Time": "Asia/Bangkok",
        "China Standard Time": "Asia/Shanghai",
        "Singapore Standard Time": "Asia/Singapore",
        "Taipei Standard Time": "Asia/Taipei",
        "W. Australia Standard Time": "Australia/Perth",
        "Tokyo Standard Time": "Asia/Tokyo",
        "Korea Standard Time": "Asia/Seoul",
        "Cen. Australia Standard Time": "Australia/Adelaide",
        "AUS Central Standard Time": "Australia/Darwin",
        "E. Australia Standard Time": "Australia/Brisbane",
        "AUS Eastern Standard Time": "Australia/Sydney",
        "West Pacific Standard Time": "Pacific/Port_Moresby",
        "Tasmania Standard Time": "Australia/Hobart",
        "New Zealand Standard Time": "Pacific/Auckland",
        "Fiji Standard Time": "Pacific/Fiji",
        "Tonga Standard Time": "Pacific/Tongatapu",
    ]
}
