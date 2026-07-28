import Testing
import Foundation
@testable import AinkradAppKitContract

@MainActor
@Suite("MCPAppServer")
struct MCPAppServerTests {
    /// Decodes a server reply into a dictionary for assertions.
    func decode(_ raw: String) throws -> [String: Any] {
        let data = try #require(raw.data(using: .utf8))
        let object = try JSONSerialization.jsonObject(with: data)
        return try #require(object as? [String: Any])
    }

    @Test("initialize returns the protocol version and server info")
    func initializeHandshake() async throws {
        let server = MCPAppServer(appID: "demo")
        let reply = await server.handle(
            #"{"jsonrpc":"2.0","id":"1","method":"initialize","params":{}}"#)
        let json = try decode(reply)
        #expect(json["id"] as? String == "1")
        let result = try #require(json["result"] as? [String: Any])
        #expect(result["protocolVersion"] as? String == "2024-11-05")
        let info = try #require(result["serverInfo"] as? [String: Any])
        #expect(info["name"] as? String == "demo")
    }

    @Test("an unknown method returns JSON-RPC error -32601")
    func unknownMethod() async throws {
        let server = MCPAppServer(appID: "demo")
        let reply = await server.handle(
            #"{"jsonrpc":"2.0","id":"7","method":"nope/nope","params":{}}"#)
        let json = try decode(reply)
        let error = try #require(json["error"] as? [String: Any])
        #expect(error["code"] as? Int == -32601)
    }

    @Test("malformed input returns parse error -32700 with a null id")
    func malformedInput() async throws {
        let server = MCPAppServer(appID: "demo")
        let json = try decode(await server.handle("{not json"))
        let error = try #require(json["error"] as? [String: Any])
        #expect(error["code"] as? Int == -32700)
        #expect(json["id"] is NSNull)
    }

    @Test("a notification (no id) produces no reply")
    func notificationProducesNoReply() async {
        let server = MCPAppServer(appID: "demo")
        let reply = await server.handle(
            #"{"jsonrpc":"2.0","method":"notifications/initialized","params":{}}"#)
        #expect(reply.isEmpty)
    }
}
