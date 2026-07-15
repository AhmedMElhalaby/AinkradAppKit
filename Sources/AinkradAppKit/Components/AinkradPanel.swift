import SwiftUI

/// The shared HUD panel finish: blur backing + translucent theme background +
/// rounded clip + edge-ring + elevation glow. Generalizes the host's
/// `hudPanelChrome`. Reads the theme from `@Environment(\.ainkradTheme)`.
public struct AinkradPanel<Content: View>: View {
    private let blur: AinkradBlurLevel
    private let backgroundOpacity: Double
    private let content: Content
    @Environment(\.ainkradTheme) private var theme

    public init(blur: AinkradBlurLevel = .panel, backgroundOpacity: Double = 0.94,
                @ViewBuilder content: () -> Content) {
        self.blur = blur; self.backgroundOpacity = backgroundOpacity; self.content = content()
    }
    public var body: some View {
        content
            .background { ZStack { VisualEffectBlur(level: blur); theme.background.opacity(backgroundOpacity) } }
            .clipShape(RoundedRectangle(cornerRadius: AinkradRadius.panel))
            .ainkradEdgeRing(radius: AinkradRadius.panel)
            .ainkradPanelGlow()
    }
}

public extension View {
    func ainkradPanel(blur: AinkradBlurLevel = .panel, backgroundOpacity: Double = 0.94) -> some View {
        AinkradPanel(blur: blur, backgroundOpacity: backgroundOpacity) { self }
    }
}
