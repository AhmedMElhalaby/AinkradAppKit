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
