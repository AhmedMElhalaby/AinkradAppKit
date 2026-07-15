import SwiftUI

/// The shared HUD panel finish: blur backing + translucent theme background +
/// chamfered clip + luminous accent stroke + optional corner brackets +
/// elevation glow. Generalizes the host's `hudPanelChrome`. Reads the theme
/// from `@Environment(\.ainkradTheme)`.
public struct AinkradPanel<Content: View>: View {
    private let blur: AinkradBlurLevel
    private let backgroundOpacity: Double
    private let showsBrackets: Bool
    private let content: Content
    @Environment(\.ainkradTheme) private var theme

    public init(blur: AinkradBlurLevel = .panel, backgroundOpacity: Double = 0.94,
                showsBrackets: Bool = false,
                @ViewBuilder content: () -> Content) {
        self.blur = blur; self.backgroundOpacity = backgroundOpacity
        self.showsBrackets = showsBrackets; self.content = content()
    }
    public var body: some View {
        content
            .background { ZStack { VisualEffectBlur(level: blur); theme.background.opacity(backgroundOpacity) } }
            .clipShape(ChamferShape(cut: AinkradRadius.panel))
            .overlay(
                ChamferShape(cut: AinkradRadius.panel)
                    .strokeBorder(theme.accentSecondary.opacity(0.4), lineWidth: 1)
            )
            .apply { showsBrackets ? AnyView($0.cornerBrackets()) : AnyView($0) }
            .glowBloom()
    }
}

public extension View {
    func ainkradPanel(blur: AinkradBlurLevel = .panel, backgroundOpacity: Double = 0.94,
                       showsBrackets: Bool = false) -> some View {
        AinkradPanel(blur: blur, backgroundOpacity: backgroundOpacity, showsBrackets: showsBrackets) { self }
    }
}
