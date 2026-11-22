// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation

public enum AutomaticPresence {
    public enum Decision: Equatable {
        case apply(Presence)
        case release
        case leave
    }

    public static func decide(desired: Presence?, pin: (presence: Presence, expiry: Date)?,
                              automaticExpiry: Date?) -> Decision {
        let pinIsAutomatic = pin != nil && pin?.expiry == automaticExpiry
        if pin != nil && !pinIsAutomatic { return .leave }
        if let desired {
            return pin?.presence == desired ? .leave : .apply(desired)
        }
        return pinIsAutomatic ? .release : .leave
    }
}

public struct AutomaticPresenceStore: Sendable {
    private let suite: String

    public init(suite: String = BlickSnapshot.appGroupIdentifier) {
        self.suite = suite
    }

    private var defaults: UserDefaults? { UserDefaults(suiteName: suite) }

    private static let focusKey = "focusPresence"
    private static let automaticExpiryKey = "automaticPresenceExpiry"

    public var focusPresence: Presence? {
        defaults?.string(forKey: Self.focusKey).flatMap(Presence.init(rawValue:))
    }

    public func setFocusPresence(_ presence: Presence?) {
        if let presence {
            defaults?.set(presence.rawValue, forKey: Self.focusKey)
        } else {
            defaults?.removeObject(forKey: Self.focusKey)
        }
    }

    public var automaticExpiry: Date? {
        defaults?.object(forKey: Self.automaticExpiryKey) as? Date
    }

    public func setAutomaticExpiry(_ expiry: Date?) {
        if let expiry {
            defaults?.set(expiry, forKey: Self.automaticExpiryKey)
        } else {
            defaults?.removeObject(forKey: Self.automaticExpiryKey)
        }
    }
}
