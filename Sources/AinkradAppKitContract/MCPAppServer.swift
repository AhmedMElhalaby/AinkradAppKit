import Foundation

/// Opt-in capability: an app type conforming to this exposes an MCP server to
/// the host's assistant. Detected by the loader with `as?`, exactly as
/// `AinkradAppTeardown` is — a bundle compiled against an older SDK simply
/// fails the cast and is left alone. This is deliberately a SEPARATE protocol
/// rather than a new requirement on `HostServices`: added protocol
/// requirements have no witness in an already-compiled bundle and stop it
/// loading entirely.
@MainActor public protocol AinkradAppMCP {
    /// Called once per host and cached by the host. Return a server that shares
    /// the app's live state (see `PluginInstanceStorage`) so tools can drive the
    /// on-screen instance rather than a detached copy.
    static func makeMCPServer(host: HostServices) -> MCPAppServer
}

/// One tool an app publishes to the assistant.
public struct MCPToolSpec: Sendable {
    public let name: String
    public let description: String
    /// The tool's JSON Schema, as a JSON **string** — the SDK has no JSON value
    /// type, the same constraint `AgentActionProvider` documents for its params.
    public let schemaJSON: String
    /// Surfaced as MCP `destructiveHint`; the host uses it to gate irreversible ops.
    public let destructive: Bool
    /// Surfaced as MCP `readOnlyHint`.
    public let readOnly: Bool
    /// Receives the call's `arguments` object as a JSON string.
    public let handler: @MainActor @Sendable (String) async -> AgentActionResult

    public init(name: String, description: String, schemaJSON: String,
                destructive: Bool = false, readOnly: Bool = false,
                handler: @escaping @MainActor @Sendable (String) async -> AgentActionResult) {
        self.name = name
        self.description = description
        self.schemaJSON = schemaJSON
        self.destructive = destructive
        self.readOnly = readOnly
        self.handler = handler
    }
}

/// One resource an app publishes for on-demand reads.
public struct MCPResourceSpec: Sendable {
    public let uri: String
    public let title: String
    public let mimeType: String
    public let provider: @MainActor @Sendable () async -> String

    public init(uri: String, title: String, mimeType: String = "text/plain",
                provider: @escaping @MainActor @Sendable () async -> String) {
        self.uri = uri
        self.title = title
        self.mimeType = mimeType
        self.provider = provider
    }
}

/// A minimal, dependency-free MCP server an app hosts in-process. Speaks
/// JSON-RPC 2.0 as strings so it can ride any transport — the host currently
/// uses an in-process one, but nothing here assumes that.
@MainActor public final class MCPAppServer {
    public let appID: String
    private var tools: [MCPToolSpec] = []
    private var resources: [MCPResourceSpec] = []

    public init(appID: String) { self.appID = appID }

    /// Registering the same name twice keeps the first — matching the host's
    /// `AgentToolRegistry`, where the earlier registration wins.
    public func addTool(_ spec: MCPToolSpec) {
        guard !tools.contains(where: { $0.name == spec.name }) else { return }
        tools.append(spec)
    }

    public func addResource(_ spec: MCPResourceSpec) {
        guard !resources.contains(where: { $0.uri == spec.uri }) else { return }
        resources.append(spec)
    }

    /// Handles one JSON-RPC message. Returns the encoded response, or an EMPTY
    /// string for a notification (no `id`) — the transport must not surface an
    /// empty reply as a message.
    public func handle(_ message: String) async -> String {
        guard let data = message.data(using: .utf8),
              let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            return Self.encode(["jsonrpc": "2.0", "id": NSNull(),
                                "error": ["code": -32700, "message": "parse error"]])
        }
        guard let id = root["id"] else { return "" }   // notification
        let method = root["method"] as? String ?? ""
        let params = root["params"] as? [String: Any] ?? [:]

        switch method {
        case "initialize":
            return Self.result(id, [
                "protocolVersion": "2024-11-05",
                "serverInfo": ["name": appID, "version": "1.0"],
                "capabilities": ["tools": [String: Any](), "resources": [String: Any]()],
            ])

        case "tools/list":
            return Self.result(id, ["tools": tools.map { spec in
                [
                    "name": spec.name,
                    "description": spec.description,
                    "inputSchema": Self.parseSchema(spec.schemaJSON),
                    "annotations": [
                        "destructiveHint": spec.destructive,
                        "readOnlyHint": spec.readOnly,
                    ],
                ]
            }])

        case "tools/call":
            guard let name = params["name"] as? String,
                  let spec = tools.first(where: { $0.name == name }) else {
                return Self.error(id, code: -32602,
                                  message: "unknown tool '\(params["name"] as? String ?? "")'")
            }
            let arguments = params["arguments"] as? [String: Any] ?? [:]
            let argumentJSON = Self.encodeAny(arguments)
            let outcome = await spec.handler(argumentJSON)
            // A handler FAILURE is a successful RPC carrying isError:true — an
            // MCP `error` means the call could not be made at all. `MCPClient`
            // relies on this split: it throws on `error`, and surfaces
            // `isError` as a visible tool result.
            return Self.result(id, [
                "content": [["type": "text", "text": outcome.text]],
                "isError": outcome.isError,
            ])

        default:
            return Self.error(id, code: -32601, message: "unknown method '\(method)'")
        }
    }

    // MARK: - encoding helpers

    static func result(_ id: Any, _ result: [String: Any]) -> String {
        encode(["jsonrpc": "2.0", "id": id, "result": result])
    }

    static func error(_ id: Any, code: Int, message: String) -> String {
        encode(["jsonrpc": "2.0", "id": id, "error": ["code": code, "message": message]])
    }

    static func encode(_ object: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: object),
              let string = String(data: data, encoding: .utf8) else {
            return #"{"jsonrpc":"2.0","id":null,"error":{"code":-32603,"message":"encode failed"}}"#
        }
        return string
    }

    /// Parses a tool's schema string into a nested object. An unparseable schema
    /// degrades to a permissive object schema rather than breaking `tools/list`
    /// for every other tool on the server.
    static func parseSchema(_ json: String) -> [String: Any] {
        guard let data = json.data(using: .utf8),
              let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            return ["type": "object"]
        }
        return object
    }

    static func encodeAny(_ object: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: object),
              let string = String(data: data, encoding: .utf8) else { return "{}" }
        return string
    }
}
