import SwiftUI

/// Typography context injected alongside the theme: an optional brand font
/// family (nil = system) and the user's UI font scale.
public struct AinkradTypography: Equatable, Sendable {
    public var fontFamilyName: String?
    public var scale: CGFloat
    public init(fontFamilyName: String? = nil, scale: CGFloat = 1.0) {
        self.fontFamilyName = fontFamilyName
        self.scale = scale
    }
    public static let `default` = AinkradTypography()
}

public extension EnvironmentValues {
    /// The resolved host theme colors. Host/plugins set this at their root;
    /// SDK components read it. Default is a neutral dark fallback so previews
    /// and un-hosted use still render.
    @Entry var ainkradTheme: HostThemeTokens = .fallbackDark
    @Entry var ainkradTypography: AinkradTypography = .default
}


public extension HostThemeTokens {
    /// Neutral dark fallback for previews / when no host injects a theme.
    static let fallbackDark = HostThemeTokens(
        themeID: "fallback",
        background: Color(red: 0.04, green: 0.05, blue: 0.09),
        surface: Color(red: 0.07, green: 0.09, blue: 0.15),
        surfaceElevated: Color(red: 0.10, green: 0.13, blue: 0.20),
        accentPrimary: Color(red: 0.15, green: 0.39, blue: 0.92),
        accentSecondary: Color(red: 0.13, green: 0.83, blue: 0.93),
        accentTertiary: Color(red: 0.06, green: 0.73, blue: 0.51),
        foreground: Color(red: 0.89, green: 0.91, blue: 0.94)
    )
}
