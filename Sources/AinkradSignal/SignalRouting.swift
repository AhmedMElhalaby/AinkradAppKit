import Foundation

public enum DeliveryChannel: String, Codable, Sendable, Hashable, CaseIterable {
    /// Always delivered. Not rule-controlled: the log is not optional.
    case feed
    case badge
    case toast
    case banner
    case sound
}

/// What the *user's situation* contributes to the decision. Supplied by the
/// host; this is what promotes a toast to a banner when the user looked away.
public struct DeliveryContext: Sendable, Equatable {
    public let hostIsFrontmost: Bool
    public let visibleAppIDs: Set<String>
    public let systemDoNotDisturb: Bool
    public let hostFocusMode: Bool

    public init(hostIsFrontmost: Bool, visibleAppIDs: Set<String>,
                systemDoNotDisturb: Bool, hostFocusMode: Bool) {
        self.hostIsFrontmost = hostIsFrontmost
        self.visibleAppIDs = visibleAppIDs
        self.systemDoNotDisturb = systemDoNotDisturb
        self.hostFocusMode = hostFocusMode
    }
}

/// Key for a `(source, kind)` override.
public struct SourceKind: Codable, Sendable, Hashable {
    public let source: SignalSource
    public let kind: String
    public init(source: SignalSource, kind: String) {
        self.source = source
        self.kind = kind
    }
}

public struct RoutingRules: Codable, Sendable, Equatable {
    /// Sources the user silenced. They still reach `.feed`, nothing else.
    public var mutedSources: Set<SignalSource>
    public var sourceOverrides: [SignalSource: Set<DeliveryChannel>]
    public var sourceKindOverrides: [SourceKind: Set<DeliveryChannel>]

    public init(mutedSources: Set<SignalSource> = [],
                sourceOverrides: [SignalSource: Set<DeliveryChannel>] = [:],
                sourceKindOverrides: [SourceKind: Set<DeliveryChannel>] = [:]) {
        self.mutedSources = mutedSources
        self.sourceOverrides = sourceOverrides
        self.sourceKindOverrides = sourceKindOverrides
    }

    public static let `default` = RoutingRules()
}

/// Pure. Given an event, the user's rules and the user's situation, which
/// channels deliver it. No I/O, no clock, no globals — every branch is a table
/// row in `SignalRoutingTests`.
public func route(_ event: SignalEvent,
                  rules: RoutingRules,
                  context: DeliveryContext) -> Set<DeliveryChannel> {
    var channels: Set<DeliveryChannel> = [.feed]

    // A muted source logs and stops. Checked before overrides so muting is
    // absolute — including against an `.urgent` proposal.
    if rules.mutedSources.contains(event.source) { return channels }

    if let explicit = rules.sourceKindOverrides[SourceKind(source: event.source, kind: event.kind)] {
        channels = explicit.union([.feed])
    } else if let explicit = rules.sourceOverrides[event.source] {
        channels = explicit.union([.feed])
    } else {
        channels.formUnion(defaultChannels(for: event, context: context))
    }

    if context.systemDoNotDisturb || context.hostFocusMode {
        channels.remove(.banner)
        channels.remove(.sound)
    }
    return channels
}

private func defaultChannels(for event: SignalEvent,
                             context: DeliveryContext) -> Set<DeliveryChannel> {
    let appIsVisible: Bool = {
        guard case .app(let id) = event.source else { return context.hostIsFrontmost }
        return context.hostIsFrontmost && context.visibleAppIDs.contains(id)
    }()
    let present = context.hostIsFrontmost

    switch (event.severity, present, appIsVisible) {
    case (.info, true, _):            return []
    case (.info, false, _):           return [.badge]
    case (.success, true, true):      return [.toast]
    case (.success, true, false):     return [.badge]
    case (.success, false, _):        return [.badge, .banner]
    case (.warning, true, true):      return [.toast]
    case (.warning, true, false):     return [.badge, .toast]
    case (.warning, false, _):        return [.badge, .banner]
    case (.failure, true, true):      return [.toast, .sound]
    case (.failure, true, false):     return [.badge, .toast, .sound]
    case (.failure, false, _):        return [.badge, .banner, .sound]
    }
}
