// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation
import UserNotifications
import os

@MainActor
final class EmailReminders {
    private let identifierPrefix = "blick.reminder."
    private let logger = Logger(subsystem: "com.excelano.checkin", category: "notifications")

    func schedule(_ email: Email, at date: Date) async -> Bool {
        guard await NotificationAuthorization.request() else { return false }
        let content = UNMutableNotificationContent()
        content.title = email.from
        content.subtitle = email.subject
        content.body = email.preview
        content.sound = .default
        content.threadIdentifier = "blick.reminder"
        content.userInfo = email.notificationUserInfo
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let request = UNNotificationRequest(
            identifier: identifierPrefix + email.id,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        )
        do {
            try await UNUserNotificationCenter.current().add(request)
            return true
        } catch {
            logger.error("reminder failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func cancel(emailId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifierPrefix + emailId])
    }

    func pending() async -> [String: Date] {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        var dates: [String: Date] = [:]
        for request in requests where request.identifier.hasPrefix(identifierPrefix) {
            guard let trigger = request.trigger as? UNCalendarNotificationTrigger,
                  let date = trigger.nextTriggerDate() else { continue }
            dates[String(request.identifier.dropFirst(identifierPrefix.count))] = date
        }
        return dates
    }
}
