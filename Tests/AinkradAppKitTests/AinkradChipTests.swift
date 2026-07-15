import Testing
@testable import AinkradAppKit

@Suite("AinkradChip")
struct AinkradChipTests {
    @Test("isRemovable reflects presence of onRemove")
    func removable() {
        #expect(AinkradChip(label: "swift", onRemove: {}).isRemovable == true)
        #expect(AinkradChip(label: "swift", onRemove: nil).isRemovable == false)
    }
}

@Suite("AinkradStatus")
struct AinkradStatusTests {
    @Test("four cases")
    func caseCount() {
        #expect(AinkradStatus.allCases.count == 4)
    }

    @Test("color(in:) picks the matching theme token field")
    func colorMapping() {
        let theme = HostThemeTokens(
            themeID: "test", background: .black, surface: .gray, surfaceElevated: .gray,
            accentPrimary: .blue, accentSecondary: .purple, accentTertiary: .pink,
            foreground: .white, success: .green, warning: .yellow, danger: .red
        )
        #expect(AinkradStatus.success.color(in: theme) == theme.success)
        #expect(AinkradStatus.warning.color(in: theme) == theme.warning)
        #expect(AinkradStatus.danger.color(in: theme) == theme.danger)
        #expect(AinkradStatus.neutral.color(in: theme) == theme.foreground)
    }
}
