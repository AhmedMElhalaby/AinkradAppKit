import SwiftUI
import Observation

@MainActor public protocol HostServices {
    var documents: PluginDocumentStore { get }
    var secrets: PluginSecretStore { get }
    /// The host's resolved theme, observable so apps recolor live on a theme change.
    var theme: HostTheme { get }
    var log: PluginLogger { get }
}

/// Observable wrapper over `HostThemeTokens`. The host mutates it on a theme
/// change; SwiftUI views that read `tokens` in their `body` re-render.
@MainActor
@Observable
public final class HostTheme {
    public private(set) var tokens: HostThemeTokens
    public init(_ tokens: HostThemeTokens) { self.tokens = tokens }
    public func update(_ tokens: HostThemeTokens) { self.tokens = tokens }
}

/// Small key→data store. Apps encode their own `Codable` state into `Data`.
public protocol PluginDocumentStore {
    func data(forKey key: String) -> Data?
    func setData(_ data: Data?, forKey key: String)
}

/// Small key→string secret store. Values never touch disk in plaintext.
public protocol PluginSecretStore {
    func secret(forKey key: String) -> String?
    func setSecret(_ value: String?, forKey key: String)
}

public protocol PluginLogger {
    func info(_ message: String)
    func error(_ message: String)
}

public struct HostThemeTokens: Equatable {
    /// Stable identity of the active theme (the host's theme id). Lets an app
    /// key its own per-theme assets without importing host theme types.
    public let themeID: String
    public let background: Color
    public let surface: Color
    public let surfaceElevated: Color
    public let accentPrimary: Color
    public let accentSecondary: Color
    public let accentTertiary: Color
    public let foreground: Color

    public init(themeID: String, background: Color, surface: Color, surfaceElevated: Color,
                accentPrimary: Color, accentSecondary: Color, accentTertiary: Color,
                foreground: Color) {
        self.themeID = themeID
        self.background = background
        self.surface = surface
        self.surfaceElevated = surfaceElevated
        self.accentPrimary = accentPrimary
        self.accentSecondary = accentSecondary
        self.accentTertiary = accentTertiary
        self.foreground = foreground
    }
}
