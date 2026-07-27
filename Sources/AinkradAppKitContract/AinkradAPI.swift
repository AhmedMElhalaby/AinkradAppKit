import Foundation

/// The public entry namespace for the Ainkrad Built-in App SDK.
public enum AinkradAppKit {
    /// The API generation this SDK represents. A plugin bundle records the
    /// value it was built against; the host loads it only if that value is
    /// within the host's supported range.
    ///
    /// Generation 7 is the first resilient-ABI generation: the module builds
    /// with `-enable-library-evolution`, so additive public changes no
    /// longer break already-compiled plugin bundles that reuse the host's
    /// embedded copy.
    /// Generation 8 splits the module into an ABI-frozen contract plus a UI
    /// kit, and widens the plugin boundary: per-instance identity and
    /// `teardown`, host-owned focus, a typed cross-app launch payload, and
    /// status colors. Every one of those is **additive** — a generation-7
    /// bundle keeps loading, which is what `minSupportedAPIVersion` is for.
    public static let apiVersion = 8

    /// The oldest generation a host built on this SDK still loads.
    ///
    /// **Generation 8 is a HARD break, so this equals `apiVersion`.**
    ///
    /// The intent was `apiVersion - 1` — a one-release deprecation window, so
    /// a generation bump is a migration rather than an outage. That is the
    /// right long-term policy and it takes effect from generation 9.
    ///
    /// It cannot apply to generation 8, because splitting the module into
    /// `AinkradAppKitContract` + `AinkradAppKitUI` **renamed every symbol**:
    /// Swift mangles the module name into its mangled names, so a plugin
    /// compiled against generation 7 references 71 `AinkradAppKit…` symbols
    /// that no longer exist. It passes the version check and then fails to
    /// link — `Bundle.load()` returns false.
    ///
    /// Claiming to support generation 7 here would be a promise the loader
    /// cannot keep: the user would see "plugin failed to load" instead of the
    /// honest "built against generation 7; this host supports 8 — update the
    /// app". Verified empirically by signing a real hardened-runtime build and
    /// loading both a stale and a freshly-built plugin.
    ///
    /// Neither guardrail caught this, which is worth remembering:
    /// `swift-api-digester` compared the new contract module against a baseline
    /// regenerated *from that same module*, so the move was invisible to it;
    /// and `ContractFreezeTests` checks source-level conformance, not symbol
    /// mangling. A module rename is an ABI break that looks like a no-op to
    /// both. See `abi/README-module-renames.md`.
    public static let minSupportedAPIVersion = apiVersion

    /// A bundle built against `bundleAPIVersion` is loadable exactly when it
    /// falls within the host's inclusive supported range.
    public static func isCompatible(bundleAPIVersion: Int, minSupported: Int, current: Int) -> Bool {
        bundleAPIVersion >= minSupported && bundleAPIVersion <= current
    }
}
