import SwiftUI
import AppKit

public extension Color {
    /// Black or white, whichever reads on top of this color. Used by filled
    /// controls (selected picker segment, primary button) for their label.
    var contrastingText: Color {
        let ns = NSColor(self).usingColorSpace(.deviceRGB) ?? .white
        let luminance = 0.299 * ns.redComponent + 0.587 * ns.greenComponent + 0.114 * ns.blueComponent
        return luminance > 0.6 ? .black : .white
    }
}
