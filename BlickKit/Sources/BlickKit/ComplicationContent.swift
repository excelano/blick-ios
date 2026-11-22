// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation

public struct ComplicationContent: Codable, Hashable {
    let nextMeetingSubject: String?
    let nextMeetingStart: Date?
    let nextMeetingEnd: Date?
    let unreadEmailCount: Int
    let chatCount: Int
    let presence: Presence
    let isOutOfOffice: Bool
    let laterMeetings: [SnapshotMeeting]

    public init(_ snapshot: BlickSnapshot) {
        nextMeetingSubject = snapshot.nextMeetingSubject
        nextMeetingStart = snapshot.nextMeetingStart
        nextMeetingEnd = snapshot.nextMeetingEnd
        unreadEmailCount = snapshot.unreadEmailCount
        chatCount = snapshot.chatCount
        presence = snapshot.presence
        isOutOfOffice = snapshot.isOutOfOffice
        laterMeetings = snapshot.laterMeetings
    }

    private static let storageKey = "lastComplicationContent"

    public static func lastSent(in defaults: UserDefaults = .standard) -> ComplicationContent? {
        defaults.data(forKey: storageKey).flatMap { try? JSONDecoder().decode(ComplicationContent.self, from: $0) }
    }

    public func recordSent(in defaults: UserDefaults = .standard) {
        defaults.set(try? JSONEncoder().encode(self), forKey: Self.storageKey)
    }
}
