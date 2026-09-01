import Testing
@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@Suite struct AinkradAPITests {
    @Test func acceptsWithinRange() {
        #expect(AinkradAppKit.isCompatible(bundleAPIVersion: 6, minSupported: 6, current: 7))
        #expect(AinkradAppKit.isCompatible(bundleAPIVersion: 7, minSupported: 6, current: 7))
    }
    @Test func rejectsBelowMin() {
        #expect(!AinkradAppKit.isCompatible(bundleAPIVersion: 5, minSupported: 6, current: 7))
    }
    @Test func rejectsAboveCurrent() {
        #expect(!AinkradAppKit.isCompatible(bundleAPIVersion: 8, minSupported: 6, current: 7))
    }
}

@Suite("Generation 9")
struct Generation9Tests {
    @Test("the generation is 9 and the deprecation window is finally open")
    func generationAndWindow() {
        #expect(AinkradAppKit.apiVersion == 9)
        #expect(AinkradAppKit.minSupportedAPIVersion == 8)
        #expect(AinkradAppKit.minSupportedAPIVersion == AinkradAppKit.apiVersion - 1,
                "generation 8 was a hard break by necessity; 9 is additive, so the window opens")
    }

    @Test("a generation-8 bundle is still loadable, a generation-7 one is not")
    func compatibilityRange() {
        func loadable(_ v: Int) -> Bool {
            AinkradAppKit.isCompatible(bundleAPIVersion: v,
                                       minSupported: AinkradAppKit.minSupportedAPIVersion,
                                       current: AinkradAppKit.apiVersion)
        }
        #expect(loadable(8))
        #expect(loadable(9))
        #expect(!loadable(7))
        #expect(!loadable(10), "a bundle from the future is not loadable either")
    }
}
