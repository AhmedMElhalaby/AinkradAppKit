import Foundation

/// Lets an app request opening ANOTHER app and hand it an opaque payload, and
/// lets the opened app retrieve the payload aimed at it. The payload is an
/// opaque string; apps agree on their own encoding (e.g. JSON). Deliberately
/// narrow — open-by-id + opaque payload only, still no registry/window access.
@MainActor public protocol PluginAppLauncher {
    /// Request that the host open `appID` in a new pane, delivering `payload`
    /// to it. A nil payload clears any pending payload for that target.
    func open(appID: String, payload: String?)
    /// Pull (and clear) the payload most recently aimed at THIS app, if any.
    /// Called by the opened app as it starts. Nil when there is none.
    func takePendingLaunch() -> String?
}
