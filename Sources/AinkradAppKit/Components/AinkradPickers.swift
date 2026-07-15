import SwiftUI

/// Index of `selection` within `items`, or nil. Pure — unit tested.
public func pickerSelectionIndex<T: Hashable>(items: [T], selection: T) -> Int? {
    items.firstIndex(of: selection)
}

/// Custom segmented control — chamfer segments with a luminous accent fill
/// on the selected item and a hover glow on the rest (never a native
/// `Picker`).
public struct AinkradSegmentedPicker<T: Hashable>: View {
    private let items: [T]
    @Binding private var selection: T
    private let label: (T) -> String
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @State private var hoveredItem: T?

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
        let hovered = hoveredItem == item
        Button { selection = item } label: {
            Text(label(item))
                .font(AinkradFontResolver.font(.caption, weight: selected ? .medium : .regular, typography: typo))
                .foregroundStyle(selected ? theme.accentPrimary.contrastingText : theme.foreground.opacity(0.75))
                .padding(.horizontal, AinkradSpacing.md).padding(.vertical, AinkradSpacing.xs + 2)
                .background(ChamferShape(cut: 5)
                    .fill(selected ? theme.accentPrimary.opacity(0.9) : theme.surfaceElevated.opacity(hovered ? 0.65 : 0.5)))
                .overlay(ChamferShape(cut: 5)
                    .strokeBorder(theme.accentPrimary.opacity(selected ? 0 : (hovered ? 0.5 : 0.15)), lineWidth: 1))
                .shadow(color: theme.accentPrimary.opacity(selected ? 0.4 : 0), radius: selected ? 5 : 0)
                .contentShape(ChamferShape(cut: 5))
        }
        .buttonStyle(.plain)
        .animation(AinkradMotion.hover, value: hovered)
        .onHover { hovering in hoveredItem = hovering ? item : (hoveredItem == item ? nil : hoveredItem) }
    }
}

/// Pairs each item with whether it is the current selection. Pure — the shape
/// `AinkradSelect`'s option rows are built from, unit-testable without SwiftUI.
public func selectOptionRows<T: Hashable>(items: [T], selected: T) -> [(item: T, isSelected: Bool)] {
    items.map { ($0, $0 == selected) }
}

/// Toggles `item`'s membership in `selection` — present items are removed,
/// absent items are added. Pure — the reducer `AinkradMultiSelect` rows call
/// on tap, unit-testable without SwiftUI.
public func toggledSelection<T: Hashable>(_ item: T, in selection: Set<T>) -> Set<T> {
    var result = selection
    if result.contains(item) { result.remove(item) } else { result.insert(item) }
    return result
}

/// Items whose `label` contains `query` (case-insensitive substring match).
/// An empty query returns every item unfiltered. Pure — `AinkradCombobox`'s
/// filtering logic, unit-testable without SwiftUI.
public func comboboxFilter<T>(items: [T], query: String, label: (T) -> String) -> [T] {
    guard !query.isEmpty else { return items }
    return items.filter { label($0).range(of: query, options: .caseInsensitive) != nil }
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
                        // Starts below the trigger (not covering it), so a
                        // click on the trigger itself still reaches the
                        // trigger's own Button rather than closing-then-reopening.
                        Color.black.opacity(0.0001)
                            .frame(width: 4000, height: 4000)
                            .offset(x: -2000, y: triggerHeight)
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

/// Multi-selection variant of `AinkradSelect` — same custom anchored overlay,
/// but tapping a row toggles its membership in `selection` (via
/// `toggledSelection`) instead of replacing it, and rows show a custom
/// checkmark glyph rather than a diamond. Same NO-native-menu contract.
public struct AinkradMultiSelect<T: Hashable>: View {
    private let items: [T]
    @Binding private var selection: Set<T>
    private let label: (T) -> String

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isOpen = false
    @State private var hoveredItem: T?
    @State private var triggerHeight: CGFloat = 0

    public init(items: [T], selection: Binding<Set<T>>, label: @escaping (T) -> String) {
        self.items = items; self._selection = selection; self.label = label
    }

    private var triggerText: String {
        selection.isEmpty ? "Select…" : items.filter(selection.contains).map(label).joined(separator: ", ")
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
                        Color.black.opacity(0.0001)
                            .frame(width: 4000, height: 4000)
                            .offset(x: -2000, y: triggerHeight)
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
                Text(triggerText)
                    .font(AinkradFontResolver.font(.body, typography: typo))
                    .foregroundStyle(theme.foreground)
                    .lineLimit(1)
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
        let isSelected = selection.contains(item)
        let isHovered = hoveredItem == item
        return Button {
            selection = toggledSelection(item, in: selection)
        } label: {
            HStack(spacing: AinkradSpacing.xs) {
                ZStack {
                    ChamferShape(cut: 2)
                        .strokeBorder(theme.accentSecondary.opacity(0.6), lineWidth: 1)
                        .frame(width: 12, height: 12)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(theme.accentSecondary)
                    }
                }
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

/// Text-entry + filtered custom option list. Typing filters `items` (via
/// `comboboxFilter`); picking a row sets both `selection` and `text`.
/// Freeform typing without a pick leaves `selection` nil. Custom overlay
/// only — no native menu/popover/list chrome.
public struct AinkradCombobox<T: Hashable>: View {
    private let items: [T]
    @Binding private var selection: T?
    @Binding private var text: String
    private let label: (T) -> String

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isFocused: Bool
    @State private var hoveredItem: T?
    @State private var fieldHeight: CGFloat = 0

    public init(items: [T], selection: Binding<T?>, text: Binding<String>, label: @escaping (T) -> String) {
        self.items = items; self._selection = selection; self._text = text; self.label = label
    }

    private var filtered: [T] { comboboxFilter(items: items, query: text, label: label) }
    private var isOpen: Bool { isFocused && !filtered.isEmpty }

    public var body: some View {
        field
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { fieldHeight = proxy.size.height }
                        .onChange(of: proxy.size.height) { _, newValue in fieldHeight = newValue }
                }
            )
            .overlay(alignment: .topLeading) {
                if isOpen {
                    ZStack(alignment: .topLeading) {
                        Color.black.opacity(0.0001)
                            .frame(width: 4000, height: 4000)
                            .offset(x: -2000, y: fieldHeight)
                            .contentShape(Rectangle())
                            .onTapGesture { isFocused = false }

                        optionsPanel
                            .offset(y: fieldHeight + AinkradSpacing.xs)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.96, anchor: .top)),
                                removal: .opacity
                            ))
                    }
                    .zIndex(1)
                }
            }
            .onKeyPress(.escape) {
                guard isFocused else { return .ignored }
                isFocused = false
                return .handled
            }
            .animation(reduceMotion ? nil : AinkradMotion.materialize, value: isOpen)
    }

    private var field: some View {
        TextField("", text: $text)
            .textFieldStyle(.plain)
            .focused($isFocused)
            .font(AinkradFontResolver.font(.body, typography: typo))
            .foregroundStyle(theme.foreground)
            .tint(theme.accentSecondary)
            .padding(.horizontal, AinkradSpacing.md)
            .padding(.vertical, AinkradSpacing.sm)
            .background(ChamferShape(cut: 8).fill(theme.surfaceElevated.opacity(0.5)))
            .overlay(ChamferShape(cut: 8).strokeBorder(theme.accentPrimary.opacity(isFocused ? 0.85 : 0.3), lineWidth: isFocused ? 1.5 : 1.25))
            .shadow(color: theme.accentPrimary.opacity(isFocused ? 0.45 : 0), radius: isFocused ? 6 : 0)
    }

    private var optionsPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(filtered, id: \.self) { item in optionRow(item) }
        }
        .padding(AinkradSpacing.xs)
        .background(ChamferShape(cut: 8).fill(theme.surfaceElevated.opacity(0.97)))
        .overlay(ChamferShape(cut: 8).strokeBorder(theme.accentSecondary.opacity(0.55), lineWidth: 1.25))
        .shadow(color: theme.accentSecondary.opacity(0.35), radius: 10, y: 4)
        .frame(minWidth: 160)
    }

    private func optionRow(_ item: T) -> some View {
        let isSelected = selection == item
        let isHovered = hoveredItem == item
        return Button {
            selection = item
            text = label(item)
            isFocused = false
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
