// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation
import Testing
@testable import BlickKit

struct ComplicationContentTests {
    private func snapshot(updatedAt: Date = .now, unread: Int = 3, emails: [SnapshotEmail] = []) -> BlickSnapshot {
        BlickSnapshot(updatedAt: updatedAt, nextMeetingSubject: "Standup", nextMeetingStart: Date(timeIntervalSince1970: 0),
                      nextMeetingEnd: Date(timeIntervalSince1970: 900), nextMeetingOrganizer: "A", nextMeetingJoinUrl: nil,
                      unreadEmailCount: unread, chatCount: 1, presence: .available, isOutOfOffice: false,
                      topEmails: emails)
    }

    @Test func ignoresTheRefreshTimeAndTheMessageLists() {
        let email = SnapshotEmail(id: "e", sender: "S", subject: "Hi", preview: "p", received: .now)
        #expect(ComplicationContent(snapshot(updatedAt: .distantPast))
            == ComplicationContent(snapshot(updatedAt: .now, emails: [email])))
    }

    @Test func changesWithACount() {
        #expect(ComplicationContent(snapshot(unread: 3)) != ComplicationContent(snapshot(unread: 4)))
    }

    @Test func lastSentSurvivesARoundTrip() {
        let defaults = UserDefaults(suiteName: "ComplicationContentTests")!
        defaults.removePersistentDomain(forName: "ComplicationContentTests")
        #expect(ComplicationContent.lastSent(in: defaults) == nil)
        let content = ComplicationContent(snapshot(unread: 7))
        content.recordSent(in: defaults)
        #expect(ComplicationContent.lastSent(in: defaults) == content)
    }
}
