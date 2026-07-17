import SwiftUI

/// Cardinal HUD switch — chamfered track (never a native `Toggle`), a
/// luminous thumb, and an accent glow that brightens while on.
public struct AinkradToggle: View {
    @Binding private var isOn: Bool
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false

    public init(isOn: Binding<Bool>) { self._isOn = isOn }

    public var body: some View {
        Button { isOn.toggle() } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                ChamferShape(cut: 6, corners: .all)
                    .fill(isOn ? theme.accentPrimary.opacity(0.9) : theme.surfaceElevated.opacity(0.6))
                ChamferShape(cut: 6, corners: .all)
                    .strokeBorder(isOn ? theme.accentSecondary.opacity(0.75) : theme.foreground.opacity(hovering ? 0.35 : 0.18), lineWidth: 1.25)
                Circle().fill(.white).padding(3)
                    .shadow(color: isOn ? theme.accentSecondary.opacity(0.75) : .black.opacity(0.4), radius: 3)
            }
            .frame(width: 40, height: 22)
            .shadow(color: theme.accentSecondary.opacity(isOn ? 0.45 : 0), radius: isOn ? 6 : 0)
            .contentShape(ChamferShape(cut: 6, corners: .all))
        }
        .buttonStyle(.plain)
        .animation(AinkradMotion.hover, value: isOn)
        .animation(AinkradMotion.hover, value: hovering)
        .onHover { hovering = $0 }
    }
}

/// Masked entry with a reveal (eye) toggle — chamfer field + luminous focus
/// ring, no separator lines. Ported from the host's `NeonSecureField`; never
/// logs or otherwise surfaces the value beyond this field.
public struct AinkradSecureField: View {
    @Binding private var text: String
    private let placeholder: String
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @State private var isRevealed = false
    @FocusState private var isFocused: Bool

    public init(text: Binding<String>, placeholder: String) {
        self._text = text; self.placeholder = placeholder
    }
    public var body: some View {
        HStack(spacing: AinkradSpacing.sm) {
            Group {
                if isRevealed {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .focused($isFocused)
            .textFieldStyle(.plain)
            .font(AinkradFontResolver.font(.mono, typography: typo))
            .foregroundStyle(theme.foreground)
            .tint(theme.accentSecondary)

            Button { isRevealed.toggle() } label: {
                Image(systemName: isRevealed ? "eye.slash" : "eye")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.foreground.opacity(0.55))
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, AinkradSpacing.md)
        .padding(.vertical, AinkradSpacing.sm)
        .background(ChamferShape(cut: 6).fill(theme.surfaceElevated.opacity(0.5)))
        .overlay(ChamferShape(cut: 6).strokeBorder(theme.accentPrimary.opacity(isFocused ? 0.9 : 0.25), lineWidth: isFocused ? 1.5 : 1.25))
        .shadow(color: theme.accentSecondary.opacity(isFocused ? 0.45 : 0), radius: isFocused ? 6 : 0)
        .animation(AinkradMotion.hover, value: isFocused)
    }
}

/// Plain-text entry mirroring `AinkradSecureField`'s chamfer chrome, minus the
/// reveal toggle and mono font.
public struct AinkradTextField: View {
    @Binding private var text: String
    private let placeholder: String
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @FocusState private var isFocused: Bool

    public init(text: Binding<String>, placeholder: String) {
        self._text = text; self.placeholder = placeholder
    }
    public var body: some View {
        TextField(placeholder, text: $text)
            .focused($isFocused)
            .textFieldStyle(.plain)
            .font(AinkradFontResolver.font(.body, typography: typo))
            .foregroundStyle(theme.foreground)
            .tint(theme.accentSecondary)
            .padding(.horizontal, AinkradSpacing.md)
            .padding(.vertical, AinkradSpacing.sm)
            .background(ChamferShape(cut: 6).fill(theme.surfaceElevated.opacity(0.5)))
            .overlay(ChamferShape(cut: 6).strokeBorder(theme.accentPrimary.opacity(isFocused ? 0.9 : 0.25), lineWidth: isFocused ? 1.5 : 1.25))
            .shadow(color: theme.accentSecondary.opacity(isFocused ? 0.45 : 0), radius: isFocused ? 6 : 0)
            .animation(AinkradMotion.hover, value: isFocused)
    }
}

/// Chamfer field with a leading magnifier glyph and a custom clear (✕)
/// affordance — never a native search field.
public struct AinkradSearchField: View {
    @Binding private var text: String
    private let placeholder: String
    private let onSubmit: (() -> Void)?

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @FocusState private var isFocused: Bool

    public init(text: Binding<String>, placeholder: String, onSubmit: (() -> Void)? = nil) {
        self._text = text; self.placeholder = placeholder; self.onSubmit = onSubmit
    }

    public var body: some View {
        HStack(spacing: AinkradSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(theme.accentSecondary.opacity(isFocused ? 0.95 : 0.55))

            TextField(placeholder, text: $text)
                .focused($isFocused)
                .textFieldStyle(.plain)
                .font(AinkradFontResolver.font(.body, typography: typo))
                .foregroundStyle(theme.foreground)
                .tint(theme.accentSecondary)
                .onSubmit { onSubmit?() }

            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(theme.foreground.opacity(0.45))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AinkradSpacing.md)
        .padding(.vertical, AinkradSpacing.sm)
        .background(ChamferShape(cut: 6).fill(theme.surfaceElevated.opacity(0.5)))
        .overlay(ChamferShape(cut: 6).strokeBorder(theme.accentPrimary.opacity(isFocused ? 0.9 : 0.25), lineWidth: isFocused ? 1.5 : 1.25))
        .shadow(color: theme.accentSecondary.opacity(isFocused ? 0.45 : 0), radius: isFocused ? 6 : 0)
        .animation(AinkradMotion.hover, value: isFocused)
    }
}

/// Multiline chamfer field — same focus-ring/HUD chrome as the single-line
/// fields, backed by a native `TextEditor` for text-editing behavior (not a
/// styled selection control, so it isn't covered by the zero-native-controls
/// rule) with its default chrome stripped.
public struct AinkradTextArea: View {
    @Binding private var text: String
    private let placeholder: String
    private let autoFocus: Bool

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @FocusState private var isFocused: Bool

    /// Two EXPLICIT overloads (no defaulted param) so both mangled symbols
    /// exist: `init(text:placeholder:)` re-mints the exact symbol pre-d38b2a8
    /// plugins (e.g. Leyline) linked against — repairing the `dlopen` break the
    /// earlier defaulted-param change caused — while `autoFocus:` callers
    /// resolve to the 3-arg init. Swift prefers the non-defaulted 2-arg overload
    /// on exact 2-arg calls, so there is no ambiguity. NEVER collapse these back
    /// into one defaulted-param init (that changes/drops the 2-arg symbol → ABI
    /// break). See ainkrad-hostthemetokens-abi memory.
    public init(text: Binding<String>, placeholder: String) {
        self._text = text; self.placeholder = placeholder; self.autoFocus = false
    }

    /// `autoFocus` focuses the editor the first time it appears — for overlays
    /// (e.g. a summoned Quick-Ask) that should accept typing immediately.
    public init(text: Binding<String>, placeholder: String, autoFocus: Bool) {
        self._text = text; self.placeholder = placeholder; self.autoFocus = autoFocus
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(AinkradFontResolver.font(.body, typography: typo))
                    .foregroundStyle(theme.foreground.opacity(0.4))
                    .padding(.horizontal, AinkradSpacing.md + 4)
                    .padding(.vertical, AinkradSpacing.sm + 4)
                    .allowsHitTesting(false)
            }
            TextEditor(text: $text)
                .focused($isFocused)
                .scrollContentBackground(.hidden)
                .font(AinkradFontResolver.font(.body, typography: typo))
                .foregroundStyle(theme.foreground)
                .tint(theme.accentSecondary)
                .padding(.horizontal, AinkradSpacing.md)
                .padding(.vertical, AinkradSpacing.sm)
        }
        .frame(minHeight: 80)
        .background(ChamferShape(cut: 8).fill(theme.surfaceElevated.opacity(0.5)))
        .overlay(ChamferShape(cut: 8).strokeBorder(theme.accentPrimary.opacity(isFocused ? 0.9 : 0.25), lineWidth: isFocused ? 1.5 : 1.25))
        .shadow(color: theme.accentSecondary.opacity(isFocused ? 0.4 : 0), radius: isFocused ? 6 : 0)
        .animation(AinkradMotion.hover, value: isFocused)
        .onAppear {
            guard autoFocus else { return }
            DispatchQueue.main.async { isFocused = true }
        }
    }
}

/// Custom single-thumb HUD slider — chamfer-adjacent track + a glowing thumb
/// (never a native `Slider`).
public struct AinkradSlider: View {
    @Binding private var value: Double
    private let bounds: ClosedRange<Double>
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var dragging = false

    public init(value: Binding<Double>, in bounds: ClosedRange<Double>) {
        self._value = value; self.bounds = bounds
    }

    private var span: Double { max(bounds.upperBound - bounds.lowerBound, .leastNonzeroMagnitude) }
    private func fraction(_ value: Double) -> CGFloat { CGFloat((value - bounds.lowerBound) / span) }

    public var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let x = fraction(value) * width

            ZStack(alignment: .leading) {
                Capsule().fill(theme.surfaceElevated.opacity(0.6)).frame(height: 4)
                Capsule().fill(theme.accentSecondary.opacity(0.85)).frame(width: max(x, 0), height: 4)
                Circle()
                    .fill(theme.accentSecondary)
                    .frame(width: 14, height: 14)
                    .shadow(color: theme.accentSecondary.opacity(dragging ? 0.9 : 0.55), radius: dragging ? 8 : 4)
                    .scaleEffect(dragging && !reduceMotion ? 1.15 : 1.0)
                    .offset(x: x - 7)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        dragging = true
                        let clampedFraction = min(max(drag.location.x / max(width, 1), 0), 1)
                        value = bounds.lowerBound + Double(clampedFraction) * span
                    }
                    .onEnded { _ in dragging = false }
            )
        }
        .frame(height: 20)
        .animation(AinkradMotion.hover, value: dragging)
        .padding(.horizontal, AinkradSpacing.md)
        .padding(.vertical, AinkradSpacing.xs)
        .background(ChamferShape(cut: 6).fill(theme.surfaceElevated.opacity(0.3)))
        .overlay(ChamferShape(cut: 6).strokeBorder(theme.accentPrimary.opacity(0.2), lineWidth: 1))
    }
}

public struct AinkradFormRow<Control: View>: View {
    public let title: String
    public let help: String?
    private let control: Control
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    public init(title: String, help: String? = nil, @ViewBuilder control: () -> Control) {
        self.title = title; self.help = help; self.control = control()
    }
    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: AinkradSpacing.xs / 2) {
                HStack(spacing: AinkradSpacing.xs) {
                    Rectangle()
                        .fill(theme.accentSecondary.opacity(0.55))
                        .frame(width: 2, height: 12)
                    Text(title).font(AinkradFontResolver.font(.body, typography: typo)).foregroundStyle(theme.foreground)
                }
                if let help {
                    Text(help)
                        .font(AinkradFontResolver.font(.caption, typography: typo))
                        .foregroundStyle(theme.foreground.opacity(0.55))
                        .padding(.leading, AinkradSpacing.xs + 2)
                }
            }
            Spacer(minLength: AinkradSpacing.lg)
            control
        }
    }
}
