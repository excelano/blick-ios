// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation
import Testing
@testable import BlickKit

struct AutomaticPresenceTests {
    private let expiry = Date(timeIntervalSince1970: 1_800_000_000)
    private let otherExpiry = Date(timeIntervalSince1970: 1_800_003_600)

    @Test func appliesWhenNothingIsPinned() {
        #expect(AutomaticPresence.decide(desired: .doNotDisturb, pin: nil, automaticExpiry: nil) == .apply(.doNotDisturb))
    }

    @Test func manualPinWins() {
        #expect(AutomaticPresence.decide(desired: .doNotDisturb, pin: (.busy, expiry), automaticExpiry: otherExpiry) == .leave)
        #expect(AutomaticPresence.decide(desired: nil, pin: (.busy, expiry), automaticExpiry: nil) == .leave)
    }

    @Test func automaticPinFollowsTheNewDesire() {
        #expect(AutomaticPresence.decide(desired: .offline, pin: (.doNotDisturb, expiry), automaticExpiry: expiry) == .apply(.offline))
    }

    @Test func automaticPinAlreadyRightIsLeft() {
        #expect(AutomaticPresence.decide(desired: .doNotDisturb, pin: (.doNotDisturb, expiry), automaticExpiry: expiry) == .leave)
    }

    @Test func automaticPinIsReleasedWhenNothingIsDesired() {
        #expect(AutomaticPresence.decide(desired: nil, pin: (.doNotDisturb, expiry), automaticExpiry: expiry) == .release)
    }

    @Test func nothingToDoWhenNothingIsPinnedOrDesired() {
        #expect(AutomaticPresence.decide(desired: nil, pin: nil, automaticExpiry: expiry) == .leave)
    }
}
