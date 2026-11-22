// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation
import Testing
@testable import BlickKit

struct WorkingHoursTests {
    private let chicago = TimeZone(identifier: "America/Chicago")!

    private func date(_ day: Int, _ hour: Int, _ minute: Int = 0, zone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        return calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
    }

    private var weekdays: WorkingHours {
        WorkingHours(graphDays: ["monday", "tuesday", "wednesday", "thursday", "friday"],
                     startTime: "08:00:00.0000000", endTime: "17:00:00.0000000",
                     windowsTimeZone: "Central Standard Time")!
    }

    @Test func parsesGraphShapeAndMapsTheWindowsZone() {
        #expect(weekdays.weekdays == [2, 3, 4, 5, 6])
        #expect(weekdays.startMinute == 480)
        #expect(weekdays.endMinute == 1020)
        #expect(weekdays.timeZone.identifier == "America/Chicago")
    }

    @Test func insideAndOutsideTheWindow() {
        #expect(weekdays.contains(date(23, 8, zone: chicago)))
        #expect(weekdays.contains(date(23, 16, 59, zone: chicago)))
        #expect(!weekdays.contains(date(23, 17, zone: chicago)))
        #expect(!weekdays.contains(date(23, 7, 59, zone: chicago)))
        #expect(!weekdays.contains(date(21, 10, zone: chicago)))
    }

    @Test func judgesInTheMailboxZoneNotTheDevices() {
        let tokyo = TimeZone(identifier: "Asia/Tokyo")!
        #expect(weekdays.contains(date(24, 0, zone: tokyo)))
    }

    @Test func overnightShiftSpansMidnight() {
        let night = WorkingHours(graphDays: ["monday"], startTime: "22:00:00", endTime: "06:00:00",
                                 windowsTimeZone: "Central Standard Time")!
        #expect(night.contains(date(23, 23, zone: chicago)))
        #expect(night.contains(date(24, 5, zone: chicago)))
        #expect(!night.contains(date(24, 23, zone: chicago)))
    }

    @Test func unknownZoneFallsBack() {
        let hours = WorkingHours(graphDays: ["monday"], startTime: "08:00:00", endTime: "17:00:00",
                                 windowsTimeZone: "Nowhere Standard Time", fallback: chicago)!
        #expect(hours.timeZone == chicago)
    }

    @Test func ianaNameIsAcceptedDirectly() {
        #expect(WindowsTimeZone.timeZone(named: "Europe/Berlin")?.identifier == "Europe/Berlin")
    }

    @Test func rejectsEmptyOrMalformed() {
        #expect(WorkingHours(graphDays: [], startTime: "08:00:00", endTime: "17:00:00", windowsTimeZone: nil) == nil)
        #expect(WorkingHours(graphDays: ["monday"], startTime: "x", endTime: "17:00:00", windowsTimeZone: nil) == nil)
    }
}
