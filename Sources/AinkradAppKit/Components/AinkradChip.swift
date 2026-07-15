import SwiftUI

/// Semantic status used by `AinkradBadge` (and available to any component
/// that needs a status→color mapping). Maps onto the status colors carried by
/// `HostThemeTokens`.
public enum AinkradStatus: CaseIterable, Sendable {
    case neutral, success, warning, danger

    /// The theme token this status maps to. Pure — unit-testable without a view.
    public func color(in theme: HostThemeTokens) -> Color {
        switch self {
        case .neutral: return theme.foreground
        case .success: return theme.success
        case .warning: return theme.warning
        case .danger: return theme.danger
        }
    }
}

/// Pill/chamfer tag — optional leading icon, optional custom-drawn remove (✕)
/// affordance (never a native button chrome).
public struct AinkradChip: View {
    private let label: String
    private let systemName: String?
    private let onRemove: (() -> Void)?

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovering = false

    public init(label: String, systemName: String? = nil, onRemove: (() -> Void)? = nil) {
        self.label = label; self.systemName = systemName; self.onRemove = onRemove
    }

    /// Whether this chip shows a remove affordance.
    public var isRemovable: Bool { onRemove != nil }

    public var body: some View {
        HStack(spacing: AinkradSpacing.xs) {
            if let systemName {
                Image(systemName: systemName).font(.system(size: 10, weight: .semibold))
            }
            Text(label)
                .font(AinkradFontResolver.font(.caption, typography: typo))
            if isRemovable {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .padding(3)
                    .contentShape(Rectangle())
                    .onTapGesture { onRemove?() }
            }
        }
        .foregroundStyle(theme.foreground.opacity(0.85))
        .padding(.horizontal, AinkradSpacing.sm)
        .padding(.vertical, AinkradSpacing.xs)
        .background(ChamferShape(cut: 5).fill(theme.surfaceElevated.opacity(hovering ? 0.65 : 0.45)))
        .overlay(ChamferShape(cut: 5).strokeBorder(theme.accentSecondary.opacity(hovering ? 0.6 : 0.3), lineWidth: 1))
        .scaleEffect(hovering && !reduceMotion ? 1.03 : 1.0)
        .animation(AinkradMotion.hover, value: hovering)
        .onHover { hovering = $0 }
    }
}

/// Small status pill — filled with the status color at low opacity, text in
/// the status color.
public struct AinkradBadge: View {
    private let text: String
    private let status: AinkradStatus

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo

    public init(text: String, status: AinkradStatus = .neutral) {
        self.text = text; self.status = status
    }

    private var color: Color { status.color(in: theme) }

    public var body: some View {
        Text(text.uppercased())
            .font(AinkradFontResolver.font(.caption, weight: .semibold, typography: typo))
            .tracking(0.6)
            .foregroundStyle(color)
            .padding(.horizontal, AinkradSpacing.sm)
            .padding(.vertical, AinkradSpacing.xs / 2)
            .background(ChamferShape(cut: 4).fill(color.opacity(0.16)))
            .overlay(ChamferShape(cut: 4).strokeBorder(color.opacity(0.55), lineWidth: 1))
    }
}

/// Keycap chip — monospaced, bracketed, for displaying a keyboard shortcut.
public struct AinkradKbd: View {
    private let key: String

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo

    public init(_ key: String) {
        self.key = key
    }

    public var body: some View {
        Text("[\(key)]")
            .font(AinkradFontResolver.font(.mono, weight: .medium, typography: typo))
            .foregroundStyle(theme.foreground.opacity(0.75))
            .padding(.horizontal, AinkradSpacing.xs + 2)
            .padding(.vertical, 2)
            .background(ChamferShape(cut: 3).fill(theme.surfaceElevated.opacity(0.55)))
            .overlay(ChamferShape(cut: 3).strokeBorder(theme.foreground.opacity(0.2), lineWidth: 1))
    }
}
