import SwiftUI

/// Centered modal confirm dialog — a full-PARENT-WINDOW dim + blur backdrop
/// behind a centered chamfer panel with a title, message, and Cancel/confirm
/// `AinkradButton` actions (destructive requests render the confirm action
/// in `.danger`). Presented via `AinkradFloatingPanel`'s modal (cover) mode:
/// the backdrop and centering need a top-level, window-sized panel — an
/// in-view `.overlay` only covers whatever ancestor view happens to host it,
/// which reads as a small chamfer panel anchored near the trigger rather
/// than a true modal. Place it anywhere (it has zero footprint while
/// `isPresented` is false) — it works from any surface without the host
/// needing to install anything, the same way `AinkradSelect`'s dropdown
/// does. Tapping the scrim or Cancel dismisses; Confirm runs the action then
/// dismisses.
public struct AinkradConfirmDialog: View {
    @Binding private var isPresented: Bool
    private let title: String
    private let message: String
    private let confirmTitle: String
    private let isDestructive: Bool
    private let onConfirm: () -> Void

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        confirmTitle: String = "Confirm",
        isDestructive: Bool = false,
        onConfirm: @escaping () -> Void
    ) {
        self._isPresented = isPresented
        self.title = title
        self.message = message
        self.confirmTitle = confirmTitle
        self.isDestructive = isDestructive
        self.onConfirm = onConfirm
    }

    public var body: some View {
        // `ainkradModalPanel` re-injects this view's `\.ainkradTheme` /
        // `\.ainkradTypography` / `\.ainkradStatusColors` onto the hosted
        // content automatically (an `NSHostingView` doesn't otherwise
        // inherit the SwiftUI environment from the call site), so
        // `modalContent` sees the same environment it would if it were
        // rendered in-place.
        Color.clear
            .frame(width: 0, height: 0)
            .ainkradModalPanel(isPresented: $isPresented) {
                modalContent
            }
    }

    private var modalContent: some View {
        ZStack {
            VisualEffectBlur(level: .hud, blendingMode: .behindWindow)
                .ignoresSafeArea()
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { isPresented = false }
            dialogCard
                .transition(
                    reduceMotion
                        ? .opacity
                        : .scale(scale: 0.94, anchor: .center).combined(with: .opacity)
                )
        }
        .animation(reduceMotion ? nil : AinkradMotion.materialize, value: isPresented)
    }

    private var dialogCard: some View {
        VStack(alignment: .leading, spacing: AinkradSpacing.md) {
            Text(title.uppercased())
                .font(AinkradFontResolver.font(.headline, weight: .semibold, typography: typo))
                .tracking(0.6)
                .foregroundStyle(theme.foreground)
            Text(message)
                .font(AinkradFontResolver.font(.body, typography: typo))
                .foregroundStyle(theme.foreground.opacity(0.75))
            HStack(spacing: AinkradSpacing.sm) {
                Spacer(minLength: 0)
                AinkradButton(title: "Cancel", style: .ghost) { isPresented = false }
                AinkradButton(title: confirmTitle, style: isDestructive ? .danger : .primary) {
                    onConfirm()
                    isPresented = false
                }
            }
        }
        .padding(AinkradSpacing.lg)
        .frame(maxWidth: 360)
        .ainkradPanel(showsBrackets: true)
    }
}
