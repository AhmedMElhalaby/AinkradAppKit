import Foundation

/// Machine-local record of where the vault is. Lives outside the vault by
/// necessity — it is what tells the app where the vault is in the first place.
public struct HomePointer: Codable, Sendable {
    public static let filename = "home.json"

    public let path: String
    public let homeID: String
    public let lastSeen: Date
    public let bookmark: Data?

    public init(path: String, homeID: String, lastSeen: Date = Date(), bookmark: Data? = nil) {
        self.path = path
        self.homeID = homeID
        self.lastSeen = lastSeen
        self.bookmark = bookmark
    }

    public static func url(in directory: URL) -> URL {
        directory.appendingPathComponent(filename)
    }

    public static func read(in directory: URL) -> HomePointer? {
        let url = self.url(in: directory)
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(HomePointer.self, from: data)
    }

    public func write(to directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(self).write(to: HomePointer.url(in: directory), options: .atomic)
    }
}
