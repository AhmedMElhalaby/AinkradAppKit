import Foundation

/// A read-only snapshot a plugin publishes for the host's agent to consult.
/// A plugin exposes only its own state — never the registry or other apps.
public struct AgentContextSnapshot: Equatable, Sendable {
    /// Stable machine tag for the source kind, e.g. "terminal", "git".
    public let kind: String
    /// Short human label, e.g. "Terminal — ~/proj".
    public let title: String
    /// The read-only content (buffer text, status, …).
    public let text: String

    public init(kind: String, title: String, text: String) {
        self.kind = kind
        self.title = title
        self.text = text
    }
}

/// Opaque handle returned by `PluginContextRegistry.register`.
public struct PluginContextToken: Hashable, Sendable {
    public let id: UUID
    public init(id: UUID = UUID()) { self.id = id }
}

/// Lets a plugin publish read-only context the host MAY poll each turn.
@MainActor public protocol PluginContextRegistry {
    func register(_ source: @escaping @MainActor () -> AgentContextSnapshot?) -> PluginContextToken
    func remove(_ token: PluginContextToken)
}
