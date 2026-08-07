import Foundation

/// A stable, dotted identity for a node in the settings catalog —
/// `assistant.access.permissions.autoApproveReads`.
///
/// Paths are the lingua franca of search results, deep-links, error toasts,
/// and assistant-driven navigation. They are **never** derived from display
/// text: renaming a label must not break a link. Retired paths live on as
/// redirect aliases rather than being deleted.
public struct SettingsPath: Hashable, Codable, Sendable, CustomStringConvertible {
    public let segments: [String]

    public init(_ segments: [String]) {
        self.segments = segments
    }

    public init?(rawValue: String) {
        let parts = rawValue.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        guard !parts.isEmpty, !parts.contains(where: \.isEmpty) else { return nil }
        self.segments = parts
    }

    public var rawValue: String { segments.joined(separator: ".") }
    public var description: String { rawValue }

    public func appending(_ segment: String) -> SettingsPath {
        SettingsPath(segments + [segment])
    }

    /// The enclosing node, or `nil` for a top-level page.
    public var parent: SettingsPath? {
        segments.count > 1 ? SettingsPath(Array(segments.dropLast())) : nil
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        guard let parsed = SettingsPath(rawValue: raw) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Malformed SettingsPath: \(raw)")
        }
        self = parsed
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
