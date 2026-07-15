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
