import Foundation
@_exported import AinkradSignal

/// Lets an app record events in the host's Signal feed.
///
/// **Write-only across apps, by construction.** There is no `source`
/// parameter: the host mints one emitter per app, bound to that app's id, and
/// stamps every event with it. An app therefore cannot attribute an event to
/// another app — not because the host rejects the attempt, but because the API
/// gives it no way to express one.
///
/// `own(limit:)` reads back only this app's own events, which is what
/// `SignalFeedView(scope: .own)` renders. Reading the aggregated cross-app feed
/// is NOT part of generation 9; it arrives in M3 behind a manifest-declared,
/// user-approved subscription.
///
/// Emission is best-effort: `emit` cannot throw and cannot fail the work that
/// called it. A rejected or undeliverable event never becomes the caller's
/// problem — the doctrine the host's run notifier established and Signal
/// generalizes.
///
/// Note for anyone adding to this protocol: a new requirement here is a SOURCE
/// break for every conformer, and while no plugin conforms in production, the
/// plugin repos fake one in their test support. Adding to `HostServices` or to
/// this protocol means updating those fakes in the same generation.
@MainActor public protocol PluginSignalEmitter {
    func emit(kind: String,
              severity: SignalSeverity,
              title: String,
              body: String?,
              importance: SignalImportance,
              deepLink: SignalDeepLink?,
              actions: [SignalAction],
              dedupeKey: String?)

    /// This app's own events, newest first.
    func own(limit: Int) -> [SignalEvent]

    /// Handle an action this app attached to one of its events. The host holds
    /// the handler weakly through a register-once bridge and never tears it
    /// down; once the source is gone the invocation is a no-op. Same lifetime
    /// contract as `AgentActionProvider`, and the same bridge behind it.
    func handleAction(_ actionID: String,
                      _ handler: @escaping @MainActor () async -> Void) -> AgentActionToken
    func removeActionHandler(_ token: AgentActionToken)
}

public extension PluginSignalEmitter {
    /// The call most apps actually make.
    ///
    /// A default-argument *extension* rather than default arguments on the
    /// requirement: defaults on a protocol requirement are not part of the
    /// witness table, so a conformer could silently diverge from them. Here
    /// every conformer gets the same behaviour.
    func emit(kind: String,
              severity: SignalSeverity,
              title: String,
              body: String? = nil,
              importance: SignalImportance = .normal,
              deepLink: SignalDeepLink? = nil,
              actions: [SignalAction] = [],
              dedupeKey: String? = nil) {
        emit(kind: kind, severity: severity, title: title, body: body,
             importance: importance, deepLink: deepLink, actions: actions, dedupeKey: dedupeKey)
    }
}

/// A conformance that records nothing, for test fakes and for the window during
/// bootstrap before the real feed exists. Silence is the correct fallback: an
/// emitter that fails loudly would violate the protocol's own promise that
/// emission never becomes the caller's problem.
@MainActor public final class NoopSignalEmitter: PluginSignalEmitter {
    public init() {}
    public func emit(kind: String, severity: SignalSeverity, title: String, body: String?,
                     importance: SignalImportance, deepLink: SignalDeepLink?,
                     actions: [SignalAction], dedupeKey: String?) {}
    public func own(limit: Int) -> [SignalEvent] { [] }
    public func handleAction(_ actionID: String,
                             _ handler: @escaping @MainActor () async -> Void) -> AgentActionToken {
        AgentActionToken()
    }
    public func removeActionHandler(_ token: AgentActionToken) {}
}
