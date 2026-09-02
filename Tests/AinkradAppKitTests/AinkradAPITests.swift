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

@Suite("Generation 10")
struct Generation10Tests {
    @Test("the generation is 10 and the window is still exactly one release")
    func generationAndWindow() {
        #expect(AinkradAppKit.apiVersion == 10)
        #expect(AinkradAppKit.minSupportedAPIVersion == 9)
        #expect(AinkradAppKit.minSupportedAPIVersion == AinkradAppKit.apiVersion - 1,
                "one release of support, advertised and honoured")
    }

    @Test("the window MOVED: generation 9 loads, generation 8 no longer does")
    func compatibilityRange() {
        func loadable(_ v: Int) -> Bool {
            AinkradAppKit.isCompatible(bundleAPIVersion: v,
                                       minSupported: AinkradAppKit.minSupportedAPIVersion,
                                       current: AinkradAppKit.apiVersion)
        }
        #expect(loadable(9))
        #expect(loadable(10))
        // THE CONSEQUENCE, asserted rather than discovered by a user. A
        // one-release window means each bump evicts the oldest generation, and
        // this bump evicts 8. Any installed bundle still declaring
        // AinkradAPIVersion 8 stops loading and must be rebuilt against 9 or
        // 10 — for this family that means Quest, which has not adopted Signal
        // and is still at generation 8.
        #expect(!loadable(8), "generation 8 is now outside the window and must be rebuilt")
        #expect(!loadable(7))
        #expect(!loadable(11), "a bundle from the future is not loadable either")
    }
}
