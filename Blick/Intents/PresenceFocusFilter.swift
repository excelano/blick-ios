// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import AppIntents
import BlickKit

struct PresenceFocusFilter: SetFocusFilterIntent {
    static var title: LocalizedStringResource = "Set Teams Presence"
    static var description = IntentDescription(
        "Sets your Microsoft 365 presence while this Focus is on, and releases it when the Focus ends. A status you pick yourself in Blick still wins until it expires."
    )

    @Parameter(title: "Presence")
    var status: StatusAppEnum?

    @Dependency var inbox: Inbox

    var displayRepresentation: DisplayRepresentation {
        guard let status else { return DisplayRepresentation(title: "No change") }
        return DisplayRepresentation(title: "\(StatusAppEnum.caseDisplayRepresentations[status]?.title ?? "Presence")")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        try await inbox.applyFocusPresence(Self.presence(for: status))
        return .result()
    }

    static func presence(for status: StatusAppEnum?) -> Presence? {
        guard let presence = status?.asPresence, presence != .unknown else { return nil }
        return presence
    }

    static func activePresence() async throws -> Presence? {
        presence(for: try await current.status)
    }
}
