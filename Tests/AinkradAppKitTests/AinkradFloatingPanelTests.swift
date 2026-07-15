import Foundation
import Testing
@testable import AinkradAppKit

@Suite("floatingPanelFrame positioning")
struct FloatingPanelFrameTests {
    // Screen coordinates: origin bottom-left, y grows upward (AppKit convention).
    let screen = CGRect(x: 0, y: 0, width: 1200, height: 800)

    @Test("positions below the trigger, left-aligned, when there's room")
    func belowTrigger() {
        let anchor = CGRect(x: 100, y: 600, width: 80, height: 24) // near the top of the screen
        let content = CGSize(width: 160, height: 120)
        let frame = floatingPanelFrame(anchorScreenRect: anchor, contentSize: content, screenVisibleFrame: screen, gap: 4)

        #expect(frame.minX == anchor.minX)
        #expect(frame.width == content.width)
        #expect(frame.height == content.height)
        // Below in screen-space means a smaller maxY than the anchor's minY.
        #expect(frame.maxY == anchor.minY - 4)
    }

    @Test("flips above the trigger when there's no room below")
    func flipsAboveWhenNoRoomBelow() {
        let anchor = CGRect(x: 100, y: 10, width: 80, height: 24) // near the bottom of the screen
        let content = CGSize(width: 160, height: 120)
        let frame = floatingPanelFrame(anchorScreenRect: anchor, contentSize: content, screenVisibleFrame: screen, gap: 4)

        #expect(frame.minY == anchor.maxY + 4)
    }

    @Test("clamps horizontally inside the visible frame when it would overflow the right edge")
    func clampsHorizontally() {
        let anchor = CGRect(x: 1150, y: 400, width: 80, height: 24)
        let content = CGSize(width: 200, height: 120)
        let frame = floatingPanelFrame(anchorScreenRect: anchor, contentSize: content, screenVisibleFrame: screen, gap: 4)

        #expect(frame.maxX == screen.maxX)
        #expect(frame.width == content.width)
    }

    @Test("clamps vertically inside the visible frame when neither above nor below fully fits")
    func clampsVerticallyWhenNothingFits() {
        let short = CGRect(x: 0, y: 0, width: 1200, height: 100) // short visible frame
        let anchor = CGRect(x: 10, y: 40, width: 80, height: 20) // mid-screen, no room above or below
        let content = CGSize(width: 160, height: 80) // fits the screen, just not below/above the anchor
        let frame = floatingPanelFrame(anchorScreenRect: anchor, contentSize: content, screenVisibleFrame: short, gap: 4)

        #expect(frame.minY >= short.minY)
        #expect(frame.maxY <= short.maxY + 0.0001)
    }

    @Test("pins to the top edge (rather than the bottom) when content is taller than the entire visible frame")
    func pinsToTopWhenContentExceedsScreen() {
        let short = CGRect(x: 0, y: 0, width: 1200, height: 100)
        let anchor = CGRect(x: 10, y: 40, width: 80, height: 20)
        let content = CGSize(width: 160, height: 300) // taller than the whole screen — can't fully fit either way
        let frame = floatingPanelFrame(anchorScreenRect: anchor, contentSize: content, screenVisibleFrame: short, gap: 4)

        #expect(frame.minY == short.minY)
    }

    @Test("left-aligns with the anchor's minX by default")
    func leftAligned() {
        let anchor = CGRect(x: 250, y: 500, width: 80, height: 24)
        let content = CGSize(width: 160, height: 120)
        let frame = floatingPanelFrame(anchorScreenRect: anchor, contentSize: content, screenVisibleFrame: screen, gap: 4)

        #expect(frame.minX == 250)
    }
}
