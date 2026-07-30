import Foundation
import Testing
@testable import AinkradAppKitHome

@Suite("Home URL vending")
struct HomeURLTests {
    private func makeHome() -> Home {
        Home(vaultRoot: URL(fileURLWithPath: "/tmp/vault"),
             cacheRoot: URL(fileURLWithPath: "/tmp/cache"))
    }

    @Test func vaultAppDirectoryIsUnderApps() {
        #expect(makeHome().vault(app: AppID("Lore")).path == "/tmp/vault/Apps/Lore")
    }

    @Test func cacheAppDirectoryIsUnderApps() {
        #expect(makeHome().cache(app: AppID("Lore")).path == "/tmp/cache/Apps/Lore")
    }

    @Test func sharedDomainsResolveUnderTheVault() {
        let home = makeHome()
        #expect(home.shared(.config).path == "/tmp/vault/Config")
        #expect(home.shared(.agents).path == "/tmp/vault/Assistant/agents")
        #expect(home.shared(.sessions).path == "/tmp/vault/Assistant/sessions")
        #expect(home.shared(.media).path == "/tmp/vault/Media")
    }

    @Test func everySharedDomainHasADistinctPath() {
        let home = makeHome()
        let paths = Set(SharedDomain.allCases.map { home.shared($0).path })
        #expect(paths.count == SharedDomain.allCases.count)
    }
}

@Suite("Home resolution")
struct HomeResolutionTests {
    private func sandbox() -> (pointer: URL, cache: URL, vault: URL) {
        let base = FileManager.default.temporaryDirectory
            .appendingPathComponent("home-\(UUID().uuidString)")
        return (base.appendingPathComponent("pointer"),
                base.appendingPathComponent("cache"),
                base.appendingPathComponent("vault"))
    }

    @Test func noPointerResolvesToUnset() {
        let s = sandbox()
        defer { try? FileManager.default.removeItem(at: s.pointer.deletingLastPathComponent()) }
        guard case .unset = AinkradHome.resolve(pointerDirectory: s.pointer, cacheRoot: s.cache) else {
            Issue.record("expected .unset"); return
        }
    }

    @Test func adoptCreatesMarkerAndPointerThenResolvesReady() throws {
        let s = sandbox()
        defer { try? FileManager.default.removeItem(at: s.pointer.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: s.vault, withIntermediateDirectories: true)

        let home = try AinkradHome.adopt(s.vault, pointerDirectory: s.pointer, cacheRoot: s.cache)
        #expect(home.vaultRoot.standardizedFileURL == s.vault.standardizedFileURL)
        #expect(FileManager.default.fileExists(
            atPath: s.vault.appendingPathComponent(".ainkrad-home").path))

        guard case .ready(let resolved) = AinkradHome.resolve(pointerDirectory: s.pointer, cacheRoot: s.cache) else {
            Issue.record("expected .ready"); return
        }
        #expect(resolved.vaultRoot.standardizedFileURL == s.vault.standardizedFileURL)
    }

    @Test func adoptingAnExistingHomePreservesItsIdentity() throws {
        let s = sandbox()
        defer { try? FileManager.default.removeItem(at: s.pointer.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: s.vault, withIntermediateDirectories: true)

        _ = try AinkradHome.adopt(s.vault, pointerDirectory: s.pointer, cacheRoot: s.cache)
        let firstID = try HomeMarker.read(in: s.vault)?.homeID
        _ = try AinkradHome.adopt(s.vault, pointerDirectory: s.pointer, cacheRoot: s.cache)
        let secondID = try HomeMarker.read(in: s.vault)?.homeID

        #expect(firstID != nil)
        #expect(firstID == secondID, "re-adopting must not mint a new homeID")
    }

    @Test func vanishedVaultResolvesToMissingNotUnset() throws {
        let s = sandbox()
        defer { try? FileManager.default.removeItem(at: s.pointer.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: s.vault, withIntermediateDirectories: true)
        _ = try AinkradHome.adopt(s.vault, pointerDirectory: s.pointer, cacheRoot: s.cache)

        try FileManager.default.removeItem(at: s.vault)

        guard case .missing(let path) = AinkradHome.resolve(pointerDirectory: s.pointer, cacheRoot: s.cache) else {
            Issue.record("expected .missing — a silent fallback is the bug this guards"); return
        }
        #expect(path == s.vault.path)
    }

    @Test func folderWithoutAMarkerResolvesToForeign() throws {
        let s = sandbox()
        defer { try? FileManager.default.removeItem(at: s.pointer.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: s.vault, withIntermediateDirectories: true)
        _ = try AinkradHome.adopt(s.vault, pointerDirectory: s.pointer, cacheRoot: s.cache)

        try FileManager.default.removeItem(at: s.vault.appendingPathComponent(".ainkrad-home"))

        guard case .foreign = AinkradHome.resolve(pointerDirectory: s.pointer, cacheRoot: s.cache) else {
            Issue.record("expected .foreign"); return
        }
    }

    @Test func nestedHomeIsRejected() throws {
        let s = sandbox()
        defer { try? FileManager.default.removeItem(at: s.pointer.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: s.vault, withIntermediateDirectories: true)
        _ = try AinkradHome.adopt(s.vault, pointerDirectory: s.pointer, cacheRoot: s.cache)

        let inner = s.vault.appendingPathComponent("Inner")
        try FileManager.default.createDirectory(at: inner, withIntermediateDirectories: true)

        #expect(throws: HomeError.self) {
            _ = try AinkradHome.adopt(inner, pointerDirectory: s.pointer, cacheRoot: s.cache)
        }
    }

    @Test func failedAdoptionWritesNoPointer() throws {
        let s = sandbox()
        defer { try? FileManager.default.removeItem(at: s.pointer.deletingLastPathComponent()) }
        let missing = s.vault.appendingPathComponent("does-not-exist")

        _ = try? AinkradHome.adopt(missing, pointerDirectory: s.pointer, cacheRoot: s.cache)

        guard case .unset = AinkradHome.resolve(pointerDirectory: s.pointer, cacheRoot: s.cache) else {
            Issue.record("a failed adoption must leave no pointer"); return
        }
    }
}
