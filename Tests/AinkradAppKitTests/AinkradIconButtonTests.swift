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
