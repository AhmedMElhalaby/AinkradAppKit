import SwiftUI
import AinkradAppKitContract

/// A control with a caption in a fixed leading column.
///
/// Two-axis sections — typeface/size, icon colour/appearance — rendered as two
/// identical rows of pills read as ONE flat list of six options. "Auto, Blue,
/// Purple, System, Light, Dark" is unparseable without knowing where one
/// control ends and the next begins.
///
/// The column is a fixed width so stacked controls align down the page, which
/// is what makes them read as a form rather than as loose buttons.
public struct AinkradCaptionedRow<Content: View>: View {
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo

    private let caption: String
    private let content: Content

    public static var captionColumnWidth: CGFloat { 86 }

    public init(_ caption: String, @ViewBuilder content: () -> Content) {
        self.caption = caption
        self.content = content()
    }

    public var body: some View {
        HStack(alignment: .center, spacing: AinkradSpacing.md) {
            Text(caption)
                .font(AinkradFontResolver.font(.caption, weight: .medium, typography: typo))
                .foregroundStyle(theme.foreground.opacity(0.45))
                .frame(width: Self.captionColumnWidth, alignment: .leading)
                // The control below carries the real label; a visible caption
                // read out again is duplicate noise.
                .accessibilityHidden(true)
            content
            Spacer(minLength: 0)
        }
    }
}
