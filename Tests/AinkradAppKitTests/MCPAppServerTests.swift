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

    func demoServer() -> MCPAppServer {
        let server = MCPAppServer(appID: "demo")
        server.addTool(.init(
            name: "echo",
            description: "Echo the input back.",
            schemaJSON: #"{"type":"object","properties":{"text":{"type":"string"}}}"#,
            destructive: false, readOnly: true
        ) { json in
            AgentActionResult(text: "got \(json)", isError: false)
        })
        server.addTool(.init(
            name: "boom", description: "Always fails.",
            schemaJSON: #"{"type":"object"}"#, destructive: true
        ) { _ in
            AgentActionResult(text: "exploded", isError: true)
        })
        return server
    }

    @Test("tools/list reports each tool with a parsed schema and annotations")
    func toolsList() async throws {
        let reply = await demoServer().handle(
            #"{"jsonrpc":"2.0","id":"2","method":"tools/list","params":{}}"#)
        let result = try #require(try decode(reply)["result"] as? [String: Any])
        let tools = try #require(result["tools"] as? [[String: Any]])
        #expect(tools.count == 2)
        #expect(tools[0]["name"] as? String == "echo")
        // inputSchema must be a nested OBJECT, not the raw schema string.
        let schema = try #require(tools[0]["inputSchema"] as? [String: Any])
        #expect(schema["type"] as? String == "object")
        let annotations = try #require(tools[1]["annotations"] as? [String: Any])
        #expect(annotations["destructiveHint"] as? Bool == true)
    }

    @Test("tools/call invokes the handler and wraps the text as MCP content")
    func toolsCallSuccess() async throws {
        let reply = await demoServer().handle(
            #"{"jsonrpc":"2.0","id":"3","method":"tools/call","params":{"name":"echo","arguments":{"text":"hi"}}}"#)
        let result = try #require(try decode(reply)["result"] as? [String: Any])
        #expect(result["isError"] as? Bool == false)
        let content = try #require(result["content"] as? [[String: Any]])
        let text = try #require(content.first?["text"] as? String)
        #expect(text.contains("\"text\""))
        #expect(text.contains("hi"))
    }

    @Test("tools/call surfaces a handler failure as isError, not an RPC error")
    func toolsCallHandlerFailure() async throws {
        let reply = await demoServer().handle(
            #"{"jsonrpc":"2.0","id":"4","method":"tools/call","params":{"name":"boom","arguments":{}}}"#)
        let json = try decode(reply)
        #expect(json["error"] == nil)
        let result = try #require(json["result"] as? [String: Any])
        #expect(result["isError"] as? Bool == true)
    }

    @Test("tools/call on an unknown tool returns JSON-RPC error -32602")
    func toolsCallUnknownTool() async throws {
        let reply = await demoServer().handle(
            #"{"jsonrpc":"2.0","id":"5","method":"tools/call","params":{"name":"ghost","arguments":{}}}"#)
        let error = try #require(try decode(reply)["error"] as? [String: Any])
        #expect(error["code"] as? Int == -32602)
    }
}
