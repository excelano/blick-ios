// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Bogenzeit
import BlickKit
import SwiftUI

struct SolarClockSource: ViewModifier {
    let publish: @MainActor (SolarClock?) -> Void

    @AppStorage(AppStorageKey.bogenzeit) private var enabled = false
    @AppStorage(AppStorageKey.bogenzeitLatitude) private var latitude: Double?
    @AppStorage(AppStorageKey.bogenzeitLongitude) private var longitude: Double?
    @AppStorage(AppStorageKey.bogenzeitScale) private var scale = Scale.standard.rawValue
    @AppStorage(AppStorageKey.bogenzeitPrecision) private var precision = Precision.standard.rawValue
    @AppStorage(AppStorageKey.bogenzeitHidesCivilTime) private var hidesCivilTime = false

    private var clock: SolarClock? {
        SolarClock(enabled: enabled, latitude: latitude, longitude: longitude,
                   scale: scale, precision: precision, hidesCivilTime: hidesCivilTime)
    }

    func body(content: Content) -> some View {
        content
            .environment(\.solarClock, clock)
            .onChange(of: clock, initial: true) { _, newValue in publish(newValue) }
    }
}
