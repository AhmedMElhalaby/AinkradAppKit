import CoreGraphics

/// Theme-invariant layout, motion, and type scales shared by the host and all
/// plugins. These do NOT vary by theme, so they are standalone constants rather
/// than fields on the per-theme `HostThemeTokens`. See
/// WorkShop/Ainkrad/04 Planning/Milestone 6 — Refinement Plan.

/// 4-pt spacing ramp. Use instead of raw `.padding(_:)` literals.
public enum AinkradSpacing {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32
}

/// Corner-radius steps. `panel` is the standard overlay/HUD radius.
public enum AinkradRadius {
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 14
    public static let panel: CGFloat = 14
}
