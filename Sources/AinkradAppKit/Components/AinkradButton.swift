import SwiftUI

/// Visual treatment for `AinkradButton`. Pure mapping to fill/border/danger
/// intent so the logic is unit-testable without instantiating any SwiftUI view.
public enum AinkradButtonStyle: CaseIterable, Sendable {
    case primary, secondary, ghost, danger

    /// Whether this style paints a solid accent-tinted fill (vs. border-only).
    public var usesAccentFill: Bool {
        switch self {
        case .primary, .danger: return true
        case .secondary, .ghost: return false
        }
    }

    /// Opacity of the background fill; `0` for border-only styles (e.g. `ghost`).
    public var fillOpacity: Double {
        switch self {
        case .primary: return 0.9
        case .secondary: return 0.5
        case .ghost: return 0
        case .danger: return 0.85
        }
    }

    /// Whether this style should read using the theme's `danger` color.
    public var isDanger: Bool {
        self == .danger
    }
}

/// Cardinal HUD action button — chamfered silhouette, accent glow, hover
/// brighten, and a subtle press scale. Reads all color from
/// `@Environment(\.ainkradTheme)`; `danger` uses `ainkradStatusColors.danger`.
public struct AinkradButton: View {
    private let title: String
    private let style: AinkradButtonStyle
    private let icon: String?
    private let action: () -> Void

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradStatusColors) private var statusColors
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovering = false
    @State private var pressed = false

    public init(title: String, style: AinkradButtonStyle = .primary, icon: String? = nil,
                action: @escaping () -> Void) {
        self.title = title; self.style = style; self.icon = icon; self.action = action
    }

    private var accentColor: Color { style.isDanger ? statusColors.danger : theme.accentPrimary }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: AinkradSpacing.xs) {
                if let icon {
                    Image(systemName: icon).font(.system(size: 12, weight: .semibold))
                }
                Text(title.uppercased())
                    .font(AinkradFontResolver.font(.caption, weight: .semibold, typography: typo))
                    .tracking(0.8)
            }
            .foregroundStyle(style.usesAccentFill ? accentColor.contrastingText : accentColor)
            .padding(.horizontal, AinkradSpacing.lg)
            .padding(.vertical, AinkradSpacing.sm)
            .background(
                ChamferShape(cut: 8)
                    .fill(style.usesAccentFill ? accentColor.opacity(style.fillOpacity) : .clear)
            )
            .overlay(
                ChamferShape(cut: 8)
                    .strokeBorder(accentColor.opacity(hovering ? 0.95 : 0.55), lineWidth: 1.25)
            )
            .shadow(color: accentColor.opacity(hovering ? 0.55 : 0), radius: hovering ? 6 : 0)
            .contentShape(ChamferShape(cut: 8))
        }
        .buttonStyle(.plain)
        .scaleEffect(pressed && !reduceMotion ? 0.97 : (hovering && !reduceMotion ? 1.02 : 1.0))
        .animation(AinkradMotion.hover, value: hovering)
        .animation(AinkradMotion.hover, value: pressed)
        .onHover { hovering = $0 }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
    }
}
