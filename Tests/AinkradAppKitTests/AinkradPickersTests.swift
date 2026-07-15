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

@Suite("AinkradMultiSelect toggle")
struct AinkradMultiSelectTests {
    @Test("toggling an absent item adds it")
    func adds() {
        let result = toggledSelection("b", in: ["a"])
        #expect(result == ["a", "b"])
    }

    @Test("toggling a present item removes it")
    func removes() {
        let result = toggledSelection("a", in: ["a", "b"])
        #expect(result == ["b"])
    }

    @Test("toggling into an empty set")
    func togglesIntoEmpty() {
        let result = toggledSelection("a", in: [])
        #expect(result == ["a"])
    }
}

@Suite("AinkradCombobox filter")
struct AinkradComboboxTests {
    @Test("empty query returns all items")
    func emptyQueryReturnsAll() {
        let result = comboboxFilter(items: ["Alpha", "Beta"], query: "", label: { $0 })
        #expect(result == ["Alpha", "Beta"])
    }

    @Test("query matches case-insensitively via label, substring anywhere")
    func matchesCaseInsensitiveSubstring() {
        let result = comboboxFilter(items: ["Alpha", "Beta", "Gamma"], query: "ph", label: { $0 })
        #expect(result == ["Alpha"])
    }

    @Test("no matches returns empty")
    func noMatches() {
        let result = comboboxFilter(items: ["Alpha", "Beta"], query: "zzz", label: { $0 })
        #expect(result.isEmpty)
    }
}
