import Foundation
import Testing
@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

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

    @Test("pins to the visible top edge (letting content scroll past the bottom) when content is taller than the entire visible frame")
    func pinsToTopWhenContentExceedsScreen() {
        let short = CGRect(x: 0, y: 0, width: 1200, height: 100)
        let anchor = CGRect(x: 10, y: 40, width: 80, height: 20)
        let content = CGSize(width: 160, height: 300) // taller than the whole screen — can't fully fit either way
        let frame = floatingPanelFrame(anchorScreenRect: anchor, contentSize: content, screenVisibleFrame: short, gap: 4)

        // The top edge sits exactly at the visible frame's top (never above
        // the menu bar); the bottom overflows below the dock and scrolls.
        #expect(frame.maxY == short.maxY)
    }

    @Test("left-aligns with the anchor's minX by default")
    func leftAligned() {
        let anchor = CGRect(x: 250, y: 500, width: 80, height: 24)
        let content = CGSize(width: 160, height: 120)
        let frame = floatingPanelFrame(anchorScreenRect: anchor, contentSize: content, screenVisibleFrame: screen, gap: 4)

        #expect(frame.minX == 250)
    }
}

@Suite("floatingPanelContentWidth")
struct FloatingPanelContentWidthTests {
    @Test("floors to minWidth when content is narrower and anchor-matching is off")
    func floorsToMin() {
        #expect(floatingPanelContentWidth(natural: 80, anchorWidth: 300, matchAnchorWidth: false) == 160)
    }

    @Test("uses natural width when it exceeds both the floor and the anchor")
    func usesNatural() {
        #expect(floatingPanelContentWidth(natural: 420, anchorWidth: 300, matchAnchorWidth: true) == 420)
    }

    @Test("grows to the anchor width when matching is on and the anchor is the widest")
    func matchesAnchor() {
        #expect(floatingPanelContentWidth(natural: 180, anchorWidth: 300, matchAnchorWidth: true) == 300)
    }

    @Test("ignores the anchor width entirely when matching is off")
    func ignoresAnchorWhenOff() {
        #expect(floatingPanelContentWidth(natural: 180, anchorWidth: 900, matchAnchorWidth: false) == 180)
    }

    @Test("only ever widens — a trigger narrower than the content never shrinks the panel")
    func onlyWidens() {
        #expect(floatingPanelContentWidth(natural: 250, anchorWidth: 90, matchAnchorWidth: true) == 250)
    }

    @Test("honors a custom minWidth floor")
    func customFloor() {
        #expect(floatingPanelContentWidth(natural: 50, anchorWidth: 0, matchAnchorWidth: false, minWidth: 200) == 200)
    }
}

@Suite("isClickOutside trigger/panel hit-testing")
struct IsClickOutsideTests {
    let panel = CGRect(x: 100, y: 400, width: 160, height: 120)
    let trigger = CGRect(x: 100, y: 560, width: 80, height: 24)

    @Test("a click inside the panel is not outside")
    func insidePanel() {
        let point = CGPoint(x: 150, y: 450)
        #expect(isClickOutside(point: point, panelFrame: panel, triggerFrame: trigger) == false)
    }

    @Test("a click on the trigger is not outside — the trigger's own toggle handles it, not the outside-click dismissal")
    func insideTrigger() {
        let point = CGPoint(x: 120, y: 570)
        #expect(isClickOutside(point: point, panelFrame: panel, triggerFrame: trigger) == false)
    }

    @Test("a click outside both the panel and the trigger is outside")
    func outsideBoth() {
        let point = CGPoint(x: 900, y: 10)
        #expect(isClickOutside(point: point, panelFrame: panel, triggerFrame: trigger) == true)
    }
}
