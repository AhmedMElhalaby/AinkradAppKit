import Testing
import Foundation
@testable import AinkradSignal

@Suite("Signal routing")
struct SignalRoutingTests {
    private func event(_ severity: SignalSeverity,
                       source: SignalSource = .host,
                       kind: String = "test.event",
                       importance: SignalImportance = .normal) -> SignalEvent {
        SignalEvent(source: source, kind: kind, severity: severity,
                    title: "t", proposedImportance: importance)
    }

    private let frontmost = DeliveryContext(hostIsFrontmost: true, visibleAppIDs: ["raven"],
                                            systemDoNotDisturb: false, hostFocusMode: false)
    private let away = DeliveryContext(hostIsFrontmost: false, visibleAppIDs: [],
                                       systemDoNotDisturb: false, hostFocusMode: false)

    @Test("the feed always receives the event, whatever the rules say")
    func feedIsUnconditional() {
        var rules = RoutingRules.default
        rules.mutedSources.insert(.host)
        let channels = route(event(.failure), rules: rules, context: away)
        #expect(channels.contains(.feed))
    }

    @Test("a muted source still logs but never interrupts")
    func mutedSourceCannotInterrupt() {
        var rules = RoutingRules.default
        rules.mutedSources.insert(.app(appID: "raven"))
        let channels = route(event(.failure, source: .app(appID: "raven"), importance: .urgent),
                             rules: rules, context: away)
        #expect(channels == [.feed])
    }

    @Test("looking away promotes a toast to a banner")
    func awayPromotesToBanner() {
        let here = route(event(.success), rules: .default, context: frontmost)
        let gone = route(event(.success), rules: .default, context: away)
        #expect(here.contains(.toast))
        #expect(!here.contains(.banner))
        #expect(gone.contains(.banner))
        #expect(!gone.contains(.toast))
    }

    @Test("do not disturb strips banner and sound but never feed or badge")
    func doNotDisturb() {
        let dnd = DeliveryContext(hostIsFrontmost: false, visibleAppIDs: [],
                                  systemDoNotDisturb: true, hostFocusMode: false)
        let channels = route(event(.failure), rules: .default, context: dnd)
        #expect(!channels.contains(.banner))
        #expect(!channels.contains(.sound))
        #expect(channels.contains(.feed))
        #expect(channels.contains(.badge))
    }

    @Test("failures make a sound when the user is present")
    func failureSounds() {
        #expect(route(event(.failure), rules: .default, context: frontmost).contains(.sound))
        #expect(!route(event(.info), rules: .default, context: frontmost).contains(.sound))
    }

    @Test("most specific rule wins: source+kind beats source beats severity")
    func specificityOrder() {
        var rules = RoutingRules.default
        rules.sourceOverrides[.host] = [.feed, .banner]
        rules.sourceKindOverrides[SourceKind(source: .host, kind: "quiet.thing")] = [.feed]
        #expect(route(event(.info), rules: rules, context: frontmost) == [.feed, .banner])
        #expect(route(event(.info, kind: "quiet.thing"), rules: rules, context: frontmost) == [.feed])
    }

    @Test("host run events route like any other event now that RunNotifier is gone")
    func runEventsAreOrdinary() {
        // The M1 exemption lived here: `run.*` from `.host` never reached
        // `.banner`, because the legacy notifier posted it. With that notifier
        // deleted, a run must route exactly like anything else — if it did not,
        // a finished run would produce no banner at all.
        let run = route(event(.success, kind: "run.finished"), rules: .default, context: away)
        let other = route(event(.success, kind: "install.completed"), rules: .default, context: away)
        #expect(run == other)
        #expect(run.contains(.banner))
    }
}
