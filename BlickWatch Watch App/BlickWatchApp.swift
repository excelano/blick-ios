// BlickWatchApp.swift
// BlickWatch Watch App
// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import AppIntents
import BlickKit
import SwiftUI
import WatchKit

@main
struct BlickWatchApp: App {
    @State private var receiver: WatchSessionReceiver
    @Environment(\.scenePhase) private var scenePhase

    /// Matched by `.backgroundTask(.appRefresh(_:))`; watchOS hands the
    /// scheduled `userInfo` back as the task's identifier.
    private static let refreshIdentifier = "com.excelano.checkin.watch.refresh"
    private static let refreshInterval: TimeInterval = 15 * 60

    init() {
        // One receiver instance backs both the glance and the relay
        // intents. Register it so the watch's App Intents resolve the same
        // live WCSession link Siri needs to reach the phone; the system
        // runs this init before any intent's perform().
        let receiver = WatchSessionReceiver()
        AppDependencyManager.shared.add(dependency: receiver)
        _receiver = State(initialValue: receiver)
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                WatchGlanceView(receiver: receiver)
            }
            .environment(\.solarClock, receiver.solarClock)
        }
        .onChange(of: scenePhase, initial: true) {
            Self.scheduleRefresh()
        }
        .backgroundTask(.watchConnectivity) {
            await receiver.receivePending()
        }
        .backgroundTask(.appRefresh(Self.refreshIdentifier)) {
            await Self.scheduleRefresh()
            _ = await receiver.sendRefreshRequest()
        }
    }

    /// Asks watchOS for the next background refresh, which keeps the
    /// complications current while the app is closed. A later request
    /// replaces an earlier one, and the system decides when it actually runs.
    @MainActor
    private static func scheduleRefresh() {
        WKApplication.shared().scheduleBackgroundRefresh(
            withPreferredDate: Date(timeIntervalSinceNow: refreshInterval),
            userInfo: refreshIdentifier as NSString
        ) { _ in }
    }
}
