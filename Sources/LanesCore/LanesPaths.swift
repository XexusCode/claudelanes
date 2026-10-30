import Foundation

/// Where ClaudeLanes keeps its files. Injectable so tests can point it at a temp folder.
public struct LanesPaths: Sendable {
    /// `~/Library/Application Support/ClaudeLanes`
    public var supportDirectory: URL
    /// `~/Applications/ClaudeLanes` — launchers live here so Spotlight and Launchpad find them.
    public var launchersDirectory: URL

    public init(supportDirectory: URL, launchersDirectory: URL) {
        self.supportDirectory = supportDirectory
        self.launchersDirectory = launchersDirectory
    }

    public static var standard: LanesPaths { named("ClaudeLanes") }

    /// Folders used before the app was renamed from "Lanes".
    public static var legacy: LanesPaths { named("Lanes") }

    private static func named(_ name: String) -> LanesPaths {
        let fm = FileManager.default
        let support = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return LanesPaths(
            supportDirectory: support.appendingPathComponent(name, isDirectory: true),
            launchersDirectory: fm.homeDirectoryForCurrentUser
                .appendingPathComponent("Applications", isDirectory: true)
                .appendingPathComponent(name, isDirectory: true)
        )
    }

    public var profilesFile: URL {
        supportDirectory.appendingPathComponent("profiles.json")
    }

    /// The `--user-data-dir` for a profile. Keyed by id so renaming never loses the session.
    public func dataDirectory(for profile: Profile) -> URL {
        supportDirectory
            .appendingPathComponent("Profiles", isDirectory: true)
            .appendingPathComponent(profile.id.uuidString, isDirectory: true)
    }

    public func launcherURL(for profile: Profile) -> URL {
        launchersDirectory.appendingPathComponent(profile.launcherName + ".app", isDirectory: true)
    }

    public enum MigrationResult: Equatable, Sendable {
        case nothingToDo, migrated, waitingForProfilesToQuit
    }

    /// Moves profiles from `legacy` to these folders, keeping every session. Old launchers
    /// are deleted (they are regenerated). Skipped while a profile from the old folder is
    /// running, because Claude would keep writing to the old path.
    public func migrate(from legacy: LanesPaths, isRunning: (String) -> Bool) throws -> MigrationResult {
        let fm = FileManager.default
        guard fm.fileExists(atPath: legacy.supportDirectory.path),
              !fm.fileExists(atPath: supportDirectory.path) else { return .nothingToDo }
        guard !isRunning(legacy.supportDirectory.standardizedFileURL.path) else { return .waitingForProfilesToQuit }
        try fm.createDirectory(at: supportDirectory.deletingLastPathComponent(), withIntermediateDirectories: true)
        try fm.moveItem(at: legacy.supportDirectory, to: supportDirectory)
        if fm.fileExists(atPath: legacy.launchersDirectory.path) {
            try fm.removeItem(at: legacy.launchersDirectory)
        }
        return .migrated
    }

    /// Whether any Claude instance runs with a data folder inside `folder`.
    public static func hasRunningProfile(in folder: String) -> Bool {
        ClaudeProcessScanner.running().contains {
            guard let dir = $0.userDataDirectory else { return false }
            return URL(fileURLWithPath: dir).standardizedFileURL.path.hasPrefix(folder + "/")
        }
    }
}
