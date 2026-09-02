import Foundation

/// Who produced an event. Stamped by the host at ingest — never supplied by
/// the emitter, which is what makes forgery inexpressible in the API.
public enum SignalSource: Codable, Sendable, Hashable {
    case host
    case sage
    case app(appID: String)
}

public enum SignalSeverity: String, Codable, Sendable, CaseIterable, Hashable {
    case info, success, warning, failure
}

/// What the emitter *proposes*. An input to routing, never an override:
/// an `.urgent` proposal from a muted source stays muted.
public enum SignalImportance: String, Codable, Sendable, CaseIterable, Hashable {
    case background, normal, urgent
}

/// Where activating an event takes the user. `payload` is opaque to Signal and
/// is handed to the target app by the host's existing cross-app launch path.
public struct SignalDeepLink: Codable, Sendable, Equatable {
    public let appID: String
    public let payload: Data
    public init(appID: String, payload: Data) {
        self.appID = appID
        self.payload = payload
    }
}

public struct SignalAction: Codable, Sendable, Equatable {
    public let id: String
    public let label: String
    public let isDestructive: Bool
    public init(id: String, label: String, isDestructive: Bool = false) {
        self.id = id
        self.label = label
        self.isDestructive = isDestructive
    }

    /// Hand-written so `isDestructive` defaults the same way it does in the
    /// memberwise init above. The synthesised decoder REQUIRED the key, which
    /// only surfaced once actions could arrive over the wire (M3): a payload
    /// carrying `{"id":"rerun","label":"Re-run"}` — valid JSON, and exactly
    /// what a first attempt looks like — failed to decode, and because a
    /// payload is rejected whole the entire notification was reported as
    /// `malformed`. Two initialisers disagreeing about a default is the kind
    /// of thing nobody finds by reading.
    ///
    /// Defaulting to `false` is the safe direction: an action is non-destructive
    /// unless it says so, so a missing key can never silently skip the
    /// confirmation step a destructive action requires.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        label = try c.decode(String.self, forKey: .label)
        isDestructive = try c.decodeIfPresent(Bool.self, forKey: .isDestructive) ?? false
    }

    private enum CodingKeys: String, CodingKey {
        case id, label, isDestructive
    }
}

public struct SignalEvent: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let timestamp: Date
    public let source: SignalSource
    public let kind: String
    public let severity: SignalSeverity
    public let title: String
    public let body: String?
    public let proposedImportance: SignalImportance
    public let deepLink: SignalDeepLink?
    public let actions: [SignalAction]
    public let dedupeKey: String?

    public init(id: UUID = UUID(),
                timestamp: Date = Date(),
                source: SignalSource,
                kind: String,
                severity: SignalSeverity,
                title: String,
                body: String? = nil,
                proposedImportance: SignalImportance = .normal,
                deepLink: SignalDeepLink? = nil,
                actions: [SignalAction] = [],
                dedupeKey: String? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.source = source
        self.kind = kind
        self.severity = severity
        self.title = title
        self.body = body
        self.proposedImportance = proposedImportance
        self.deepLink = deepLink
        self.actions = actions
        self.dedupeKey = dedupeKey
    }
}
