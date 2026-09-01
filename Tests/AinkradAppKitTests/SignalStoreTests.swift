import Testing
import Foundation
@testable import AinkradSignal

@Suite("SignalStore")
struct SignalStoreTests {
    /// Real SQLite on a temp file — an in-memory fake would not exercise the
    /// schema, the indexes, or the FTS synchronization, which is where the
    /// bugs live.
    private func makeStore() throws -> (SignalStore, URL) {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("signal-\(UUID().uuidString).sqlite")
        return (try SignalStore(url: url), url)
    }

    private func event(_ title: String,
                       source: SignalSource = .host,
                       kind: String = "test.event",
                       severity: SignalSeverity = .info,
                       at seconds: TimeInterval = 1000,
                       dedupeKey: String? = nil) -> SignalEvent {
        SignalEvent(timestamp: Date(timeIntervalSince1970: seconds), source: source,
                    kind: kind, severity: severity, title: title, dedupeKey: dedupeKey)
    }

    @Test("inserts an event and reads it back whole")
    func insertAndRead() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        let e = SignalEvent(source: .app(appID: "raven"), kind: "build.failed",
                            severity: .failure, title: "Build failed", body: "3 errors",
                            proposedImportance: .urgent,
                            deepLink: SignalDeepLink(appID: "raven", payload: Data([0x07])),
                            actions: [SignalAction(id: "retry", label: "Retry")],
                            dedupeKey: "b:main")
        #expect(try store.insert(e) == .inserted)
        let page = store.page(filter: .all, before: nil, limit: 10)
        #expect(page.count == 1)
        #expect(page[0] == e)
    }

    @Test("pages newest first and honours the limit and cursor")
    func paging() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        for i in 0..<5 { _ = try store.insert(event("e\(i)", at: TimeInterval(1000 + i))) }
        let first = store.page(filter: .all, before: nil, limit: 2)
        #expect(first.map(\.title) == ["e4", "e3"])
        let next = store.page(filter: .all, before: first.last?.timestamp, limit: 2)
        #expect(next.map(\.title) == ["e2", "e1"])
    }

    @Test("filters by source and by severity")
    func filtering() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        _ = try store.insert(event("h", source: .host, severity: .info, at: 1))
        _ = try store.insert(event("r", source: .app(appID: "raven"), severity: .failure, at: 2))
        _ = try store.insert(event("q", source: .app(appID: "quest"), severity: .failure, at: 3))

        var bySource = SignalFilter.all
        bySource.sources = [.app(appID: "raven")]
        #expect(store.page(filter: bySource, before: nil, limit: 10).map(\.title) == ["r"])

        var bySeverity = SignalFilter.all
        bySeverity.severities = [.failure]
        #expect(store.page(filter: bySeverity, before: nil, limit: 10).map(\.title) == ["q", "r"])
    }

    @Test("reopening the same file keeps the events")
    func durability() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        _ = try store.insert(event("persisted"))
        _ = store   // close by scope
        let reopened = try SignalStore(url: url)
        #expect(reopened.page(filter: .all, before: nil, limit: 10).map(\.title) == ["persisted"])
    }
}
