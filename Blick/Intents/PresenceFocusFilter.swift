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
        let presence = status?.asPresence
        try await inbox.applyFocusPresence(presence == .unknown ? nil : presence)
        return .result()
    }
}
