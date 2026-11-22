// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation
import Observation

@MainActor
@Observable
final class NotificationRouter {
    static let shared = NotificationRouter()

    var emailToOpen: Email?

    private init() {}
}

extension Email {
    var notificationUserInfo: [String: Any] {
        [
            "emailId": id,
            "emailSubject": subject,
            "emailFrom": from,
            "emailFromAddress": fromAddress,
            "emailPreview": preview,
            "emailReceived": received.timeIntervalSince1970,
        ]
    }

    init?(notificationUserInfo info: [AnyHashable: Any]) {
        guard let id = info["emailId"] as? String else { return nil }
        self.init(id: id,
                  subject: info["emailSubject"] as? String ?? "",
                  from: info["emailFrom"] as? String ?? "",
                  fromAddress: info["emailFromAddress"] as? String ?? "",
                  preview: info["emailPreview"] as? String ?? "",
                  received: Date(timeIntervalSince1970: info["emailReceived"] as? TimeInterval ?? 0))
    }
}
