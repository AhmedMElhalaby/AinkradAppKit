import Testing
import SwiftUI
@testable import AinkradAppKitUI

@Suite("AinkradCaptionedRow accessibility")
@MainActor
struct AinkradCaptionedRowTests {
    @Test("the caption is retained, because it is the row's accessibility label")
    func captionIsCarried() {
        // The caption used to be `.accessibilityHidden(true)` and discarded, on
        // the reasoning that the control below carried the real label. None of
        // the kit's form controls do — so a settings pane read as a list of
        // anonymous buttons, with five identical "Alert / Quiet / Off" pickers
        // and nothing to say which source each belonged to.
        //
        // The modifiers are not inspectable from here; this guards the input
        // they depend on. The behaviour itself needs a VoiceOver pass.
        let row = AinkradCaptionedRow("Delivery") { EmptyView() }
        #expect(row.caption == "Delivery")
    }
}
