import SwiftUI

/// How many of `segments` should read as "filled" for `value` out of `total`.
/// Clamps the ratio into `0...1` first (so overshoot/negative values never
/// under/overflow), then rounds to the nearest segment. A non-positive
/// `total` or `segments` yields `0`. Pure — `AinkradStatusBar`'s HP-bar
/// segment math, unit-testable without SwiftUI.
public func filledSegments(value: Double, total: Double, segments: Int) -> Int {
    guard total > 0, segments > 0 else { return 0 }
    let ratio = max(0, min(value / total, 1))
    return Int((ratio * Double(segments)).rounded())
}

/// Which color source an `AinkradStatusBar` fills with.
public enum AinkradStatusBarKind: Sendable {
    /// The host theme's primary accent.
    case accent
    /// One of `\.ainkradStatusColors`, via the shared `AinkradStatus` enum.
    case status(AinkradStatus)

    func color(theme: HostThemeTokens, statusColors: AinkradStatusColors) -> Color {
        switch self {
        case .accent: return theme.accentPrimary
        case .status(let status): return status.color(in: theme, statusColors: statusColors)
        }
    }
}

/// HP-bar-style segmented gauge — a row of small chamfered blocks, the
/// leading `filledSegments(value:total:segments:)` of them lit with a
/// gradient fill in `kind`'s color, the rest dimmed. Reads theme/status
/// colors from the environment.
public struct AinkradStatusBar: View {
    private let value: Double
    private let total: Double
    private let kind: AinkradStatusBarKind
    private let segments: Int

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradStatusColors) private var statusColors
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(value: Double, total: Double = 1, kind: AinkradStatusBarKind = .accent, segments: Int = 12) {
        self.value = value
        self.total = total
        self.kind = kind
        self.segments = segments
    }

    private var filled: Int { filledSegments(value: value, total: total, segments: segments) }
    private var color: Color { kind.color(theme: theme, statusColors: statusColors) }

    public var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<max(segments, 0), id: \.self) { index in
                let isFilled = index < filled
                ChamferShape(cut: 2, corners: .all)
                    .fill(
                        isFilled
                            ? LinearGradient(colors: [color.opacity(0.65), color], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [theme.foreground.opacity(0.08)], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(height: 8)
                    .shadow(color: color.opacity(isFilled ? 0.5 : 0), radius: isFilled ? 2 : 0)
            }
        }
        .animation(reduceMotion ? nil : AinkradMotion.present, value: filled)
    }
}

/// The rotation angle (degrees) `AinkradSpinner`'s animated arc should target
/// for its `.rotationEffect`, given whether Reduce Motion is active and
/// whether the spin has been toggled on. Reduce Motion always pins the ring
/// static at `0`; otherwise the toggle drives the looping `.animation(...)`
/// between `0` and a full turn. Pure — unit-testable without SwiftUI's
/// animation runtime.
public func spinnerRotationAngle(reduceMotion: Bool, isSpinning: Bool) -> Double {
    guard !reduceMotion else { return 0 }
    return isSpinning ? 360 : 0
}

/// Custom rotating arc "reactor ring" — the Cardinal HUD stand-in for
/// `ProgressView`'s spinner. Freezes as a static ring under Reduce Motion
/// instead of animating.
///
/// Drives the spin via a `Bool` toggled once in `.onAppear`, matched with an
/// `.animation(_:value:)` on the container (rather than wrapping the state
/// change itself in `withAnimation`) — the more robust pattern for a
/// `repeatForever` loop that needs to keep running for the view's entire
/// lifetime, not just the instant it appears.
public struct AinkradSpinner: View {
    private let size: CGFloat

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isSpinning = false

    public init(size: CGFloat = 20) {
        self.size = size
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(theme.foreground.opacity(0.12), lineWidth: max(1.5, size * 0.08))
            Circle()
                .trim(from: 0, to: 0.28)
                .stroke(theme.accentSecondary, style: StrokeStyle(lineWidth: max(1.5, size * 0.08), lineCap: .round))
                .shadow(color: theme.accentSecondary.opacity(0.6), radius: 3)
                .rotationEffect(.degrees(spinnerRotationAngle(reduceMotion: reduceMotion, isSpinning: isSpinning)))
        }
        .frame(width: size, height: size)
        .animation(reduceMotion ? nil : .linear(duration: 0.9).repeatForever(autoreverses: false), value: isSpinning)
        .onAppear {
            guard !reduceMotion else { return }
            isSpinning = true
        }
    }
}
