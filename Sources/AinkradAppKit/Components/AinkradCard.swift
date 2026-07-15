import SwiftUI

/// Surface-elevated rounded container with hover + selected states.
/// Consolidates AppStoreCard / ToolCallCard / connection rows.
public struct AinkradCard<Content: View>: View {
    private let isSelected: Bool
    private let onTap: (() -> Void)?
    private let content: Content
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovering = false

    public init(isSelected: Bool = false, onTap: (() -> Void)? = nil,
                @ViewBuilder content: () -> Content) {
        self.isSelected = isSelected; self.onTap = onTap; self.content = content()
    }
    /// Whether the card routes taps (drives accessibility + hit testing).
    public var isInteractive: Bool { onTap != nil }

    public var body: some View {
        content
            .padding(AinkradSpacing.md)
            .background(RoundedRectangle(cornerRadius: AinkradRadius.md).fill(theme.surface.opacity(0.9)))
            .overlay(RoundedRectangle(cornerRadius: AinkradRadius.md)
                .strokeBorder(theme.foreground.opacity(borderOpacity), lineWidth: 1))
            .overlay(selectionRing)
            .scaleEffect(hovering && !reduceMotion ? 1.01 : 1.0)
            .animation(AinkradMotion.hover, value: hovering)
            .contentShape(Rectangle())
            .onHover { hovering = $0 }
            .apply { if let onTap { $0.onTapGesture(perform: onTap) } else { $0 } }
    }
    private var borderOpacity: Double { isSelected ? 0.0 : (hovering ? 0.22 : 0.10) }
    @ViewBuilder private var selectionRing: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: AinkradRadius.md).strokeBorder(theme.accentPrimary.opacity(0.8), lineWidth: 1.5)
        }
    }
}

// Small helper so the conditional tap gesture stays readable.
extension View { @ViewBuilder func apply<V: View>(@ViewBuilder _ t: (Self) -> V) -> some View { t(self) } }
