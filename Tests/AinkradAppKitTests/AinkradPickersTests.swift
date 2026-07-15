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

@Suite("AinkradSelect option rows")
struct AinkradSelectRowsTests {
    @Test("flags the selected row and only that row")
    func flagsSelectedRow() {
        let rows = selectOptionRows(items: ["a", "b", "c"], selected: "b")
        #expect(rows.map(\.item) == ["a", "b", "c"])
        #expect(rows.map(\.isSelected) == [false, true, false])
    }

    @Test("selecting a new item updates a testable reducer binding")
    func selectingUpdatesBinding() {
        var selection = "a"
        func select(_ item: String) { selection = item }
        select("c")
        let rows: [(item: String, isSelected: Bool)] = selectOptionRows(items: ["a", "b", "c"], selected: selection)
        #expect(rows.map(\.isSelected) == [false, false, true])
    }

    @Test("no item selected flags nothing")
    func noneSelected() {
        let rows = selectOptionRows(items: ["a", "b"], selected: "z")
        #expect(rows.allSatisfy { !$0.isSelected })
    }
}
