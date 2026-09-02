import SwiftUI

/// How a pane tells the host which of the app's own things it is showing, so a
/// notification can focus the pane that produced it.
///
/// ## Why this is an environment value and not a protocol requirement
///
/// `AinkradApp` is ABI-frozen and `makeRootView(host:)` receives one
/// `HostServices` per APP, not per pane — so nothing in the contract can tell
/// two panes of the same app apart. Adding a requirement to carry a pane
/// identity is the one change library evolution does not cover, and it would
/// break every generation-9 bundle.
///
/// The SwiftUI environment is a side channel that needs no contract change at
/// all: the host injects a sink around the view it is already rendering for a
/// known pane, and an app opts in by reading it. An app that never reads it
/// keeps working exactly as before, which is why the default is a sink that
/// does nothing.
///
/// Usage, from inside an app's own pane view:
///
/// ```swift
/// @Environment(\.ainkradPaneLocator) private var paneLocator
/// // ...
/// .onAppear { paneLocator(session.id.uuidString) }
/// ```
///
/// Then emit deep links carrying the same string as
/// `SignalDeepLink(appID:payload:locator:)`.
public struct SignalPaneLocatorSink: Sendable {
    private let report: @MainActor @Sendable (String?) -> Void

    public init(report: @escaping @MainActor @Sendable (String?) -> Void) {
        self.report = report
    }

    /// Reports the locator this pane is currently showing. Pass nil when the
    /// pane no longer shows anything addressable.
    ///
    /// Safe to call repeatedly and on every change — the host keeps the last
    /// value per pane. An app SHOULD call it again when the pane's content
    /// changes, or a notification will focus the pane that used to hold the
    /// session rather than the one that does.
    @MainActor public func callAsFunction(_ locator: String?) { report(locator) }
}

private struct SignalPaneLocatorKey: EnvironmentKey {
    /// A sink that discards. An app reading this outside a host pane — in a
    /// preview, in its own tests, in the Dev Host — must not have to special
    /// case its absence.
    static let defaultValue = SignalPaneLocatorSink { _ in }
}

public extension EnvironmentValues {
    var ainkradPaneLocator: SignalPaneLocatorSink {
        get { self[SignalPaneLocatorKey.self] }
        set { self[SignalPaneLocatorKey.self] = newValue }
    }
}
