import Testing
import CoreGraphics
import SwiftUI
@testable import AinkradAppKit

@Suite("AinkradSpacing")
struct AinkradSpacingTests {
    @Test("spacing ramp uses the documented 4-pt base scale")
    func ramp() {
        #expect(AinkradSpacing.xs == 4)
        #expect(AinkradSpacing.sm == 8)
        #expect(AinkradSpacing.md == 12)
        #expect(AinkradSpacing.lg == 16)
        #expect(AinkradSpacing.xl == 24)
        #expect(AinkradSpacing.xxl == 32)
    }

    @Test("ramp is strictly increasing")
    func monotonic() {
        let steps = [AinkradSpacing.xs, AinkradSpacing.sm, AinkradSpacing.md, AinkradSpacing.lg, AinkradSpacing.xl, AinkradSpacing.xxl]
        #expect(zip(steps, steps.dropFirst()).allSatisfy { $0 < $1 })
    }
}

@Suite("AinkradRadius")
struct AinkradRadiusTests {
    @Test("radius steps; panel stays 14 to preserve current chrome")
    func steps() {
        #expect(AinkradRadius.sm == 8)
        #expect(AinkradRadius.md == 12)
        #expect(AinkradRadius.lg == 14)
        #expect(AinkradRadius.panel == 14)
    }
}

@Suite("AinkradElevation")
struct AinkradElevationTests {
    @Test("level0 is a no-op shadow")
    func flat() {
        #expect(AinkradElevation.level0 == ShadowSpec(color: .clear, radius: 0, x: 0, y: 0))
    }

    @Test("elevation deepens with level")
    func deepens() {
        #expect(AinkradElevation.level1.radius < AinkradElevation.level2.radius)
        #expect(AinkradElevation.level1.y < AinkradElevation.level2.y)
    }
}
