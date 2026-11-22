// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation

enum InboxItem: Identifiable {
    case email(Email)
    case chat(ChatMessage)

    var id: String {
        switch self {
        case .email(let email): "email-\(email.id)"
        case .chat(let chat): "chat-\(chat.id.uuidString)"
        }
    }

    var date: Date {
        switch self {
        case .email(let email): email.received
        case .chat(let chat): chat.sent
        }
    }

    static func merged(emails: [Email], chats: [ChatMessage]) -> [InboxItem] {
        (emails.map(InboxItem.email) + chats.map(InboxItem.chat)).sorted { $0.date > $1.date }
    }
}
