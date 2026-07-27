import Testing
@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@Suite("AinkradCommandMenu selection toggle")
struct CommandMenuToggleTests {
    @Test("tapping an unselected item selects it")
    func selectsNew() {
        #expect(commandMenuToggled("b", current: "a") == "b")
    }

    @Test("tapping the already-selected item deselects it")
    func deselectsCurrent() {
        #expect(commandMenuToggled("a", current: "a") == nil)
    }

    @Test("tapping any item when nothing is selected selects it")
    func selectsFromNil() {
        #expect(commandMenuToggled("a", current: nil) == "a")
    }
}

@Suite("AinkradNavList rows")
struct NavListRowsTests {
    @Test("flags the selected row and only that row")
    func flagsSelectedRow() {
        let rows = navListRows(items: ["a", "b", "c"], selected: "b")
        #expect(rows.map(\.item) == ["a", "b", "c"])
        #expect(rows.map(\.isSelected) == [false, true, false])
    }

    @Test("a selection absent from items flags nothing")
    func noMatch() {
        let rows = navListRows(items: ["a", "b"], selected: "z")
        #expect(rows.allSatisfy { !$0.isSelected })
    }

    @Test("an empty item list yields no rows")
    func empty() {
        let rows = navListRows(items: [String](), selected: "a")
        #expect(rows.isEmpty)
    }
}
