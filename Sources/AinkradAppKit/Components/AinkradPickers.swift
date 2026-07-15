import SwiftUI

/// Index of `selection` within `items`, or nil. Pure — unit tested.
public func pickerSelectionIndex<T: Hashable>(items: [T], selection: T) -> Int? {
    items.firstIndex(of: selection)
}

public struct AinkradSegmentedPicker<T: Hashable>: View {
    private let items: [T]
    @Binding private var selection: T
    private let label: (T) -> String
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo

    public init(items: [T], selection: Binding<T>, label: @escaping (T) -> String) {
        self.items = items; self._selection = selection; self.label = label
    }
    public var body: some View {
        // Refresh: horizontal scroll prevents the overflow-clipping bug.
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AinkradSpacing.xs + 2) {
                ForEach(items, id: \.self) { item in segment(item) }
            }
        }
        .animation(AinkradMotion.hover, value: selection)
    }
    @ViewBuilder private func segment(_ item: T) -> some View {
        let selected = item == selection
        Button { selection = item } label: {
            Text(label(item))
                .font(AinkradFontResolver.font(.caption, weight: selected ? .medium : .regular, typography: typo))
                .foregroundStyle(selected ? theme.accentPrimary.contrastingText : theme.foreground.opacity(0.75))
                .padding(.horizontal, AinkradSpacing.md).padding(.vertical, AinkradSpacing.xs + 2)
                .background(RoundedRectangle(cornerRadius: AinkradRadius.sm)
                    .fill(selected ? theme.accentPrimary.opacity(0.9) : theme.surfaceElevated.opacity(0.5)))
                .overlay(RoundedRectangle(cornerRadius: AinkradRadius.sm)
                    .strokeBorder(theme.accentPrimary.opacity(selected ? 0 : 0.15), lineWidth: 1))
                .contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
}

/// Pairs each item with whether it is the current selection. Pure — the shape
/// `AinkradSelect`'s option rows are built from, unit-testable without SwiftUI.
public func selectOptionRows<T: Hashable>(items: [T], selected: T) -> [(item: T, isSelected: Bool)] {
    items.map { ($0, $0 == selected) }
}

/// Custom Cardinal HUD dropdown — chamfer trigger field + an anchored,
/// custom-drawn option panel (never a native `Menu`/`Picker`/`.popover`).
/// Dismisses on selection, outside tap, or Esc. `isOpen` materializes the
/// panel in via `AinkradMotion`.
///
/// v1 anchoring caveat: the panel is a same-tree `.overlay`, so it can be
/// clipped by an ancestor that clips its bounds (e.g. `.clipShape` on a
/// parent card). Fine for the Gallery's flat layout; a window-level
/// presentation would be needed for tightly-clipped containers.
public struct AinkradSelect<T: Hashable>: View {
    private let items: [T]
    @Binding private var selection: T
    private let label: (T) -> String

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isOpen = false
    @State private var hoveredItem: T?
    @State private var triggerHeight: CGFloat = 0

    public init(items: [T], selection: Binding<T>, label: @escaping (T) -> String) {
        self.items = items; self._selection = selection; self.label = label
    }

    public var body: some View {
        trigger
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { triggerHeight = proxy.size.height }
                        .onChange(of: proxy.size.height) { _, newValue in triggerHeight = newValue }
                }
            )
            .overlay(alignment: .topLeading) {
                if isOpen {
                    ZStack(alignment: .topLeading) {
                        // Oversized, near-invisible tap catcher so an outside
                        // tap dismisses the panel. Sits in the overlay layer,
                        // so it doesn't affect this view's reported size.
                        Color.black.opacity(0.0001)
                            .frame(width: 4000, height: 4000)
                            .offset(x: -2000, y: -2000)
                            .contentShape(Rectangle())
                            .onTapGesture { close() }

                        optionsPanel
                            .offset(y: triggerHeight + AinkradSpacing.xs)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.96, anchor: .top)),
                                removal: .opacity
                            ))
                    }
                    .zIndex(1)
                }
            }
            .onKeyPress(.escape) {
                guard isOpen else { return .ignored }
                close()
                return .handled
            }
    }

    private func open() {
        withAnimation(reduceMotion ? nil : AinkradMotion.materialize) { isOpen = true }
    }
    private func close() {
        withAnimation(reduceMotion ? nil : AinkradMotion.dismiss) { isOpen = false }
    }

    private var trigger: some View {
        Button {
            isOpen ? close() : open()
        } label: {
            HStack(spacing: AinkradSpacing.xs) {
                Text(label(selection))
                    .font(AinkradFontResolver.font(.body, typography: typo))
                    .foregroundStyle(theme.foreground)
                Spacer(minLength: AinkradSpacing.sm)
                Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(theme.accentSecondary.opacity(0.85))
            }
            .padding(.horizontal, AinkradSpacing.md)
            .padding(.vertical, AinkradSpacing.sm)
            .background(ChamferShape(cut: 8).fill(theme.surfaceElevated.opacity(0.5)))
            .overlay(ChamferShape(cut: 8).strokeBorder(theme.accentPrimary.opacity(isOpen ? 0.75 : 0.3), lineWidth: 1.25))
            .shadow(color: theme.accentPrimary.opacity(isOpen ? 0.4 : 0), radius: isOpen ? 5 : 0)
            .contentShape(ChamferShape(cut: 8))
        }
        .buttonStyle(.plain)
        .animation(AinkradMotion.hover, value: isOpen)
    }

    private var optionsPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(items, id: \.self) { item in optionRow(item) }
        }
        .padding(AinkradSpacing.xs)
        .background(ChamferShape(cut: 8).fill(theme.surfaceElevated.opacity(0.97)))
        .overlay(ChamferShape(cut: 8).strokeBorder(theme.accentSecondary.opacity(0.55), lineWidth: 1.25))
        .shadow(color: theme.accentSecondary.opacity(0.35), radius: 10, y: 4)
        .frame(minWidth: 160)
    }

    private func optionRow(_ item: T) -> some View {
        let isSelected = item == selection
        let isHovered = hoveredItem == item
        return Button {
            selection = item
            close()
        } label: {
            HStack(spacing: AinkradSpacing.xs) {
                Image(systemName: "diamond.fill")
                    .font(.system(size: 6))
                    .foregroundStyle(theme.accentSecondary)
                    .opacity(isSelected ? 1 : 0)
                Text(label(item))
                    .font(AinkradFontResolver.font(.body, typography: typo))
                    .foregroundStyle(theme.foreground)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, AinkradSpacing.sm)
            .padding(.vertical, AinkradSpacing.xs + 2)
            .background(ChamferShape(cut: 4).fill(isHovered ? theme.accentSecondary.opacity(0.18) : .clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(AinkradMotion.hover, value: isHovered)
        .onHover { hovering in hoveredItem = hovering ? item : (hoveredItem == item ? nil : hoveredItem) }
    }
}
