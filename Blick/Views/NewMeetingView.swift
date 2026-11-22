// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import BlickKit
import SwiftUI

struct NewMeetingView: View {
    var inbox: Inbox
    let onClose: () -> Void

    @State private var subject = ""
    @State private var attendeesText = ""
    @State private var start = NewMeetingView.nextHalfHour(after: .now)
    @State private var durationMinutes = 30
    @State private var teams = true
    @State private var notes = ""
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var showContactPicker = false
    @State private var schedules: [String: FreeBusy] = [:]
    @State private var loadingSchedules = false
    @State private var schedulesFailed = false
    @State private var noOpening = false
    @FocusState private var attendeesFocused: Bool

    private static let durations = [15, 30, 45, 60, 90, 120]
    private static let lookAheadDays = 14
    private static let workdayStartHour = 8
    private static let workdayEndHour = 18

    private var attendees: [String] { EmailAddressValidation.parseList(attendeesText).valid }
    private var invalidAttendees: [String] { EmailAddressValidation.parseList(attendeesText).invalid }
    private var end: Date { start.addingTimeInterval(TimeInterval(durationMinutes * 60)) }

    private var canSend: Bool {
        !isSending && !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && invalidAttendees.isEmpty && end > .now
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $subject)
                    Toggle("Teams meeting", isOn: $teams)
                        .tint(Brand.accent)
                }
                attendeesSection
                Section("When") {
                    DatePicker("Starts", selection: $start, in: Date.now..., displayedComponents: [.date, .hourAndMinute])
                    Picker("Duration", selection: $durationMinutes) {
                        ForEach(Self.durations, id: \.self) { minutes in
                            Text(Self.durationLabel(minutes)).tag(minutes)
                        }
                    }
                }
                availabilitySection
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 90)
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.bg)
            .tint(Brand.accent)
            .disabled(isSending)
            .navigationTitle("New Meeting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onClose)
                        .foregroundStyle(Brand.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSending {
                        ProgressView().tint(Brand.accent)
                    } else {
                        Button(attendees.isEmpty ? "Save" : "Send") { Task { await send() } }
                            .foregroundStyle(canSend ? Brand.accent : Brand.textMuted)
                            .disabled(!canSend)
                    }
                }
            }
            .toolbarBackground(Brand.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .task(id: attendees) { await loadSchedules() }
        .onChange(of: start) { noOpening = false }
        .background {
            if showContactPicker {
                ContactPicker(
                    onPick: { picked in
                        attendeesText = RecipientSuggest.completing(attendeesText, with: picked.address)
                        showContactPicker = false
                    },
                    onCancel: { showContactPicker = false }
                )
            }
        }
    }

    private var attendeesSection: some View {
        Section {
            HStack {
                TextField("Add people by email", text: $attendeesText)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($attendeesFocused)
                Button { showContactPicker = true } label: {
                    Image(systemName: "person.crop.circle.badge.plus")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Add from Contacts")
            }
            ForEach(suggestions, id: \.address) { entry in
                Button {
                    attendeesText = RecipientSuggest.completing(attendeesText, with: entry.address)
                } label: {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(entry.name).foregroundStyle(.white)
                        if entry.name != entry.address {
                            Text(entry.address).font(.caption).foregroundStyle(Brand.textMuted)
                        }
                    }
                }
            }
        } header: {
            Text("Attendees")
        } footer: {
            if !invalidAttendees.isEmpty {
                Text("Not an email address: \(invalidAttendees.joined(separator: ", "))")
                    .foregroundStyle(.orange)
            } else if attendees.isEmpty {
                Text("With no attendees the meeting goes on your calendar only.")
            } else {
                Text("Each attendee gets an invitation when you send.")
            }
        }
    }

    private var suggestions: [AddressBookEntry] {
        guard attendeesFocused else { return [] }
        let token = RecipientSuggest.activeToken(in: attendeesText)
        guard !token.isEmpty else { return [] }
        let chosen = Set(attendees.map { $0.lowercased() })
        return RecipientSuggest.matches(for: token, in: inbox.recipientSuggestions())
            .filter { !chosen.contains($0.address.lowercased()) }
    }

    @ViewBuilder
    private var availabilitySection: some View {
        if !attendees.isEmpty {
            Section {
                if loadingSchedules && schedules.isEmpty {
                    ProgressView().tint(Brand.accent)
                } else if schedulesFailed {
                    Text("Couldn't load availability.")
                        .foregroundStyle(.orange)
                } else {
                    ForEach(availabilityRows, id: \.address) { row in
                        HStack {
                            Circle()
                                .fill(Self.color(for: row.availability))
                                .frame(width: 10, height: 10)
                            Text(row.name)
                            Spacer()
                            Text(row.availability.label)
                                .foregroundStyle(Brand.textMuted)
                        }
                        .accessibilityElement(children: .combine)
                    }
                    Button("Find a time everyone is free") { findOpening() }
                    if noOpening {
                        Text("No common opening in working hours over the next \(Self.lookAheadDays) days.")
                            .font(.footnote)
                            .foregroundStyle(Brand.textMuted)
                    }
                }
            } header: {
                Text("Availability")
            } footer: {
                Text("From each calendar's free/busy for the chosen time. People outside your organization often show no information.")
            }
        }
    }

    private var availabilityRows: [(address: String, name: String, availability: Availability)] {
        let me = inbox.currentUserMail
        let everyone = (me.isEmpty ? [] : [me]) + attendees.filter { $0.caseInsensitiveCompare(me) != .orderedSame }
        return everyone.map { address in
            let name = address.caseInsensitiveCompare(me) == .orderedSame ? "You" : address
            let availability = schedules[address.lowercased()]?.availability(from: start, to: end) ?? .unknown
            return (address, name, availability)
        }
    }

    private func loadSchedules() async {
        guard !attendees.isEmpty else {
            schedules = [:]
            return
        }
        try? await Task.sleep(for: .milliseconds(500))
        guard !Task.isCancelled else { return }
        let windowStart = Calendar.current.startOfDay(for: .now)
        guard let windowEnd = Calendar.current.date(byAdding: .day, value: Self.lookAheadDays + 1, to: windowStart) else {
            return
        }
        loadingSchedules = true
        schedulesFailed = false
        do {
            let found = try await inbox.freeBusy(for: attendees, from: windowStart, to: windowEnd)
            guard !Task.isCancelled else { return }
            schedules = found
        } catch {
            guard !Task.isCancelled else { return }
            schedulesFailed = true
        }
        loadingSchedules = false
    }

    private func findOpening() {
        let calendar = Calendar.current
        let duration = TimeInterval(durationMinutes * 60)
        let all = Array(schedules.values)
        var day = calendar.startOfDay(for: .now)
        for _ in 0...Self.lookAheadDays {
            defer { day = calendar.date(byAdding: .day, value: 1, to: day) ?? day }
            guard !calendar.isDateInWeekend(day),
                  let open = calendar.date(bySettingHour: Self.workdayStartHour, minute: 0, second: 0, of: day),
                  let close = calendar.date(bySettingHour: Self.workdayEndHour, minute: 0, second: 0, of: day) else {
                continue
            }
            if let found = FreeBusy.firstCommonOpening(in: all, duration: duration,
                                                       notBefore: max(open, .now), notAfter: close) {
                start = found
                noOpening = false
                return
            }
        }
        noOpening = true
    }

    private func send() async {
        isSending = true
        errorMessage = nil
        do {
            try await inbox.scheduleMeeting(subject: subject.trimmingCharacters(in: .whitespacesAndNewlines),
                                            notes: notes, start: start, end: end,
                                            attendees: attendees, teams: teams)
            onClose()
        } catch {
            errorMessage = "Couldn't create the meeting. Check your connection and try again."
        }
        isSending = false
    }

    private static func color(for availability: Availability) -> Color {
        switch availability {
        case .free: .green
        case .workingElsewhere: .teal
        case .tentative: .yellow
        case .busy: .red
        case .away: .purple
        case .unknown: .gray
        }
    }

    private static func durationLabel(_ minutes: Int) -> String {
        minutes < 60 ? "\(minutes) min"
            : minutes % 60 == 0 ? "\(minutes / 60) hr" : "\(minutes / 60) hr \(minutes % 60) min"
    }

    static func nextHalfHour(after date: Date) -> Date {
        let slot: TimeInterval = 1800
        return Date(timeIntervalSinceReferenceDate: (date.timeIntervalSinceReferenceDate / slot).rounded(.up) * slot)
    }
}
