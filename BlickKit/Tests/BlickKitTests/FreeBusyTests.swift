// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation
import Testing
@testable import BlickKit

struct FreeBusyTests {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)
    private let half: TimeInterval = 1800

    private func at(_ slots: Double) -> Date { start.addingTimeInterval(slots * half) }

    @Test func parsesEachGraphCode() {
        let fb = FreeBusy(start: start, interval: half, availabilityView: "01234x")
        #expect(fb.slots == [.free, .tentative, .busy, .away, .workingElsewhere, .unknown])
    }

    @Test func availabilityOutsideTheViewIsUnknown() {
        let fb = FreeBusy(start: start, interval: half, availabilityView: "00")
        #expect(fb.availability(at: at(-1)) == .unknown)
        #expect(fb.availability(at: at(2)) == .unknown)
        #expect(fb.availability(at: at(1.5)) == .free)
    }

    @Test func rangeReportsTheWorstSlot() {
        let fb = FreeBusy(start: start, interval: half, availabilityView: "0120")
        #expect(fb.availability(from: at(0), to: at(1)) == .free)
        #expect(fb.availability(from: at(0), to: at(2)) == .tentative)
        #expect(fb.availability(from: at(0), to: at(4)) == .busy)
    }

    @Test func findsFirstSlotEveryoneHasFree() {
        let a = FreeBusy(start: start, interval: half, availabilityView: "00220000")
        let b = FreeBusy(start: start, interval: half, availabilityView: "20000200")
        let found = FreeBusy.firstCommonOpening(in: [a, b], duration: 2 * half, notBefore: at(0), notAfter: at(8))
        #expect(found == at(6))
    }

    @Test func workingElsewhereDoesNotBlock() {
        let a = FreeBusy(start: start, interval: half, availabilityView: "44")
        #expect(FreeBusy.firstCommonOpening(in: [a], duration: 2 * half, notBefore: at(0), notAfter: at(2)) == at(0))
    }

    @Test func roundsTheStartUpToTheNextSlot() {
        let a = FreeBusy(start: start, interval: half, availabilityView: "0000")
        let found = FreeBusy.firstCommonOpening(in: [a], duration: half, notBefore: at(1.2), notAfter: at(4))
        #expect(found == at(2))
    }

    @Test func noOpeningWhenTheWindowIsFull() {
        let a = FreeBusy(start: start, interval: half, availabilityView: "0202")
        #expect(FreeBusy.firstCommonOpening(in: [a], duration: 2 * half, notBefore: at(0), notAfter: at(4)) == nil)
    }

    @Test func unknownSlotsBlock() {
        let a = FreeBusy(start: start, interval: half, availabilityView: "00")
        #expect(FreeBusy.firstCommonOpening(in: [a], duration: 3 * half, notBefore: at(0), notAfter: at(3)) == nil)
    }
}
