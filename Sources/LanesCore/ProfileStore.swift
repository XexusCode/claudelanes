import Foundation

/// Reads and writes `profiles.json`.
public struct ProfileStore: Sendable {
    public let paths: LanesPaths

    public init(paths: LanesPaths = .standard) {
        self.paths = paths
    }

    public func load() throws -> [Profile] {
        let url = paths.profilesFile
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        return try Self.decoder.decode(File.self, from: data).profiles
    }

    public func save(_ profiles: [Profile]) throws {
        try FileManager.default.createDirectory(at: paths.supportDirectory, withIntermediateDirectories: true)
        let data = try Self.encoder.encode(File(version: 1, profiles: profiles))
        try data.write(to: paths.profilesFile, options: .atomic)
    }

    private struct File: Codable {
        var version: Int
        var profiles: [Profile]
    }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
