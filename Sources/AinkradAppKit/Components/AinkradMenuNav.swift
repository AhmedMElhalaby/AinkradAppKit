import SwiftUI

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
public struct AinkradCommandMenu<T: Hashable>: View {
    private let items: [T]
    @Binding private var selection: T?
    private let icon: (T) -> String
    private let label: (T) -> String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(items: [T], selection: Binding<T?>, icon: @escaping (T) -> String, label: @escaping (T) -> String) {
        self.items = items
        self._selection = selection
        self.icon = icon
        self.label = label
    }

    public var body: some View {
        VStack(spacing: AinkradSpacing.xs) {
            ForEach(items, id: \.self) { item in
                AinkradCommandMenuRow(icon: icon(item), label: label(item), isSelected: item == selection) {
                    let next = commandMenuToggled(item, current: selection)
                    if reduceMotion {
                        selection = next
                    } else {
                        withAnimation(AinkradMotion.materialize) { selection = next }
                    }
                }
            }
        }
    }
}

private struct AinkradCommandMenuRow: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: AinkradSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 18)
                Text(label.uppercased())
                    .font(AinkradFontResolver.font(.caption, weight: .semibold, typography: typo))
                    .tracking(0.6)
                Spacer(minLength: 0)
            }
            .foregroundStyle(isSelected ? theme.accentPrimary.contrastingText : theme.foreground.opacity(hovering ? 0.9 : 0.65))
            .padding(.horizontal, AinkradSpacing.md)
            .padding(.vertical, AinkradSpacing.sm)
            .background(
                ChamferShape(cut: 6)
                    .fill(isSelected ? theme.accentPrimary.opacity(0.85) : theme.surfaceElevated.opacity(hovering ? 0.5 : 0.2))
            )
            .overlay(
                ChamferShape(cut: 6)
                    .strokeBorder(theme.accentSecondary.opacity(isSelected ? 0.9 : (hovering ? 0.5 : 0)), lineWidth: 1.25)
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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
