import SwiftUI
import AinkradAppKitContract

/// Toggles a command-menu selection: tapping the already-selected item clears
/// it, tapping any other item selects it. Pure — `AinkradCommandMenu`'s
/// single-select-with-deselect behavior, unit-testable without SwiftUI.
public func commandMenuToggled<T: Hashable>(_ item: T, current: T?) -> T? {
    current == item ? nil : item
}

/// Pairs each item with whether it's the current `selected` value. Pure —
/// `AinkradNavList`'s row model, unit-testable without SwiftUI.
public func navListRows<T: Hashable>(items: [T], selected: T) -> [(item: T, isSelected: Bool)] {
    items.map { ($0, $0 == selected) }
}

/// The SAO vertical menu-bar motif: a stack of chamfer buttons, each with a
/// leading icon and label, hover scan-line, and a glowing accent fill when
/// selected. `selection` is optional — tapping the selected row deselects it.
///
/// `detail` and `value` are additive, optional per-item slots (both default
/// to `nil`) for a secondary line (e.g. a breadcrumb) and a trailing value —
/// added so richer result lists (settings search) don't need a look-alike.
/// `uppercased` (default `true`, matching the original motif) turns off the
/// shouty label transform for content where sentence case matters. When
/// `items` isn't empty, ↑/↓ move a keyboard highlight independent of
/// `selection` and Return activates the highlighted row exactly as a tap
/// would. `emptyState` (default `nil`) renders in place of the row stack when
/// `items` is empty.
public struct AinkradCommandMenu<T: Hashable>: View {
    private let items: [T]
    @Binding private var selection: T?
    private let icon: (T) -> String
    private let label: (T) -> String
    private let detail: ((T) -> String?)?
    private let value: ((T) -> String?)?
    private let uppercased: Bool
    private let emptyState: (() -> AnyView)?

    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var highlightedIndex = 0

    public init(
        items: [T],
        selection: Binding<T?>,
        icon: @escaping (T) -> String,
        label: @escaping (T) -> String,
        detail: ((T) -> String?)? = nil,
        value: ((T) -> String?)? = nil,
        uppercased: Bool = true,
        emptyState: (() -> AnyView)? = nil
    ) {
        self.items = items
        self._selection = selection
        self.icon = icon
        self.label = label
        self.detail = detail
        self.value = value
        self.uppercased = uppercased
        self.emptyState = emptyState
    }

    public var body: some View {
        if items.isEmpty, let emptyState {
            emptyState()
        } else {
            VStack(spacing: AinkradSpacing.xs) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    AinkradCommandMenuRow(
                        icon: icon(item),
                        label: label(item),
                        detail: detail.flatMap { $0(item) },
                        value: value.flatMap { $0(item) },
                        uppercased: uppercased,
                        isSelected: item == selection,
                        isHighlighted: index == highlightedIndex
                    ) {
                        activate(item)
                    }
                }
            }
            .onKeyPress(.downArrow) {
                highlightedIndex = min(highlightedIndex + 1, items.count - 1); return .handled
            }
            .onKeyPress(.upArrow) {
                highlightedIndex = max(highlightedIndex - 1, 0); return .handled
            }
            .onKeyPress(.return) {
                guard items.indices.contains(highlightedIndex) else { return .ignored }
                activate(items[highlightedIndex]); return .handled
            }
            .onChange(of: items.count) { _, newCount in
                highlightedIndex = min(highlightedIndex, max(newCount - 1, 0))
            }
        }
    }

    private func activate(_ item: T) {
        let next = commandMenuToggled(item, current: selection)
        if reduceMotion {
            selection = next
        } else {
            withAnimation(AinkradMotion.materialize) { selection = next }
        }
    }
}

private struct AinkradCommandMenuRow: View {
    let icon: String
    let label: String
    let detail: String?
    let value: String?
    let uppercased: Bool
    let isSelected: Bool
    let isHighlighted: Bool
    let action: () -> Void

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false

    private var emphasized: Bool { hovering || isHighlighted }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AinkradSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 18)
                VStack(alignment: .leading, spacing: AinkradSpacing.xs / 2) {
                    Text(uppercased ? label.uppercased() : label)
                        .font(AinkradFontResolver.font(.caption, weight: .semibold, typography: typo))
                        .tracking(uppercased ? 0.6 : 0)
                    if let detail {
                        Text(detail)
                            .font(AinkradFontResolver.font(.mono, typography: typo))
                            .foregroundStyle(theme.foreground.opacity(0.45))
                    }
                }
                Spacer(minLength: AinkradSpacing.sm)
                if let value, !value.isEmpty {
                    Text(value)
                        .font(AinkradFontResolver.font(.mono, typography: typo))
                        .foregroundStyle(theme.accentSecondary.opacity(0.85))
                }
            }
            .foregroundStyle(isSelected ? theme.accentPrimary.contrastingText : theme.foreground.opacity(emphasized ? 0.9 : 0.65))
            .padding(.horizontal, AinkradSpacing.md)
            .padding(.vertical, AinkradSpacing.sm)
            .background(
                ChamferShape(cut: 6)
                    .fill(isSelected ? theme.accentPrimary.opacity(0.85) : theme.surfaceElevated.opacity(emphasized ? 0.5 : 0.2))
            )
            .overlay(
                ChamferShape(cut: 6)
                    .strokeBorder(theme.accentSecondary.opacity(isSelected ? 0.9 : (emphasized ? 0.5 : 0)), lineWidth: 1.25)
            )
            .shadow(color: theme.accentSecondary.opacity(isSelected ? 0.5 : 0), radius: isSelected ? 5 : 0)
            .scanlineOverlay(active: hovering && !isSelected)
            .contentShape(ChamferShape(cut: 6))
        }
        .buttonStyle(.plain)
        .scaleEffect(hovering && !reduceMotion ? 1.015 : 1.0)
        .animation(AinkradMotion.hover, value: hovering)
        .onHover { hovering = $0 }
    }
}

/// Sidebar-style navigation list — single-select rows, an accent bar leading
/// the selected row, and no divider lines between rows.
public struct AinkradNavList<T: Hashable>: View {
    private let items: [T]
    @Binding private var selection: T
    private let icon: (T) -> String?
    private let label: (T) -> String

    @Environment(\.ainkradReduceMotion) private var reduceMotion

    public init(items: [T], selection: Binding<T>, icon: @escaping (T) -> String?, label: @escaping (T) -> String) {
        self.items = items
        self._selection = selection
        self.icon = icon
        self.label = label
    }

    public var body: some View {
        VStack(spacing: AinkradSpacing.xs / 2) {
            ForEach(navListRows(items: items, selected: selection), id: \.item) { row in
                AinkradNavListRow(icon: icon(row.item), label: label(row.item), isSelected: row.isSelected) {
                    if reduceMotion {
                        selection = row.item
                    } else {
                        withAnimation(AinkradMotion.materialize) { selection = row.item }
                    }
                }
            }
        }
    }
}

private struct AinkradNavListRow: View {
    let icon: String?
    let label: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: AinkradSpacing.sm) {
                Rectangle()
                    .fill(theme.accentSecondary)
                    .frame(width: 2)
                    .opacity(isSelected ? 1 : 0)
                    .shadow(color: theme.accentSecondary.opacity(isSelected ? 0.6 : 0), radius: 2)
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 16)
                }
                Text(label)
                    .font(AinkradFontResolver.font(.body, weight: isSelected ? .semibold : .regular, typography: typo))
                Spacer(minLength: 0)
            }
            .foregroundStyle(isSelected ? theme.foreground : theme.foreground.opacity(hovering ? 0.85 : 0.6))
            .padding(.vertical, AinkradSpacing.sm)
            .padding(.horizontal, AinkradSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AinkradRadius.sm)
                    .fill(isSelected ? theme.surfaceElevated.opacity(0.6) : (hovering ? theme.surfaceElevated.opacity(0.3) : .clear))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(AinkradMotion.hover, value: hovering)
        .onHover { hovering = $0 }
    }
}
