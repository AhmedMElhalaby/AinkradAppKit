import Testing
@testable import AinkradAppKit

@Suite("Picker selection")
struct AinkradPickerTests {
    @Test("selectionIndex finds the current item")
    func index() {
        #expect(pickerSelectionIndex(items: ["a","b","c"], selection: "b") == 1)
        #expect(pickerSelectionIndex(items: ["a","b"], selection: "z") == nil)
    }
}
