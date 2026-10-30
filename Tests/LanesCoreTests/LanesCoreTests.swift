import Foundation
import AppKit
import Testing
@testable import LanesCore

private func tempPaths() throws -> LanesPaths {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("lanes-tests-\(UUID().uuidString)", isDirectory: true)
    return LanesPaths(
        supportDirectory: root.appendingPathComponent("Support with spaces"),
        launchersDirectory: root.appendingPathComponent("Applications/Lanes")
    )
}

@Suite struct ProfileTests {
    @Test(arguments: [
        ("Personal", "P"),
        ("side project", "SP"),
        ("trabajo-cliente-x", "TC"),
        ("   ", "?"),
    ])
    func initials(name: String, expected: String) {
        #expect(Profile(name: name, colorHex: "#000000").initials == expected)
    }

    @Test func launcherNameStripsPathCharacters() {
        #expect(Profile(name: "A/B: C", colorHex: "#000000").launcherName == "A-B- C (Lanes)")
    }

    @Test func uniqueNamesIgnoreCaseAndPathCharacters() {
        let existing = [Profile(name: "Personal", colorHex: "#000000"), Profile(name: "a/b", colorHex: "#000000")]
        #expect(ProfileName.unique("Work", among: existing) == "Work")
        #expect(ProfileName.unique("personal", among: existing) == "personal 2")
        #expect(ProfileName.unique("A-B", among: existing) == "A-B 2")
    }

    @Test func oldProfileFilesStillDecode() throws {
        let json = ##"{"id":"8C1D2F0A-1111-2222-3333-444455556666","name":"Old","colorHex":"#000000","createdAt":0,"customDockIcon":true,"iconStyle":"claude"}"##
        #expect(try JSONDecoder().decode(Profile.self, from: Data(json.utf8)).name == "Old")
    }

    @Test func colorRoundTrip() throws {
        let c = try #require(ProfileColor.components("#3E63DD"))
        #expect(ProfileColor.hex(red: c.red, green: c.green, blue: c.blue) == "#3E63DD")
        #expect(ProfileColor.components("nope") == nil)
    }

    @Test func nextColorSkipsUsedOnes() {
        #expect(ProfileColor.next(after: []) == ProfileColor.palette[0])
        #expect(ProfileColor.next(after: [ProfileColor.palette[0].lowercased()]) == ProfileColor.palette[1])
    }
}

@Suite struct StoreTests {
    @Test func saveAndLoad() throws {
        let store = ProfileStore(paths: try tempPaths())
        #expect(try store.load().isEmpty)
        let profiles = [Profile(name: "Personal", colorHex: "#E5484D"), Profile(name: "Cliente", colorHex: "#3E63DD")]
        try store.save(profiles)
        let loaded = try store.load()
        #expect(loaded.map(\.id) == profiles.map(\.id))
        #expect(loaded.map(\.name) == ["Personal", "Cliente"])
    }

    @Test func dataDirectoryIsStableAcrossRenames() throws {
        let paths = try tempPaths()
        var profile = Profile(name: "Personal", colorHex: "#E5484D")
        let before = paths.dataDirectory(for: profile)
        profile.name = "Casa"
        #expect(paths.dataDirectory(for: profile) == before)
    }
}

@Suite struct ProcessScannerTests {
    @Test func findsMainProcessesOnly() {
        let ps = """
          501 /Applications/Claude.app/Contents/MacOS/Claude
          502 /Applications/Claude.app/Contents/MacOS/Claude --user-data-dir=/Users/me/Library/Application Support/Lanes/Profiles/ABC
          503 /Applications/Claude.app/Contents/Frameworks/Claude Helper (Renderer).app/Contents/MacOS/Claude Helper (Renderer) --type=renderer --user-data-dir=/x
          504 /Applications/Claude.app/Contents/MacOS/Claude --user-data-dir=/tmp/a b --enable-logging
          505 /usr/bin/vim notes.txt
          506 /Applications/ClaudeHelperTool.app/Contents/MacOS/ClaudeHelperTool
          507 /Applications/Claude.app/Contents/MacOS/ClaudeX
          508 /usr/bin/python3 /Applications/Claude.app/Contents/MacOS/Claude --user-data-dir=/spoof
        """
        let found = ClaudeProcessScanner.parse(psOutput: ps, executablePath: "/Applications/Claude.app/Contents/MacOS/Claude")
        #expect(found == [
            ClaudeProcess(pid: 501, userDataDirectory: nil),
            ClaudeProcess(pid: 502, userDataDirectory: "/Users/me/Library/Application Support/Lanes/Profiles/ABC"),
            ClaudeProcess(pid: 504, userDataDirectory: "/tmp/a b"),
        ])
    }
}

@Suite struct LauncherTests {
    /// Any executable works as a stand-in for the compiled helper.
    let helper = URL(fileURLWithPath: "/usr/bin/true")

    @Test func installRenameAndUninstall() throws {
        let paths = try tempPaths()
        let launcher = LauncherBundle(paths: paths, helperExecutable: helper)
        var profile = Profile(name: "Personal", colorHex: "#E5484D")

        let app = try launcher.install(for: profile)
        let fm = FileManager.default
        #expect(app.lastPathComponent == "Personal (Lanes).app")
        #expect(fm.isExecutableFile(atPath: app.appendingPathComponent("Contents/MacOS/launcher").path))
        #expect(fm.fileExists(atPath: app.appendingPathComponent("Contents/Resources/AppIcon.icns").path))
        #expect(fm.fileExists(atPath: paths.dataDirectory(for: profile).path))

        let info = try #require(NSDictionary(contentsOf: app.appendingPathComponent("Contents/Info.plist")))
        #expect(info[LauncherBundle.dataDirectoryKey] as? String == paths.dataDirectory(for: profile).path)
        #expect(info["CFBundleIdentifier"] as? String == "io.github.xexuscode.lanes.launcher." + profile.shortID)

        profile.name = "Casa"
        let renamed = try launcher.install(for: profile)
        #expect(renamed.lastPathComponent == "Casa (Lanes).app")
        #expect(!fm.fileExists(atPath: app.path))

        try launcher.uninstall(for: profile)
        #expect(!fm.fileExists(atPath: renamed.path))
    }

    @Test func uninstallLeavesOtherProfilesAlone() throws {
        let paths = try tempPaths()
        let launcher = LauncherBundle(paths: paths, helperExecutable: helper)
        let a = Profile(name: "A", colorHex: "#E5484D")
        let b = Profile(name: "B", colorHex: "#3E63DD")
        try launcher.install(for: a)
        let appB = try launcher.install(for: b)
        try launcher.uninstall(for: a)
        #expect(FileManager.default.fileExists(atPath: appB.path))
    }
}

@Suite struct LaunchArgumentTests {
    @Test func opensTheExactAppPath() {
        let args = ClaudeLauncher.openArguments(
            app: URL(fileURLWithPath: "/Volumes/My Apps/Claude.app"),
            dataDirectory: URL(fileURLWithPath: "/tmp/data dir")
        )
        #expect(args == ["-n", "-a", "/Volumes/My Apps/Claude.app",
                         "--args", "--user-data-dir=/tmp/data dir"])
    }
}
