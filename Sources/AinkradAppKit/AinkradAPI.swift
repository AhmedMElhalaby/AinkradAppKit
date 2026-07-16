import Foundation

/// The public entry namespace for the Ainkrad Built-in App SDK.
public enum AinkradAppKit {
    /// The API generation this SDK represents. A plugin bundle records the
    /// value it was built against; the host loads it only if that value is
    /// within the host's supported range.
    public static let apiVersion = 6

    /// A bundle built against `bundleAPIVersion` is loadable exactly when it
    /// falls within the host's inclusive supported range.
    public static func isCompatible(bundleAPIVersion: Int, minSupported: Int, current: Int) -> Bool {
        bundleAPIVersion >= minSupported && bundleAPIVersion <= current
    }
}
