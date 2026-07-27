import Foundation

/// Stable identity for one plugin instance, minted by the host.
///
/// ## The problem this replaces
///
/// The SDK gave plugins no identity and no lifecycle, so all four first-party
/// plugins independently invented the same workaround:
///
/// ```swift
/// private static var stores: [ObjectIdentifier: MyStore] = [:]
/// let key = ObjectIdentifier(host as AnyObject)
/// ```
///
/// Three things are wrong with that, and they were wrong in four places:
///
/// 1. **`ObjectIdentifier` of an existential is an address.** `HostServices` is
///    not class-bound, so `host as AnyObject` may box a value — and the box's
///    address is reused after it is freed. A new host can therefore be handed
///    the *previous* host's store. GitMage's settings and Lore's open SQLite
///    connection both rode on that key.
/// 2. **Nothing is ever evicted.** The dictionary is `static`, so every store
///    ever created lives for the process. Lore's entry holds an open database
///    and its file descriptor; Leyline's holds materialized key state.
/// 3. **There is no teardown.** A plugin closed by the user keeps its watchers,
///    connections and timers running, because nothing tells it that it is done.
///
/// A host-minted `PluginInstanceID` fixes (1) — it is a value, not an address,
/// and never recycled. `AinkradAppKitTeardown` fixes (3), and gives the host
/// the hook it needs to fix (2).
public struct PluginInstanceID: Hashable, Sendable {
    public let rawValue: UUID
    public init(rawValue: UUID = UUID()) { self.rawValue = rawValue }
}

/// How a plugin learns its own instance identity.
///
/// A separate protocol rather than a new `HostServices` requirement — even
/// though the host is the only conformer of `HostServices`, and adding a
/// requirement there would in practice be safe under library evolution. The
/// rule is kept absolute because "safe in practice, if you reason carefully
/// about who conforms" is precisely the kind of judgement that decays over
/// releases. One shape for new capability, no exceptions to remember:
///
/// ```swift
/// let instance = (host as? PluginInstanceIdentity)?.instanceID
/// ```
///
/// A generation-7 host fails the cast, and the plugin falls back to
/// single-instance behaviour.
@MainActor public protocol PluginInstanceIdentity {
    /// Stable for the lifetime of this instance; never reused after teardown.
    var instanceID: PluginInstanceID { get }
}

/// Opt-in teardown, discovered by dynamic cast so it is **not** a requirement
/// on `AinkradApp`.
///
/// This is the shape every future capability must take. Library evolution
/// covers added *declarations*; it does not cover added **protocol
/// requirements** — an already-compiled bundle has no witness for a new one and
/// fails to load. So `AinkradApp` and `HostServices` are closed, and new
/// capability arrives as a separate protocol the host looks for:
///
/// ```swift
/// if let teardownable = appType as? AinkradAppTeardown.Type {
///     teardownable.teardown(instance: id)
/// }
/// ```
///
/// A generation-7 bundle simply fails the cast and is left alone.
/// `ContractFreezeTests` enforces that this stays true.
@MainActor public protocol AinkradAppTeardown {
    /// Release everything scoped to `instance`: open files and databases,
    /// watchers, timers, connections, caches. Called when the host closes this
    /// instance of the app. Must be safe to call more than once.
    static func teardown(instance: PluginInstanceID)
}

/// A per-instance store cache, so plugins stop hand-rolling one each.
///
/// Keyed by the host-minted `PluginInstanceID` rather than an address, and
/// evicted on `teardown`. This is the shared, correct version of the four
/// duplicated registries described above.
@MainActor
public final class PluginInstanceStorage<Value> {
    private var values: [PluginInstanceID: Value] = [:]

    public init() {}

    /// The value for `instance`, creating it once on first use.
    public func value(for instance: PluginInstanceID, make: () -> Value) -> Value {
        if let existing = values[instance] { return existing }
        let created = make()
        values[instance] = created
        return created
    }

    /// Drops the value for `instance`, returning it so the caller can close
    /// whatever it owns. The eviction the old static dictionaries never had.
    @discardableResult
    public func remove(_ instance: PluginInstanceID) -> Value? {
        values.removeValue(forKey: instance)
    }

    public var count: Int { values.count }
}
