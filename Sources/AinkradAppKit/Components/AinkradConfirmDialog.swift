import SwiftUI

/// Centered modal confirm dialog — a scrim behind a chamfer panel with a
/// title, message, and Cancel/confirm `AinkradButton` actions (destructive
/// requests render the confirm action in `.danger`). Place it as an overlay
/// near the root of the surface it should block; it renders nothing while
/// `isPresented` is false, and tapping the scrim cancels.
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
        if isPresented {
            ZStack {
                Color.black.opacity(0.45)
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
