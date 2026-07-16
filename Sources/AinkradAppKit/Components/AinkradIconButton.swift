import SwiftUI

/// Square, icon-only Cardinal HUD button — chamfered corners, accent glow on
/// hover. Use for compact toolbar/utility actions.
public struct AinkradIconButton: View {
    private let systemName: String
    private let action: () -> Void

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false

    public init(systemName: String, action: @escaping () -> Void) {
        self.systemName = systemName; self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.foreground.opacity(hovering ? 1.0 : 0.75))
                .frame(width: 30, height: 30)
                .background(ChamferShape(cut: 6).fill(theme.surfaceElevated.opacity(hovering ? 0.7 : 0.4)))
                .overlay(ChamferShape(cut: 6).strokeBorder(theme.accentSecondary.opacity(hovering ? 0.85 : 0.35), lineWidth: 1))
                .shadow(color: theme.accentSecondary.opacity(hovering ? 0.5 : 0), radius: hovering ? 5 : 0)
                .contentShape(ChamferShape(cut: 6))
        }
        .buttonStyle(.plain)
        .scaleEffect(hovering && !reduceMotion ? 1.05 : 1.0)
        .animation(AinkradMotion.hover, value: hovering)
        .onHover { hovering = $0 }
    }
}

/// Latch-style toggle button — stays lit while `isOn` is true, distinct from
/// the switch-style `AinkradToggle`. Supply either (or both) of `systemName`
/// and `title`.
public struct AinkradToggleButton: View {
    @Binding private var isOn: Bool
    private let systemName: String?
    private let title: String?

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false

    public init(isOn: Binding<Bool>, systemName: String? = nil, title: String? = nil) {
        self._isOn = isOn; self.systemName = systemName; self.title = title
    }

    /// Mirrors the `isOn` binding — exposed for testing the latch state.
    public var isActive: Bool { isOn }

    public var body: some View {
        Button { isOn.toggle() } label: {
            HStack(spacing: AinkradSpacing.xs) {
                if let systemName {
                    Image(systemName: systemName).font(.system(size: 12, weight: .semibold))
                }
                if let title {
                    Text(title.uppercased())
                        .font(AinkradFontResolver.font(.caption, weight: .semibold, typography: typo))
                        .tracking(0.8)
                }
            }
            .foregroundStyle(isActive ? theme.accentPrimary.contrastingText : theme.foreground.opacity(0.75))
            .padding(.horizontal, AinkradSpacing.md)
            .padding(.vertical, AinkradSpacing.sm)
            .background(ChamferShape(cut: 6).fill(isActive ? theme.accentPrimary.opacity(0.85) : theme.surfaceElevated.opacity(hovering ? 0.6 : 0.4)))
            .overlay(ChamferShape(cut: 6).strokeBorder(theme.accentSecondary.opacity(isActive ? 0.95 : (hovering ? 0.6 : 0.3)), lineWidth: 1.25))
            .shadow(color: theme.accentSecondary.opacity(isActive ? 0.55 : 0), radius: isActive ? 5 : 0)
            .contentShape(ChamferShape(cut: 6))
        }
        .buttonStyle(.plain)
        .scaleEffect(hovering && !reduceMotion ? 1.02 : 1.0)
        .animation(AinkradMotion.hover, value: hovering)
        .animation(AinkradMotion.hover, value: isActive)
        .onHover { hovering = $0 }
    }
}
