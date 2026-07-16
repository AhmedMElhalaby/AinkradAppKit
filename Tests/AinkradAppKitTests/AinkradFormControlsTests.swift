import Testing
import SwiftUI
@testable import AinkradAppKit

@Suite("AinkradFormControls")
struct AinkradFormControlsTests {
    @Test("FormRow exposes its title and help")
    func formRow() {
        let row = AinkradFormRow(title: "Enabled", help: "Turns it on") { EmptyView() }
        #expect(row.title == "Enabled")
        #expect(row.help == "Turns it on")
    }
}
