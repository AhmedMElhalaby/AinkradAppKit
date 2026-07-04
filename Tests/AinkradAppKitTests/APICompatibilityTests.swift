import Testing
@testable import AinkradAppKit

struct APICompatibilityTests {
    @Test("current SDK reports API version 1")
    func currentVersion() {
        #expect(AinkradAppKit.apiVersion == 1)
    }

    @Test("a version inside the supported range is compatible")
    func inRange() {
        #expect(AinkradAppKit.isCompatible(bundleAPIVersion: 1, minSupported: 1, current: 1))
    }

    @Test("a version below the minimum is rejected")
    func belowMin() {
        #expect(!AinkradAppKit.isCompatible(bundleAPIVersion: 0, minSupported: 1, current: 2))
    }

    @Test("a version above the current is rejected")
    func aboveCurrent() {
        #expect(!AinkradAppKit.isCompatible(bundleAPIVersion: 3, minSupported: 1, current: 2))
    }
}
