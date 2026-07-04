import SwiftUI

/// The contract a plugin bundle implements. Mirrors the host's internal
/// Built-in App shape but depends only on `HostServices`, never the host binary.
@MainActor public protocol AinkradApp {
    static var id: String { get }
    static var displayName: String { get }
    /// SF Symbol name. Tint from `host.theme`, never a hardcoded color.
    static var icon: String { get }
    static func makeRootView(host: HostServices) -> AnyView
    static func makeSettingsView(host: HostServices) -> AnyView
    /// The window's own background fill (color + opacity). Default `nil`.
    static func chromeFill(host: HostServices) -> Color?
}

public extension AinkradApp {
    static func chromeFill(host: HostServices) -> Color? { nil }
}

/// A bundle's `NSPrincipalClass` conforms to this; the host casts the loaded
/// principal class to it to obtain the app type.
@MainActor public protocol AinkradPluginEntryPoint: AnyObject {
    static func app() -> any AinkradApp.Type
}
