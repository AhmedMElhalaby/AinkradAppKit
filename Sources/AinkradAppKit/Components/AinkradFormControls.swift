import SwiftUI

public struct AinkradToggle: View {
    @Binding private var isOn: Bool
    @Environment(\.ainkradTheme) private var theme
    public init(isOn: Binding<Bool>) { self._isOn = isOn }
    public var body: some View {
        Button { isOn.toggle() } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule().fill(isOn ? theme.accentPrimary.opacity(0.9) : theme.surface)
                    .overlay(Capsule().strokeBorder(isOn ? theme.accentSecondary.opacity(0.65) : theme.foreground.opacity(0.18), lineWidth: 1))
                Circle().fill(.white).padding(3)
                    .shadow(color: isOn ? theme.accentSecondary.opacity(0.7) : .black.opacity(0.4), radius: 3)
            }.frame(width: 40, height: 22).contentShape(Capsule())
        }.buttonStyle(.plain).animation(AinkradMotion.hover, value: isOn)
    }
}

/// Masked entry with a reveal (eye) toggle — HUD card styling, no separator
/// lines. Ported from the host's `NeonSecureField`; never logs or otherwise
/// surfaces the value beyond this field.
public struct AinkradSecureField: View {
    @Binding private var text: String
    private let placeholder: String
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @State private var isRevealed = false

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
        .background(RoundedRectangle(cornerRadius: AinkradRadius.sm).fill(theme.surfaceElevated.opacity(0.5)))
        .overlay(RoundedRectangle(cornerRadius: AinkradRadius.sm).strokeBorder(theme.accentPrimary.opacity(0.15), lineWidth: 1))
    }
}

/// Plain-text entry mirroring `AinkradSecureField`'s chrome, minus the reveal
/// toggle and mono font.
public struct AinkradTextField: View {
    @Binding private var text: String
    private let placeholder: String
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo

    public init(text: Binding<String>, placeholder: String) {
        self._text = text; self.placeholder = placeholder
    }
    public var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .font(AinkradFontResolver.font(.body, typography: typo))
            .foregroundStyle(theme.foreground)
            .tint(theme.accentSecondary)
            .padding(.horizontal, AinkradSpacing.md)
            .padding(.vertical, AinkradSpacing.sm)
            .background(RoundedRectangle(cornerRadius: AinkradRadius.sm).fill(theme.surfaceElevated.opacity(0.5)))
            .overlay(RoundedRectangle(cornerRadius: AinkradRadius.sm).strokeBorder(theme.accentPrimary.opacity(0.15), lineWidth: 1))
    }
}

/// Accent-tinted slider matching the same surfaceElevated/radius-sm chrome.
public struct AinkradSlider: View {
    @Binding private var value: Double
    private let bounds: ClosedRange<Double>
    @Environment(\.ainkradTheme) private var theme

    public init(value: Binding<Double>, in bounds: ClosedRange<Double>) {
        self._value = value; self.bounds = bounds
    }
    public var body: some View {
        Slider(value: $value, in: bounds)
            .tint(theme.accentSecondary)
            .padding(.horizontal, AinkradSpacing.md)
            .padding(.vertical, AinkradSpacing.xs)
            .background(RoundedRectangle(cornerRadius: AinkradRadius.sm).fill(theme.surfaceElevated.opacity(0.5)))
            .overlay(RoundedRectangle(cornerRadius: AinkradRadius.sm).strokeBorder(theme.accentPrimary.opacity(0.15), lineWidth: 1))
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
                Text(title).font(AinkradFontResolver.font(.body, typography: typo)).foregroundStyle(theme.foreground)
                if let help { Text(help).font(AinkradFontResolver.font(.caption, typography: typo)).foregroundStyle(theme.foreground.opacity(0.55)) }
            }
            Spacer(minLength: AinkradSpacing.lg)
            control
        }
    }
}
