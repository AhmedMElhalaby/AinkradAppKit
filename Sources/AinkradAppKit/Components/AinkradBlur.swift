import SwiftUI
import AppKit

public enum AinkradBlurLevel: Equatable, Sendable {
    case panel, hud
    public var material: NSVisualEffectView.Material {
        switch self {
        case .panel: return .hudWindow
        case .hud:   return .fullScreenUI
        }
    }
}

/// Blurs the app content behind the view. Ported from the host so plugins get
/// the identical panel backing.
///
/// `blendingMode` defaults to `.withinWindow` (blur other layers within this
/// same window — the usual in-app panel look) but a modal presented in its
/// own top-level window (e.g. a floating panel from
/// `View.ainkradFloatingPanel(...)`) needs `.behindWindow` instead, so it
/// samples the parent window's content sitting behind it rather than its own
/// near-empty panel window.
public struct VisualEffectBlur: NSViewRepresentable {
    public var level: AinkradBlurLevel = .panel
    public var blendingMode: NSVisualEffectView.BlendingMode = .withinWindow
    public init(level: AinkradBlurLevel = .panel, blendingMode: NSVisualEffectView.BlendingMode = .withinWindow) {
        self.level = level
        self.blendingMode = blendingMode
    }
    public func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = level.material
        v.blendingMode = blendingMode
        v.state = .active
        return v
    }
    public func updateNSView(_ v: NSVisualEffectView, context: Context) {
        v.material = level.material
        v.blendingMode = blendingMode
    }
}

private struct EdgeRing: ViewModifier {
    let radius: CGFloat
    @Environment(\.ainkradTheme) private var theme
    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: radius)
                .strokeBorder(
                    LinearGradient(colors: [theme.accentSecondary.opacity(0.45),
                                            theme.accentPrimary.opacity(0.18)],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: 1)
        )
    }
}

private struct PanelGlow: ViewModifier {
    @Environment(\.ainkradTheme) private var theme
    func body(content: Content) -> some View {
        content
            .shadow(color: theme.accentPrimary.opacity(0.28), radius: AinkradElevation.level2.radius)
            .shadow(color: AinkradElevation.level2.color, radius: 20, y: 8)
    }
}

public extension View {
    /// The shared 1-pt gradient edge highlight used by panels and cards.
    func ainkradEdgeRing(radius: CGFloat = AinkradRadius.panel) -> some View { modifier(EdgeRing(radius: radius)) }
    /// The shared two-layer accent glow + contact shadow for elevated panels.
    func ainkradPanelGlow() -> some View { modifier(PanelGlow()) }
}
