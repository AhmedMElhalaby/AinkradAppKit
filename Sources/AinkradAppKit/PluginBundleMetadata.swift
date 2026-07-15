import Foundation

/// Info.plist keys a plugin bundle declares. Read WITHOUT loading code so the
/// host can validate a bundle before executing any of it.
public enum PluginInfoKey {
    public static let appID = "AinkradAppID"
    public static let displayName = "AinkradDisplayName"
    public static let iconSymbol = "AinkradIconSymbol"
    public static let apiVersion = "AinkradAPIVersion"
    public static let principalClass = "NSPrincipalClass"
    public static let presentation = "AinkradPresentation"
}

/// How a plugin's window should be presented by the host. Defaults to `.pane`
/// when the bundle omits `AinkradPresentation` or declares an unrecognized value.
public enum PluginPresentation: String, Sendable {
    case pane
    case overlay
}

public struct PluginBundleMetadata: Equatable {
    public let appID: String
    public let displayName: String
    public let iconSymbol: String
    public let apiVersion: Int
    public let principalClassName: String
    public let presentation: PluginPresentation

    public init(appID: String, displayName: String, iconSymbol: String,
                apiVersion: Int, principalClassName: String,
                presentation: PluginPresentation = .pane) {
        self.appID = appID
        self.displayName = displayName
        self.iconSymbol = iconSymbol
        self.apiVersion = apiVersion
        self.principalClassName = principalClassName
        self.presentation = presentation
    }
}

public enum PluginMetadataError: Error, Equatable {
    case missingKey(String)
    case invalidAPIVersion
}

public extension PluginBundleMetadata {
    /// Parses and validates plugin metadata from an Info.plist dictionary.
    static func parse(infoDictionary dict: [String: Any]) -> Result<PluginBundleMetadata, PluginMetadataError> {
        func string(_ key: String) -> String? { dict[key] as? String }
        guard let appID = string(PluginInfoKey.appID) else { return .failure(.missingKey(PluginInfoKey.appID)) }
        guard let displayName = string(PluginInfoKey.displayName) else { return .failure(.missingKey(PluginInfoKey.displayName)) }
        guard let icon = string(PluginInfoKey.iconSymbol) else { return .failure(.missingKey(PluginInfoKey.iconSymbol)) }
        guard let principal = string(PluginInfoKey.principalClass) else { return .failure(.missingKey(PluginInfoKey.principalClass)) }
        guard let api = dict[PluginInfoKey.apiVersion] as? Int else { return .failure(.invalidAPIVersion) }
        let presentation = PluginPresentation(rawValue: (dict[PluginInfoKey.presentation] as? String) ?? "") ?? .pane
        return .success(PluginBundleMetadata(appID: appID, displayName: displayName,
                                             iconSymbol: icon, apiVersion: api,
                                             principalClassName: principal,
                                             presentation: presentation))
    }
}
