// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import BlickKit
import SwiftUI

@MainActor
@ViewBuilder
func emailReminderMenu(for email: Email, inbox: Inbox) -> some View {
    Menu {
        ForEach(ReminderPreset.available(at: .now), id: \.preset) { option in
            Button {
                Task { await inbox.remind(email, at: option.date) }
            } label: {
                Text(option.preset.title)
                Text(option.date.formatted(.dateTime.weekday(.abbreviated).hour().minute()))
            }
        }
        if inbox.reminders[email.id] != nil {
            Divider()
            Button(role: .destructive) {
                Task { await inbox.cancelReminder(emailId: email.id) }
            } label: {
                Label("Cancel reminder", systemImage: "bell.slash")
            }
        }
    } label: {
        if let date = inbox.reminders[email.id] {
            Label("Reminder \(date.formatted(.dateTime.weekday(.abbreviated).hour().minute()))",
                  systemImage: "bell.badge")
        } else {
            Label("Remind me", systemImage: "bell")
        }
    }
}
