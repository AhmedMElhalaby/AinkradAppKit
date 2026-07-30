import Foundation

/// Identifier for one app in the Ainkrad family (`"Lore"`, `"Quest"`, …).
public struct AppID: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.rawValue = rawValue }
}

/// Directories shared by the host and every app. Vault-resident by definition:
/// each holds authored or otherwise irreplaceable content.
public enum SharedDomain: String, CaseIterable, Sendable {
    case config, agents, memory, skills, commands, sessions, media, sounds

    var relativePath: String {
        switch self {
        case .config:   return "Config"
        case .agents:   return "Assistant/agents"
        case .memory:   return "Assistant/memory"
        case .skills:   return "Assistant/skills"
        case .commands: return "Assistant/commands"
        case .sessions: return "Assistant/sessions"
        case .media:    return "Media"
        case .sounds:   return "Sounds"
        }
    }
}

/// A resolved Ainkrad Home: one user-chosen vault plus one machine-local cache.
///
/// The split rule is *authored or irreplaceable → vault; derivable → cache*, and
/// the invariant it exists to guarantee is that deleting `cacheRoot` entirely
/// loses nothing the user cannot get back.
public struct Home: Sendable, Hashable {
    public let vaultRoot: URL
    public let cacheRoot: URL

    public init(vaultRoot: URL, cacheRoot: URL) {
        self.vaultRoot = vaultRoot
        self.cacheRoot = cacheRoot
    }

    /// Authored data owned by one app.
    public func vault(app: AppID) -> URL {
        vaultRoot.appendingPathComponent("Apps", isDirectory: true)
            .appendingPathComponent(app.rawValue, isDirectory: true)
    }

    /// Disposable, machine-local data owned by one app.
    public func cache(app: AppID) -> URL {
        cacheRoot.appendingPathComponent("Apps", isDirectory: true)
            .appendingPathComponent(app.rawValue, isDirectory: true)
    }

    /// A directory shared across the family.
    public func shared(_ domain: SharedDomain) -> URL {
        domain.relativePath.split(separator: "/").reduce(vaultRoot) {
            $0.appendingPathComponent(String($1), isDirectory: true)
        }
    }
}
