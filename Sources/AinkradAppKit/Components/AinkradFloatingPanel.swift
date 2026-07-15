import SwiftUI
import AppKit

/// Positions a floating panel relative to an anchor rect, both in SCREEN
/// coordinates (AppKit convention: origin bottom-left, y grows upward).
/// Prefers directly below the anchor, left-aligned; flips above the anchor
/// if there isn't room below; then clamps into `screenVisibleFrame` on both
/// axes so the panel is never fully off-screen. Pure — unit tested without
/// AppKit/SwiftUI.
public func floatingPanelFrame(
    anchorScreenRect: CGRect,
    contentSize: CGSize,
    screenVisibleFrame: CGRect,
    gap: CGFloat = 4
) -> CGRect {
    let belowY = anchorScreenRect.minY - gap - contentSize.height
    var originY: CGFloat
    if belowY >= screenVisibleFrame.minY {
        originY = belowY
    } else {
        // No room below — try flipping above the trigger.
        let aboveY = anchorScreenRect.maxY + gap
        if aboveY + contentSize.height <= screenVisibleFrame.maxY {
            originY = aboveY
        } else {
            // Neither fits fully: prefer below, then clamp.
            originY = belowY
        }
    }

    var originX = anchorScreenRect.minX
    if originX + contentSize.width > screenVisibleFrame.maxX {
        originX = screenVisibleFrame.maxX - contentSize.width
    }
    if originX < screenVisibleFrame.minX {
        originX = screenVisibleFrame.minX
    }

    if originY + contentSize.height > screenVisibleFrame.maxY {
        originY = screenVisibleFrame.maxY - contentSize.height
    }
    if originY < screenVisibleFrame.minY {
        originY = screenVisibleFrame.minY
    }

    return CGRect(x: originX, y: originY, width: contentSize.width, height: contentSize.height)
}

/// AppKit-backed presenter for a top-level, custom-drawn floating panel: a
/// borderless, non-activating `NSPanel` hosting arbitrary SwiftUI content,
/// added as a child window of the trigger's window so it tracks/dismisses
/// with it. This is the shared presentation surface for `AinkradSelect`,
/// `AinkradMultiSelect`, `AinkradCombobox`, and `AinkradSearchableSelect` —
/// it renders above ALL app content (any clipping/overlay ancestor) without
/// requiring host cooperation, and is NOT a native `Menu`/`Picker`/`.popover`.
@MainActor
final class AinkradFloatingPanelController: NSObject, NSWindowDelegate {
    /// The trigger's underlying view, supplied by `AinkradFloatingPanelAnchor`.
    /// Weak: the anchor view's lifetime is owned by SwiftUI, not us.
    weak var anchorView: NSView?

    private var panel: NSPanel?
    private var localMouseMonitor: Any?
    private var globalMouseMonitor: Any?
    private var localKeyMonitor: Any?
    private var parentWindowObservers: [NSObjectProtocol] = []
    private weak var parentWindow: NSWindow?
    private var onDismiss: (() -> Void)?

    func present<Content: View>(
        maxHeight: CGFloat,
        @ViewBuilder content: @escaping () -> Content,
        onDismiss: @escaping () -> Void
    ) {
        dismiss()
        guard let anchorView, let window = anchorView.window else { return }
        self.onDismiss = onDismiss
        self.parentWindow = window

        // Measure the content's natural size first (unconstrained), then
        // decide whether it needs to scroll under `maxHeight`.
        let measuring = NSHostingView(rootView: AnyView(content()))
        let natural = measuring.fittingSize
        let width = max(natural.width, 160)
        let height = min(max(natural.height, 1), maxHeight)
        let needsScroll = natural.height > maxHeight

        let sized: AnyView = needsScroll
            ? AnyView(ScrollView { content() }.frame(width: width, height: height))
            : AnyView(content().frame(width: width, height: height))

        let hosting = NSHostingView(rootView: sized)
        hosting.frame = CGRect(origin: .zero, size: CGSize(width: width, height: height))
        hosting.wantsLayer = true
        hosting.layer?.backgroundColor = .clear

        let anchorRectInWindow = anchorView.convert(anchorView.bounds, to: nil)
        let anchorScreenRect = window.convertToScreen(anchorRectInWindow)
        let visibleFrame = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame
            ?? CGRect(x: 0, y: 0, width: width, height: height)
        let frame = floatingPanelFrame(
            anchorScreenRect: anchorScreenRect,
            contentSize: CGSize(width: width, height: height),
            screenVisibleFrame: visibleFrame
        )

        let panel = NSPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel],
                             backing: .buffered, defer: false)
        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.delegate = self
        panel.contentView = hosting
        panel.setFrame(frame, display: true)

        window.addChildWindow(panel, ordered: .above)
        panel.orderFront(nil)
        self.panel = panel

        installMonitors(panel: panel, parentWindow: window)
    }

    /// Removes the panel, its childWindow relationship, and all monitors/
    /// observers. Safe to call multiple times.
    func dismiss() {
        removeMonitors()
        if let panel {
            panel.parent?.removeChildWindow(panel)
            panel.orderOut(nil)
            panel.contentView = nil
            panel.delegate = nil
        }
        panel = nil
        parentWindow = nil
        onDismiss = nil
    }

    private func installMonitors(panel: NSPanel, parentWindow: NSWindow) {
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.panel === panel, event.keyCode == 53 /* Esc */ else { return event }
            self.requestDismiss()
            return nil
        }
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self, self.panel === panel else { return event }
            if event.window !== panel { self.requestDismiss() }
            return event
        }
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.requestDismiss()
        }

        let center = NotificationCenter.default
        parentWindowObservers = [
            center.addObserver(forName: NSWindow.didResignKeyNotification, object: parentWindow, queue: .main) { [weak self] _ in
                self?.requestDismiss()
            },
            center.addObserver(forName: NSWindow.willMoveNotification, object: parentWindow, queue: .main) { [weak self] _ in
                self?.requestDismiss()
            },
            center.addObserver(forName: NSWindow.didMoveNotification, object: parentWindow, queue: .main) { [weak self] _ in
                self?.requestDismiss()
            },
        ]
    }

    private func removeMonitors() {
        if let localMouseMonitor { NSEvent.removeMonitor(localMouseMonitor) }
        if let globalMouseMonitor { NSEvent.removeMonitor(globalMouseMonitor) }
        if let localKeyMonitor { NSEvent.removeMonitor(localKeyMonitor) }
        localMouseMonitor = nil
        globalMouseMonitor = nil
        localKeyMonitor = nil
        let center = NotificationCenter.default
        parentWindowObservers.forEach { center.removeObserver($0) }
        parentWindowObservers = []
    }

    /// Tells the SwiftUI side to flip `isPresented` false, which drives
    /// `dismiss()` via the modifier's `onChange`. Idempotent.
    private func requestDismiss() {
        guard panel != nil else { return }
        let callback = onDismiss
        dismiss()
        callback?()
    }

    func windowWillClose(_ notification: Notification) {
        requestDismiss()
    }
}

/// Zero-footprint `NSView` bridge used only to obtain the trigger's
/// underlying `NSView` (for window + screen-coordinate lookups). Sized to
/// match its SwiftUI parent via `.background`, so its bounds mirror the
/// trigger's bounds; it draws nothing and never intercepts hit-testing.
private struct AinkradFloatingPanelAnchor: NSViewRepresentable {
    let controller: AinkradFloatingPanelController
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        controller.anchorView = view
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {
        controller.anchorView = nsView
    }
}

private struct AinkradFloatingPanelModifier<PanelContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    var maxHeight: CGFloat
    @ViewBuilder var panelContent: () -> PanelContent

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradStatusColors) private var statusColors

    @State private var controller = AinkradFloatingPanelController()

    func body(content: Content) -> some View {
        content
            .background(AinkradFloatingPanelAnchor(controller: controller))
            .onChange(of: isPresented) { _, newValue in
                if newValue {
                    present()
                } else {
                    controller.dismiss()
                }
            }
            .onDisappear { controller.dismiss() }
    }

    private func present() {
        // NSHostingView doesn't inherit the SwiftUI environment from the call
        // site, so the theme/typography/status-color environment is captured
        // here and re-injected onto the hosted content explicitly.
        let theme = theme
        let typo = typo
        let statusColors = statusColors
        controller.present(maxHeight: maxHeight) {
            panelContent()
                .environment(\.ainkradTheme, theme)
                .environment(\.ainkradTypography, typo)
                .environment(\.ainkradStatusColors, statusColors)
        } onDismiss: {
            isPresented = false
        }
    }
}

public extension View {
    /// Presents `content` in a top-level, custom-drawn floating panel
    /// anchored just below this view — mirrors `.popover`'s ergonomics but
    /// renders in an app-level `NSPanel` instead of an in-view `.overlay`, so
    /// it is never clipped by an ancestor's bounds and floats above every
    /// other window/plugin surface. Content is capped at `maxHeight` and
    /// scrolls if taller. Dismisses on selection (caller sets `isPresented`
    /// false), Esc, an outside click, or the parent window losing key/moving.
    func ainkradFloatingPanel<PanelContent: View>(
        isPresented: Binding<Bool>,
        maxHeight: CGFloat = 320,
        @ViewBuilder content: @escaping () -> PanelContent
    ) -> some View {
        modifier(AinkradFloatingPanelModifier(isPresented: isPresented, maxHeight: maxHeight, panelContent: content))
    }
}
