import Testing
import AppKit
@testable import AinkradAppKit

@Suite("AinkradBlurLevel")
struct AinkradBlurLevelTests {
    @Test("levels map to distinct materials")
    func materials() {
        #expect(AinkradBlurLevel.panel.material == .hudWindow)
        #expect(AinkradBlurLevel.hud.material == .fullScreenUI)
        #expect(AinkradBlurLevel.panel.material != AinkradBlurLevel.hud.material)
    }
}
