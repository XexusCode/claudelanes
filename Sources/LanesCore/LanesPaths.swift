import Foundation

/// Where Lanes keeps its files. Injectable so tests can point it at a temp folder.
public struct LanesPaths: Sendable {
    /// `~/Library/Application Support/Lanes`
    public var supportDirectory: URL
    /// `~/Applications/Lanes` — launchers live here so Spotlight and Launchpad find them.
    public var launchersDirectory: URL

    public init(supportDirectory: URL, launchersDirectory: URL) {
        self.supportDirectory = supportDirectory
        self.launchersDirectory = launchersDirectory
    }

    public static var standard: LanesPaths {
        let fm = FileManager.default
        let support = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return LanesPaths(
            supportDirectory: support.appendingPathComponent("Lanes", isDirectory: true),
            launchersDirectory: fm.homeDirectoryForCurrentUser
                .appendingPathComponent("Applications", isDirectory: true)
                .appendingPathComponent("Lanes", isDirectory: true)
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
}
