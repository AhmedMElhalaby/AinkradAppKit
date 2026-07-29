import CoreGraphics

/// The single source of truth for settings geometry. The later
/// user-resizable pass edits these, not thirty call sites.
public enum SettingsMetrics {
    public static let panelMinWidth: CGFloat = 1100
    public static let panelMaxWidth: CGFloat = 1440
    public static let panelWidthFraction: CGFloat = 0.82
    public static let panelMinHeight: CGFloat = 700
    public static let panelMaxHeight: CGFloat = 900
    public static let panelHeightFraction: CGFloat = 0.85
    public static let panelYOffset: CGFloat = -30

    public static let sidebarWidth: CGFloat = 240
    public static let controlColumnWidth: CGFloat = 220

    /// Inset applied inside a `.custom` pane. Matches the padding a row gets
    /// inside its card, so pane text and row text share one left rail and
    /// pane content never sits flush against a surrounding stroke.
    public static let paneInset: CGFloat = 14

    /// Below this the mini-map is hidden.
    public static let miniMapBreakpoint: CGFloat = 640
    /// Above this rows lay out side-by-side on a shared control rail.
    public static let wideBreakpoint: CGFloat = 900
}
