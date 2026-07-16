import SwiftUI

/// Centered chamfer modal, scoped to the host surface it's attached to —
/// mirrors `.ainkradConfirmDialog`'s scoped-overlay approach (dim + subtle
/// blur filling THIS view's own bounds, never a full-window cover), but
/// hosts arbitrary content instead of a fixed title/message/buttons layout.
/// Dismisses on scrim tap or Esc; materialize/scale transition gated on
/// `ainkradReduceMotion`.
private struct AinkradModalModifier<ModalContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    @ViewBuilder var modalContent: () -> ModalContent

    @Environment(\.ainkradReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay {
            if isPresented {
                ZStack {
                    VisualEffectBlur(level: .panel, blendingMode: .withinWindow)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .opacity(0.6)
                    Color.black.opacity(0.45)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture { isPresented = false }

                    modalContent()
                        .padding(AinkradSpacing.lg)
                        .frame(maxWidth: 480)
                        .ainkradPanel(showsBrackets: true)
                        .transition(
                            reduceMotion
                                ? .opacity
                                : .scale(scale: 0.94, anchor: .center).combined(with: .opacity)
                        )

                    dismissKey
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(reduceMotion ? nil : AinkradMotion.materialize, value: isPresented)
            }
        }
    }

    /// Invisible Esc-key dismiss affordance — a real (custom-drawn, zero-size,
    /// zero-opacity) `Button` rather than any native menu/shortcut chrome, so
    /// pressing Esc while this scoped overlay is key dismisses it.
    private var dismissKey: some View {
        Button("") { isPresented = false }
            .keyboardShortcut(.escape, modifiers: [])
            .opacity(0)
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
    }
}

/// Chamfer sheet sliding in from `edge`, scoped to the host surface —
/// dim behind, materialize + slide gated on `ainkradReduceMotion`, dismiss on
/// scrim tap or Esc.
private struct AinkradSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    var edge: Edge
    @ViewBuilder var sheetContent: () -> SheetContent

    @Environment(\.ainkradReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay {
            if isPresented {
                ZStack(alignment: alignment) {
                    Color.black.opacity(0.45)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture { isPresented = false }

                    sheetContent()
                        .padding(AinkradSpacing.lg)
                        .frame(maxWidth: isHorizontalEdge ? .infinity : 360)
                        .ainkradPanel(showsBrackets: true)
                        .transition(
                            reduceMotion
                                ? .opacity
                                : .move(edge: edge).combined(with: .opacity)
                        )

                    Button("") { isPresented = false }
                        .keyboardShortcut(.escape, modifiers: [])
                        .opacity(0)
                        .frame(width: 0, height: 0)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(reduceMotion ? nil : AinkradMotion.materialize, value: isPresented)
            }
        }
    }

    /// `.top`/`.bottom` sheets span the host's width; `.leading`/`.trailing`
    /// are fixed-width side sheets.
    private var isHorizontalEdge: Bool { edge == .top || edge == .bottom }

    private var alignment: Alignment {
        switch edge {
        case .top: return .top
        case .bottom: return .bottom
        case .leading: return .leading
        case .trailing: return .trailing
        }
    }
}

public extension View {
    /// Presents a centered chamfer modal scoped to THIS view's own bounds,
    /// mirroring `.ainkradConfirmDialog`'s dim+blur scrim. Content is
    /// arbitrary — supply your own layout/buttons. Tapping the scrim or Esc
    /// dismisses (set `isPresented` false); the caller decides what else
    /// dismissing does.
    func ainkradModal<ModalContent: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> ModalContent
    ) -> some View {
        modifier(AinkradModalModifier(isPresented: isPresented, modalContent: content))
    }

    /// Presents a chamfer sheet sliding in from `edge`, scoped to THIS view's
    /// own bounds. Dim behind, slide/materialize gated on
    /// `ainkradReduceMotion`, dismiss on scrim tap or Esc.
    func ainkradSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        edge: Edge = .bottom,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        modifier(AinkradSheetModifier(isPresented: isPresented, edge: edge, sheetContent: content))
    }
}
