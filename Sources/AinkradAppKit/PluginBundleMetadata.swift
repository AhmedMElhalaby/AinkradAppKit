import Foundation

/// Info.plist keys a plugin bundle declares. Read WITHOUT loading code so the
/// host can validate a bundle before executing any of it.
public enum PluginInfoKey {
    public static let appID = "AinkradAppID"
    public static let displayName = "AinkradDisplayName"
    public static let iconSymbol = "AinkradIconSymbol"
    public static let apiVersion = "AinkradAPIVersion"
    public static let principalClass = "NSPrincipalClass"
}

public struct PluginBundleMetadata: Equatable {
    public let appID: String
    public let displayName: String
    public let iconSymbol: String
    public let apiVersion: Int
    public let principalClassName: String

    public init(appID: String, displayName: String, iconSymbol: String,
                apiVersion: Int, principalClassName: String) {
        self.appID = appID
        self.displayName = displayName
        self.iconSymbol = iconSymbol
        self.apiVersion = apiVersion
        self.principalClassName = principalClassName
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
        return .success(PluginBundleMetadata(appID: appID, displayName: displayName,
                                             iconSymbol: icon, apiVersion: api,
                                             principalClassName: principal))
    }
}
