import Testing
@testable import AinkradAppKit

struct PluginBundleMetadataTests {
    private var validDict: [String: Any] {
        [
            PluginInfoKey.appID: "hello",
            PluginInfoKey.displayName: "Hello",
            PluginInfoKey.iconSymbol: "hand.wave",
            PluginInfoKey.apiVersion: 1,
            PluginInfoKey.principalClass: "HelloPlugin.HelloEntryPoint",
        ]
    }

    @Test("parses a complete Info.plist")
    func parsesValid() {
        let result = PluginBundleMetadata.parse(infoDictionary: validDict)
        #expect(result == .success(PluginBundleMetadata(
            appID: "hello", displayName: "Hello", iconSymbol: "hand.wave",
            apiVersion: 1, principalClassName: "HelloPlugin.HelloEntryPoint")))
    }

    @Test("rejects a missing required key")
    func rejectsMissingKey() {
        var dict = validDict
        dict.removeValue(forKey: PluginInfoKey.appID)
        #expect(PluginBundleMetadata.parse(infoDictionary: dict) == .failure(.missingKey(PluginInfoKey.appID)))
    }

    @Test("rejects a non-integer API version")
    func rejectsBadAPIVersion() {
        var dict = validDict
        dict[PluginInfoKey.apiVersion] = "one"
        #expect(PluginBundleMetadata.parse(infoDictionary: dict) == .failure(.invalidAPIVersion))
    }
}
