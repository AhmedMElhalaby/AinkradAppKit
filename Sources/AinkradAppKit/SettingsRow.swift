import SwiftUI
import AinkradAppKitContract
import AinkradAppKitUI

/// How a row arranges label and control. Chosen from the detail pane's
/// width, not the window's — a narrow pane inside a wide window still stacks.
public enum SettingsRowLayout: Sendable, Equatable {
    case stacked
    case sideBySide

    public init(detailWidth: CGFloat) {
        self = detailWidth > SettingsMetrics.wideBreakpoint ? .sideBySide : .stacked
    }
}

/// One row = one setting. Label, help on the second line (never a tooltip —
/// hover-hidden explanations make settings unlearnable), optional badges, and
/// the control in a fixed-width trailing column so every control in a pane
/// lines up on one vertical rail.
public struct SettingsRow: View {
    @Environment(\.ainkradTheme) private var tokens
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    private let field: SettingsField
    private let layout: SettingsRowLayout
    @State private var isHovered = false

    public init(field: SettingsField, layout: SettingsRowLayout) {
        self.field = field
        self.layout = layout
    }

    public static func badges(for field: SettingsField) -> [String] {
        var result: [String] = []
        if field.isAdvanced { result.append("Advanced") }
        if field.requiresRestart { result.append("Restart required") }
        return result
    }

    public static func showsRevert(for field: SettingsField) -> Bool {
        field.reset != nil && field.isModified()
    }

    /// Quantizes `value` to the nearest multiple of `step` relative to
    /// `range.lowerBound`, then clamps to `range`. `AinkradSlider` has no
    /// native step; this is the glue that gives `.slider(step:)` teeth
    /// without touching the shared `AinkradAppKitUI` component. A
    /// non-positive `step` (0 or negative) disables quantization — the value
    /// passes through unchanged aside from the clamp, avoiding a
    /// divide-by-zero. Pure — unit-testable without a rendered view.
    public static func quantize(_ value: Double, step: Double, range: ClosedRange<Double>) -> Double {
        let clamped = min(max(value, range.lowerBound), range.upperBound)
        guard step > 0 else { return clamped }
        let steps = ((clamped - range.lowerBound) / step).rounded()
        let quantized = range.lowerBound + steps * step
        return min(max(quantized, range.lowerBound), range.upperBound)
    }

    public var body: some View {
        Group {
            switch layout {
            case .sideBySide:
                HStack(alignment: .top, spacing: 12) {
                    labelColumn
                    Spacer(minLength: 12)
                    control.frame(width: SettingsMetrics.controlColumnWidth, alignment: .trailing)
                }
            case .stacked:
                VStack(alignment: .leading, spacing: 10) {
                    labelColumn
                    control.frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(14)
        .background(ChamferShape(cut: AinkradRadius.md).fill(tokens.surfaceElevated.opacity(0.5)))
        .overlay(ChamferShape(cut: AinkradRadius.md)
            .strokeBorder(tokens.accentPrimary.opacity(isHovered ? 0.3 : 0.15), lineWidth: 1))
        .onHover { isHovered = $0 }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: isHovered)
    }

    private var labelColumn: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(field.label)
                    .font(AinkradFontResolver.font(.body, weight: .medium, typography: typo))
                    .foregroundStyle(tokens.foreground.opacity(0.9))
                ForEach(Self.badges(for: field), id: \.self) { badge in
                    AinkradBadge(text: badge.uppercased(), tint: tokens.accentSecondary)
                }
                if isHovered, Self.showsRevert(for: field), let reset = field.reset {
                    Button(action: reset) {
                        // `.system(size:)` here sizes an SF Symbol *glyph*,
                        // not text — the AinkradFont-only rule governs text
                        // typography, not icon point size, so this isn't a
                        // violation of it.
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 10))
                            .foregroundStyle(tokens.accentSecondary.opacity(0.9))
                    }
                    .buttonStyle(.plain)
                    .help(field.defaultDescription.map { "Reset to \($0)" } ?? "Reset to default")
                }
            }
            if let help = field.help {
                Text(help)
                    .font(AinkradFontResolver.font(.caption, typography: typo))
                    .foregroundStyle(tokens.foreground.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var control: some View {
        switch field.kind {
        case .toggle(let binding):
            AinkradToggle(isOn: binding)
        case .select(let options, let selection):
            // `AinkradSegmentedPicker` requires `T: Hashable`; `SettingsOption`
            // is only `Identifiable`. The field's binding already holds the
            // selected option's `id` (a `String`, which is `Hashable`), so the
            // picker operates directly on ids — no extra glue binding needed.
            AinkradSegmentedPicker(
                items: options.map(\.id),
                selection: selection,
                label: { id in options.first { $0.id == id }?.title ?? id }
            )
            .fixedSize()
        case .slider(let range, let step, let value):
            // `AinkradSlider` has no native step, so it's wrapped in a
            // shim binding that quantizes writes via `Self.quantize`
            // before they reach the underlying `value` binding.
            AinkradSlider(
                value: Binding(
                    get: { value.wrappedValue },
                    set: { value.wrappedValue = Self.quantize($0, step: step, range: range) }
                ),
                in: range
            )
        case .text(let binding):
            AinkradTextField(text: binding, placeholder: "")
        case .secure(let binding):
            AinkradSecureField(text: binding, placeholder: "")
        case .shortcut(let binding):
            Text(binding.wrappedValue)
                .font(AinkradFontResolver.font(.mono, typography: typo))
                .foregroundStyle(tokens.foreground.opacity(0.8))
        case .action(let title, let handler):
            AinkradButton(title: title, action: handler)
        case .custom(let view):
            view
        }
    }
}
