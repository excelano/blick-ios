// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation
import Testing
@testable import BlickKit

struct ReminderPresetTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Chicago")!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    @Test func oneHourIsAlwaysOffered() {
        let now = date(2026, 11, 20, 23, 30)
        #expect(ReminderPreset.inOneHour.date(from: now, calendar: calendar) == now.addingTimeInterval(3600))
    }

    @Test func eveningOfferedEarlyInTheDay() {
        let now = date(2026, 11, 20, 9)
        #expect(ReminderPreset.thisEvening.date(from: now, calendar: calendar) == date(2026, 11, 20, 18))
    }

    @Test func eveningDroppedWhenTooClose() {
        #expect(ReminderPreset.thisEvening.date(from: date(2026, 11, 20, 16, 30), calendar: calendar) == nil)
        #expect(ReminderPreset.thisEvening.date(from: date(2026, 11, 20, 19), calendar: calendar) == nil)
    }

    @Test func tomorrowMorningIsNextDayAtEight() {
        #expect(ReminderPreset.tomorrowMorning.date(from: date(2026, 11, 20, 23, 50), calendar: calendar)
            == date(2026, 11, 21, 8))
    }

    @Test func tomorrowMorningCrossesDaylightSavingEnd() {
        #expect(ReminderPreset.tomorrowMorning.date(from: date(2026, 10, 31, 22), calendar: calendar)
            == date(2026, 11, 1, 8))
    }

    @Test func nextWeekIsTheComingMonday() {
        #expect(ReminderPreset.nextWeek.date(from: date(2026, 11, 20, 10), calendar: calendar)
            == date(2026, 11, 23, 8))
    }

    @Test func nextWeekFromMondaySkipsAWeek() {
        #expect(ReminderPreset.nextWeek.date(from: date(2026, 11, 23, 7), calendar: calendar)
            == date(2026, 11, 30, 8))
    }

    @Test func nextWeekFromSundayIsNotTomorrow() {
        #expect(ReminderPreset.nextWeek.date(from: date(2026, 11, 22, 10), calendar: calendar)
            == date(2026, 11, 30, 8))
    }

    @Test func availableSkipsPresetsThatDoNotApply() {
        let presets = ReminderPreset.available(at: date(2026, 11, 20, 17), calendar: calendar).map(\.preset)
        #expect(presets == [.inOneHour, .tomorrowMorning, .nextWeek])
    }
}
