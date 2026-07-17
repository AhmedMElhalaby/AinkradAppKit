import Testing
import SwiftUI
@testable import AinkradAppKit

@Suite("AinkradToggleButton")
struct AinkradToggleButtonTests {
    @Test("isActive mirrors the binding")
    func mirrorsBinding() {
        var isOn = false
        let binding = Binding<Bool>(get: { isOn }, set: { isOn = $0 })
        let button = AinkradToggleButton(isOn: binding, systemName: "bolt")
        #expect(button.isActive == false)

        isOn = true
        let buttonOn = AinkradToggleButton(isOn: binding, systemName: "bolt")
        #expect(buttonOn.isActive == true)
    }
}

@Suite("AinkradIconButton")
struct AinkradIconButtonTests {
    @Test("all three call shapes construct (existing 2-arg + sized + sized+tooltip)")
    func constructs() {
        // Existing (byte-unchanged) init.
        _ = AinkradIconButton(systemName: "gear") {}
        // New sized init (tooltip defaulted nil).
        _ = AinkradIconButton(systemName: "gear", size: 22) {}
        // New sized init with explicit tooltip.
        _ = AinkradIconButton(systemName: "gear", size: 44, tooltip: "Settings") {}
    }
}
