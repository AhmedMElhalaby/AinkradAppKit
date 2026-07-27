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
    /// Deliberately `apiVersion - 1`, giving each generation a one-release
    /// deprecation window. Before this, the host's `minSupported` tracked
    /// `current` exactly, so bumping the generation **instantly de-registered
    /// every installed plugin**: the bump and the breakage were the same
    /// event, with no release in between for plugin authors to rebuild
    /// against. A window turns a generation bump into a migration instead of
    /// an outage.
    public static let minSupportedAPIVersion = apiVersion - 1

    /// A bundle built against `bundleAPIVersion` is loadable exactly when it
    /// falls within the host's inclusive supported range.
    public static func isCompatible(bundleAPIVersion: Int, minSupported: Int, current: Int) -> Bool {
        bundleAPIVersion >= minSupported && bundleAPIVersion <= current
    }
}
