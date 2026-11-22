// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import BlickKit
import Foundation
import UserNotifications
import os

@MainActor
final class DailyBriefNotification {
    private let identifier = "blick.brief.next"
    private let logger = Logger(subsystem: "com.excelano.checkin", category: "notifications")

    func schedule(_ brief: DailyBrief, at date: Date) async {
        guard await NotificationAuthorization.isGranted() else { return }
        let content = UNMutableNotificationContent()
        content.title = brief.title
        content.body = brief.body
        content.sound = .default
        content.threadIdentifier = "blick.brief"
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let request = UNNotificationRequest(identifier: identifier, content: content,
                                            trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false))
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            logger.error("brief failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func clear() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
