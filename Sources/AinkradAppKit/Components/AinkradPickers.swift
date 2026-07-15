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

public struct AinkradMenuPicker<T: Hashable>: View {
    private let items: [T]
    @Binding private var selection: T
    private let label: (T) -> String
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo

    public init(items: [T], selection: Binding<T>, label: @escaping (T) -> String) {
        self.items = items; self._selection = selection; self.label = label
    }
    public var body: some View {
        Menu {
            ForEach(items, id: \.self) { item in
                Button(label(item)) { selection = item }
            }
        } label: {
            HStack(spacing: AinkradSpacing.xs) {
                Text(label(selection)).font(AinkradFontResolver.font(.body, typography: typo))
                Image(systemName: "chevron.up.chevron.down").font(.system(size: 10))
            }
            .foregroundStyle(theme.foreground)
            .padding(.horizontal, AinkradSpacing.md).padding(.vertical, AinkradSpacing.sm)
            .background(RoundedRectangle(cornerRadius: AinkradRadius.sm).fill(theme.surfaceElevated.opacity(0.5)))
            .overlay(RoundedRectangle(cornerRadius: AinkradRadius.sm).strokeBorder(theme.accentPrimary.opacity(0.15), lineWidth: 1))
        }
        .menuStyle(.borderlessButton)
    }
}
