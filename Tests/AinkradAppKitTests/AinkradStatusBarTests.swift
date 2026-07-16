import Foundation
import Testing
@testable import AinkradAppKit

@Suite("filledSegments")
struct FilledSegmentsTests {
    @Test("half value fills half the segments")
    func half() {
        #expect(filledSegments(value: 5, total: 10, segments: 10) == 5)
    }

    @Test("zero value fills nothing")
    func zero() {
        #expect(filledSegments(value: 0, total: 10, segments: 10) == 0)
    }

    @Test("full value fills every segment")
    func full() {
        #expect(filledSegments(value: 10, total: 10, segments: 10) == 10)
    }

    @Test("value beyond total clamps to full")
    func overshoot() {
        #expect(filledSegments(value: 20, total: 10, segments: 10) == 10)
    }

    @Test("negative value clamps to zero")
    func negative() {
        #expect(filledSegments(value: -3, total: 10, segments: 10) == 0)
    }

    @Test("a zero/negative total yields zero filled segments")
    func zeroTotal() {
        #expect(filledSegments(value: 5, total: 0, segments: 10) == 0)
        #expect(filledSegments(value: 5, total: -1, segments: 10) == 0)
    }

    @Test("fractional ratio rounds to the nearest segment")
    func rounds() {
        #expect(filledSegments(value: 1, total: 3, segments: 3) == 1)
        #expect(filledSegments(value: 2, total: 3, segments: 12) == 8)
    }
}

@Suite("spinnerRotationAngle")
struct SpinnerRotationAngleTests {
    @Test("reduce motion pins the ring static at 0, even mid-spin")
    func reduceMotionIsStatic() {
        #expect(spinnerRotationAngle(reduceMotion: true, isSpinning: false) == 0)
        #expect(spinnerRotationAngle(reduceMotion: true, isSpinning: true) == 0)
    }

    @Test("not spinning yet targets 0")
    func notYetSpinning() {
        #expect(spinnerRotationAngle(reduceMotion: false, isSpinning: false) == 0)
    }

    @Test("spinning targets a full turn, which the looping .animation(...) drives continuously")
    func spinningTargetsFullTurn() {
        #expect(spinnerRotationAngle(reduceMotion: false, isSpinning: true) == 360)
    }
}

@Suite("spinnerTimelineAngle")
struct SpinnerTimelineAngleTests {
    @Test("start of a period is angle 0")
    func start() {
        let date = Date(timeIntervalSinceReferenceDate: 10)
        #expect(spinnerTimelineAngle(date: date, period: 1) == 0)
    }

    @Test("halfway through the period is 180 degrees")
    func halfway() {
        let date = Date(timeIntervalSinceReferenceDate: 10.5)
        #expect(spinnerTimelineAngle(date: date, period: 1) == 180)
    }

    @Test("wraps around at the period boundary")
    func wraps() {
        let date = Date(timeIntervalSinceReferenceDate: 2.75)
        #expect(spinnerTimelineAngle(date: date, period: 1) == 270)
    }

    @Test("a non-positive period yields 0 rather than dividing by zero")
    func nonPositivePeriod() {
        let date = Date(timeIntervalSinceReferenceDate: 5)
        #expect(spinnerTimelineAngle(date: date, period: 0) == 0)
        #expect(spinnerTimelineAngle(date: date, period: -1) == 0)
    }
}
