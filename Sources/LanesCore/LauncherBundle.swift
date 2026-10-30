import Foundation

/// Builds a tiny `.app` per profile that opens (or focuses) Claude with that profile's
/// data folder. It works on its own (Spotlight, Launchpad, Dock) even when Lanes is not
/// running: it carries a copy of the `lanes-launcher` helper and reads the folder from
/// its own Info.plist.
public struct LauncherBundle: Sendable {
    public let paths: LanesPaths
    /// The compiled `lanes-launcher` helper that gets copied into each launcher.
    public let helperExecutable: URL

    public init(paths: LanesPaths = .standard, helperExecutable: URL) {
        self.paths = paths
        self.helperExecutable = helperExecutable
    }

    public static let dataDirectoryKey = "LanesDataDirectory"
    static let profileKey = "LanesProfileID"

    @discardableResult
    public func install(for profile: Profile) throws -> URL {
        let fm = FileManager.default
        try removeStale(for: profile)
        let app = paths.launcherURL(for: profile)
        let contents = app.appendingPathComponent("Contents", isDirectory: true)
        let macOS = contents.appendingPathComponent("MacOS", isDirectory: true)
        let resources = contents.appendingPathComponent("Resources", isDirectory: true)
        try? fm.removeItem(at: app)
        try fm.createDirectory(at: macOS, withIntermediateDirectories: true)
        try fm.createDirectory(at: resources, withIntermediateDirectories: true)

        let dataDirectory = paths.dataDirectory(for: profile)
        try fm.createDirectory(at: dataDirectory, withIntermediateDirectories: true)

        let executable = macOS.appendingPathComponent("launcher")
        try fm.copyItem(at: helperExecutable, to: executable)
        try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)

        let plist = Self.infoPlist(for: profile, dataDirectory: dataDirectory)
        let plistData = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try plistData.write(to: contents.appendingPathComponent("Info.plist"))

        try IconRenderer.writeICNS(IconRenderer.image(for: profile), to: resources.appendingPathComponent("AppIcon.icns"))

        Self.adHocSign(app)
        // Bump the modification date so Finder and the Dock pick up a new icon.
        try fm.setAttributes([.modificationDate: Date()], ofItemAtPath: app.path)
        return app
    }

    /// Removes every launcher that belongs to this profile except the current one (e.g. after a rename).
    public func removeStale(for profile: Profile) throws {
        try remove(for: profile, keeping: paths.launcherURL(for: profile))
    }

    public func uninstall(for profile: Profile) throws {
        try remove(for: profile, keeping: nil)
    }

    private func remove(for profile: Profile, keeping: URL?) throws {
        let fm = FileManager.default
        guard let items = try? fm.contentsOfDirectory(at: paths.launchersDirectory, includingPropertiesForKeys: nil) else { return }
        for item in items where item.pathExtension == "app" && item.standardizedFileURL != keeping?.standardizedFileURL {
            let plist = item.appendingPathComponent("Contents/Info.plist")
            guard let data = try? Data(contentsOf: plist),
                  let info = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
                  info[Self.profileKey] as? String == profile.id.uuidString else { continue }
            try fm.removeItem(at: item)
        }
    }

    static func infoPlist(for profile: Profile, dataDirectory: URL) -> [String: Any] {
        [
            "CFBundleExecutable": "launcher",
            "CFBundleIdentifier": "io.github.xexuscode.lanes.launcher." + profile.shortID,
            "CFBundleName": profile.launcherName,
            "CFBundleDisplayName": profile.launcherName,
            "CFBundleIconFile": "AppIcon",
            "CFBundlePackageType": "APPL",
            "CFBundleShortVersionString": "1.0",
            "CFBundleVersion": "1",
            "LSMinimumSystemVersion": "14.0",
            "LSUIElement": true,
            profileKey: profile.id.uuidString,
            dataDirectoryKey: dataDirectory.path,
        ]
    }

    /// Seals the bundle so Gatekeeper treats it as one unit. Failure is not fatal:
    /// locally created apps without quarantine run unsigned too.
    static func adHocSign(_ app: URL) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        process.arguments = ["--force", "--sign", "-", app.path]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()
    }
}
