// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation
import Testing
@testable import BlickKit

struct DailyBriefTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Chicago")!
        return calendar
    }

    private func date(_ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
    }

    private let label: (Date) -> String = { _ in "T" }

    @Test func leadsWithTheEarliestMeeting() {
        let brief = DailyBrief.compose(
            meetings: [.init(subject: "Later", start: date(11, 23, 14)), .init(subject: "Standup", start: date(11, 23, 9))],
            unreadEmails: 4, unreadChats: 1, timeStyle: label)
        #expect(brief.title == "First up: Standup at T")
        #expect(brief.body == "2 meetings today, 4 unread emails, 1 unread chat.")
    }

    @Test func singleMeetingSkipsTheCount() {
        let brief = DailyBrief.compose(meetings: [.init(subject: "Review", start: date(11, 23, 9))],
                                       unreadEmails: 1, unreadChats: 0, timeStyle: label)
        #expect(brief.body == "1 unread email, no unread chats.")
    }

    @Test func emptyDay() {
        let brief = DailyBrief.compose(meetings: [], unreadEmails: 0, unreadChats: 0, timeStyle: label)
        #expect(brief.title == "No meetings today")
        #expect(brief.body == "no unread emails, no unread chats.")
    }

    @Test func firesLaterTodayWhenTheTimeIsAhead() {
        #expect(DailyBrief.nextFireDate(after: date(11, 23, 6), minuteOfDay: 450, weekdaysOnly: true, calendar: calendar)
            == date(11, 23, 7, 30))
    }

    @Test func rollsToTomorrowOnceTheTimeHasPassed() {
        #expect(DailyBrief.nextFireDate(after: date(11, 23, 8), minuteOfDay: 450, weekdaysOnly: true, calendar: calendar)
            == date(11, 24, 7, 30))
    }

    @Test func weekdaysOnlySkipsTheWeekend() {
        #expect(DailyBrief.nextFireDate(after: date(11, 20, 9), minuteOfDay: 450, weekdaysOnly: true, calendar: calendar)
            == date(11, 23, 7, 30))
        #expect(DailyBrief.nextFireDate(after: date(11, 20, 9), minuteOfDay: 450, weekdaysOnly: false, calendar: calendar)
            == date(11, 21, 7, 30))
    }
}
