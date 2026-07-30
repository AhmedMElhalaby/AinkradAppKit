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
