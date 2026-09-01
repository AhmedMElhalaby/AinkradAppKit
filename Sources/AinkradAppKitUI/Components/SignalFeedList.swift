import SwiftUI
import AinkradAppKitContract
import AinkradSignal

/// Day-grouped list of events. Deliberately dumb: it owns no state and reads
/// no store, because both the bell popover and the in-window island embed it.
public struct SignalFeedList: View {
    public let events: [SignalEvent]
    public var repeatCounts: [UUID: Int] = [:]
    public var readIDs: Set<UUID> = []
    public var now: Date = Date()
    public var calendar: Calendar = .current
    public var onActivate: (SignalEvent) -> Void = { _ in }
    public var onAction: (SignalEvent, SignalAction) -> Void = { _, _ in }

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo

    private var groups: [SignalDayGroup] {
        SignalPresentation.dayGroups(events, calendar: calendar)
    }

    public var body: some View {
        if events.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AinkradSpacing.xs / 2,
                           pinnedViews: [.sectionHeaders]) {
                    ForEach(groups) { group in
                        Section {
                            ForEach(group.events) { event in
                                SignalFeedRow(event: event,
                                              repeatCount: repeatCounts[event.id] ?? 1,
                                              isUnread: !readIDs.contains(event.id),
                                              now: now,
                                              onActivate: onActivate,
                                              onAction: onAction)
                            }
                        } header: {
                            dayHeader(group.id)
                        }
                    }
                }
                .padding(.vertical, AinkradSpacing.xs + 2)
                .padding(.horizontal, AinkradSpacing.xs + 2)
            }
        }
    }

    /// A header, not a separator: the design language forbids rules, so the day
    /// break is carried by weight and a soft scrim behind the pinned label.
    private func dayHeader(_ day: Date) -> some View {
        // Mono, uppercase, tracked: a date is a readout, and this is the same
        // treatment the top bar gives the clock.
        Text(Self.dayLabel(day, now: now, calendar: calendar))
            .font(AinkradFontResolver.font(size: 9.5, weight: .semibold, mono: true, typography: typo))
            .foregroundStyle(theme.foreground.opacity(0.42))
            .textCase(.uppercase)
            .tracking(0.7)
            .padding(.horizontal, AinkradSpacing.md)
            .padding(.top, AinkradSpacing.sm + 2)
            .padding(.bottom, AinkradSpacing.xs)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.surface.opacity(0.92))
    }

    public static func dayLabel(_ day: Date, now: Date, calendar: Calendar) -> String {
        if calendar.isDate(day, inSameDayAs: now) { return "Today" }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now)),
           calendar.isDate(day, inSameDayAs: yesterday) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: day)
    }

    private var emptyState: some View {
        VStack(spacing: AinkradSpacing.xs + 2) {
            Image(systemName: "bell.slash")
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(theme.foreground.opacity(0.3))
            Text("Nothing yet")
                .font(AinkradFontResolver.font(size: 12, weight: .medium, typography: typo))
                .foregroundStyle(theme.foreground.opacity(0.55))
            AinkradCaption("Runs, builds and app events will show up here.")
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AinkradSpacing.xl + AinkradSpacing.sm)
    }
}
