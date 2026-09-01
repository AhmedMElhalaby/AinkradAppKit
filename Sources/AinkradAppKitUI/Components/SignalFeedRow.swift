import SwiftUI
import AinkradAppKitContract
import AinkradSignal

public struct SignalDayGroup: Identifiable, Equatable {
    public let id: Date          // start of day
    public let events: [SignalEvent]
}

/// Pure presentation helpers, kept out of the `View` so they are testable
/// without rendering. Anything that needs a clock takes it as a parameter —
/// no `Date()` inside a formatter.
public enum SignalPresentation {
    public static func relativeTime(_ date: Date, now: Date) -> String {
        let elapsed = max(0, now.timeIntervalSince(date))
        switch elapsed {
        case ..<60: return "now"
        case ..<3600: return "\(Int(elapsed / 60))m"
        case ..<86400: return "\(Int(elapsed / 3600))h"
        default: return "\(Int(elapsed / 86400))d"
        }
    }

    public static func dayGroups(_ events: [SignalEvent], calendar: Calendar) -> [SignalDayGroup] {
        let sorted = events.sorted { $0.timestamp > $1.timestamp }
        var order: [Date] = []
        var buckets: [Date: [SignalEvent]] = [:]
        for event in sorted {
            let day = calendar.startOfDay(for: event.timestamp)
            if buckets[day] == nil { order.append(day) }
            buckets[day, default: []].append(event)
        }
        return order.map { SignalDayGroup(id: $0, events: buckets[$0] ?? []) }
    }

    public static func iconSymbol(for severity: SignalSeverity) -> String {
        switch severity {
        case .info: return "info.circle"
        case .success: return "checkmark.circle"
        case .warning: return "exclamationmark.triangle"
        case .failure: return "xmark.octagon"
        @unknown default: return "info.circle"
        }
    }

    /// Severity in the kit's own vocabulary, so Signal colours itself from the
    /// same `AinkradStatus` ramp every other component uses instead of a
    /// parallel palette of its own.
    ///
    /// `.info` maps to `.neutral` rather than a tinted success: an informational
    /// event is not a small success, and rendering it green said it was.
    public static func status(for severity: SignalSeverity) -> AinkradStatus {
        switch severity {
        case .info: return .neutral
        case .success: return .success
        case .warning: return .warning
        case .failure: return .danger
        @unknown default: return .neutral
        }
    }

    public static func color(for severity: SignalSeverity, in status: AinkradStatusColors) -> Color {
        switch severity {
        case .success: return status.success
        case .warning: return status.warning
        case .failure: return status.danger
        case .info: return status.success.opacity(0.55)
        @unknown default: return status.success.opacity(0.55)
        }
    }

    public static func sourceLabel(_ source: SignalSource) -> String {
        switch source {
        case .host: return "Ainkrad"
        case .sage: return "Sage"
        case .app(let id): return id.split(separator: ".").last.map(String.init)?.capitalized ?? id
        @unknown default: return "Ainkrad"
        }
    }
}

/// One event, in the house style: Exo 2 for prose, JetBrains Mono for the
/// readout, `ChamferShape` for every surface, and the `AinkradStatus` ramp for
/// severity. No separator lines — separation is spacing plus the elevated
/// surface on hover.
public struct SignalFeedRow: View {
    public let event: SignalEvent
    public var repeatCount: Int = 1
    public var isUnread: Bool = true
    public var now: Date = Date()
    public var onActivate: (SignalEvent) -> Void = { _ in }
    public var onAction: (SignalEvent, SignalAction) -> Void = { _, _ in }

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradStatusColors) private var statusColors
    @State private var isHovered = false

    private var status: AinkradStatus { SignalPresentation.status(for: event.severity) }
    private var accent: Color { status.color(in: theme, statusColors: statusColors) }

    public var body: some View {
        HStack(alignment: .top, spacing: AinkradSpacing.sm) {
            // Its own layer: the glyph lifts on hover rather than the whole row
            // sliding as one image.
            Image(systemName: SignalPresentation.iconSymbol(for: event.severity))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(accent)
                .frame(width: 16, height: 16)
                .scaleEffect(isHovered ? 1.12 : 1)
                .offset(y: isHovered ? -1 : 0)

            VStack(alignment: .leading, spacing: AinkradSpacing.xs / 2) {
                HStack(spacing: AinkradSpacing.xs + 2) {
                    Text(event.title)
                        .font(AinkradFontResolver.font(size: 12.5, weight: isUnread ? .semibold : .regular, typography: typo))
                        .foregroundStyle(theme.foreground)
                        .lineLimit(1)
                    if repeatCount > 1 {
                        AinkradBadge(text: "×\(repeatCount)", status: status)
                    }
                    Spacer(minLength: AinkradSpacing.xs)
                    // A readout, so mono — the same language as the clock and
                    // battery in the top bar.
                    Text(SignalPresentation.relativeTime(event.timestamp, now: now))
                        .font(AinkradFontResolver.font(size: 10, weight: .medium, mono: true, typography: typo))
                        .foregroundStyle(theme.foreground.opacity(0.45))
                }

                if let body = event.body, !body.isEmpty {
                    Text(body)
                        .font(AinkradFontResolver.font(size: 11.5, typography: typo))
                        .foregroundStyle(theme.foreground.opacity(0.62))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: AinkradSpacing.xs + 2) {
                    Text(SignalPresentation.sourceLabel(event.source))
                        .font(AinkradFontResolver.font(size: 9.5, weight: .medium, mono: true, typography: typo))
                        .foregroundStyle(theme.foreground.opacity(0.45))
                        .tracking(0.4)
                    ForEach(event.actions, id: \.id) { action in
                        rowAction(action)
                    }
                }
            }

            // The column is always reserved, even when read: letting it
            // collapse pulled read rows' timestamps further right than unread
            // ones, so a column that should read as a straight edge zig-zagged.
            Circle()
                .fill(accent)
                .frame(width: 5, height: 5)
                .opacity(isUnread ? 1 : 0)
                .padding(.top, 6)
        }
        .padding(.horizontal, AinkradSpacing.md)
        .padding(.vertical, AinkradSpacing.sm + 1)
        .background(
            ChamferShape(cut: AinkradRadius.sm)
                .fill(theme.surfaceElevated.opacity(isHovered ? 0.9 : 0))
        )
        .overlay(
            ChamferShape(cut: AinkradRadius.sm)
                .strokeBorder(theme.accentSecondary.opacity(isHovered ? 0.35 : 0), lineWidth: 1)
        )
        .contentShape(ChamferShape(cut: AinkradRadius.sm))
        .onTapGesture { onActivate(event) }
        .onHover { hovering in
            withAnimation(AinkradMotion.hover) { isHovered = hovering }
        }
    }

    /// Inline action. `AinkradButton` is the right control for a footer or a
    /// dialog, but its `AinkradSpacing.lg` padding is far too heavy for a row,
    /// so this is built from the same primitives it uses — `ChamferShape`, the
    /// spacing ramp, the brand face — rather than a raw capsule.
    private func rowAction(_ action: SignalAction) -> some View {
        let tint = action.isDestructive ? statusColors.danger : theme.accentPrimary
        return Button { onAction(event, action) } label: {
            Text(action.label)
                .font(AinkradFontResolver.font(size: 10.5, weight: .medium, typography: typo))
                .foregroundStyle(tint)
                .padding(.horizontal, AinkradSpacing.sm)
                .padding(.vertical, AinkradSpacing.xs / 2)
                .background(ChamferShape(cut: 4).fill(tint.opacity(0.14)))
                .overlay(ChamferShape(cut: 4).strokeBorder(tint.opacity(0.5), lineWidth: 1))
                .contentShape(ChamferShape(cut: 4))
        }
        .buttonStyle(.plain)
    }
}
