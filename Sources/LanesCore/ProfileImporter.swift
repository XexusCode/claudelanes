import Foundation

/// Copies the normal Claude's data (sign-in, settings, history) into a new profile.
/// The original folder is left untouched, so the normal Claude keeps working and acts
/// as a backup.
public struct ProfileImporter: Sendable {
    public let paths: LanesPaths
    /// The normal Claude's data folder.
    public let source: URL

    public init(paths: LanesPaths = .standard, source: URL = ProfileImporter.defaultSource) {
        self.paths = paths
        self.source = source
    }

    public static var defaultSource: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Claude", isDirectory: true)
    }

    public enum ImportError: LocalizedError {
        case nothingToImport
        case claudeIsRunning
        case destinationNotEmpty

        public var errorDescription: String? {
            switch self {
            case .nothingToImport: "There is no Claude data to import on this Mac."
            case .claudeIsRunning: "Quit Claude first, so its data is not copied half-written."
            case .destinationNotEmpty: "This profile already has data."
            }
        }
    }

    public var hasSourceData: Bool {
        FileManager.default.fileExists(atPath: source.appendingPathComponent("Local State").path)
    }

    /// Chromium lock files tie a data folder to a running process; they must not be copied.
    static func shouldSkip(_ name: String) -> Bool {
        name.hasPrefix("Singleton") || name == "lockfile" || name.hasSuffix(".lock")
    }

    /// Copies the data into `profile`'s folder. On APFS each file is cloned, so even a
    /// large folder takes little extra disk space. The copy goes to a temporary folder
    /// first and is moved into place only when complete.
    ///
    /// - Parameter isClaudeRunning: checked right before copying; injectable for tests.
    public func importDefaultData(into profile: Profile,
                                  isClaudeRunning: () -> Bool = ProfileImporter.isDefaultClaudeRunning) throws {
        let fm = FileManager.default
        guard hasSourceData else { throw ImportError.nothingToImport }
        guard !isClaudeRunning() else { throw ImportError.claudeIsRunning }

        let destination = paths.dataDirectory(for: profile)
        if let contents = try? fm.contentsOfDirectory(atPath: destination.path), !contents.isEmpty {
            throw ImportError.destinationNotEmpty
        }
        let staging = destination.deletingLastPathComponent()
            .appendingPathComponent(".importing-\(profile.id.uuidString)", isDirectory: true)
        try? fm.removeItem(at: staging)
        try fm.createDirectory(at: staging, withIntermediateDirectories: true)
        do {
            for name in try fm.contentsOfDirectory(atPath: source.path) where !Self.shouldSkip(name) {
                try fm.copyItem(at: source.appendingPathComponent(name), to: staging.appendingPathComponent(name))
            }
            try? fm.removeItem(at: destination)
            try fm.moveItem(at: staging, to: destination)
        } catch {
            try? fm.removeItem(at: staging)
            throw error
        }
    }

    public static func isDefaultClaudeRunning() -> Bool {
        ClaudeProcessScanner.running().contains { $0.userDataDirectory == nil }
    }
}
