import AppKit
import LanesCore
import ServiceManagement
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var profiles: [Profile] = []
    /// Running Claude instances keyed by profile id.
    @Published private(set) var running: [UUID: Int32] = [:]
    @Published private(set) var defaultClaudeRunning = false
    @Published var launchAtLogin = SMAppService.mainApp.status == .enabled
    @Published var errorMessage: String?
    @Published var labelWindows = UserDefaults.standard.object(forKey: "labelWindows") as? Bool ?? true {
        didSet {
            UserDefaults.standard.set(labelWindows, forKey: "labelWindows")
            windowLabels.isEnabled = labelWindows
        }
    }

    let paths: LanesPaths
    private let store: ProfileStore
    private var timer: Timer?
    private let windowLabels = WindowLabels()

    init() {
        // Profiles made before the rename live in the old "Lanes" folders. Move them once
        // nothing runs from there; until then keep using the old folders.
        var paths = LanesPaths.standard
        var migrationNote: String?
        do {
            if try paths.migrate(from: .legacy, isRunning: LanesPaths.hasRunningProfile(in:)) == .waitingForProfilesToQuit {
                paths = .legacy
                migrationNote = "Quit your open profiles and reopen ClaudeLanes to finish moving them to the new folder."
            }
        } catch {
            paths = .legacy
            migrationNote = "Could not move your profiles to the new folder: \(error.localizedDescription)"
        }
        self.paths = paths
        self.store = ProfileStore(paths: paths)
        do {
            profiles = try store.load()
        } catch {
            errorMessage = "Could not read profiles: \(error.localizedDescription)"
        }
        if let migrationNote { errorMessage = migrationNote }
        // Rebuild launchers so they always carry the helper from this version.
        for profile in profiles { _ = try? launcher?.install(for: profile) }
        windowLabels.isEnabled = labelWindows
        refreshRunning()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refreshRunning() }
        }
    }

    // MARK: Profiles

    @discardableResult
    func addProfile(name: String = "New profile") -> Profile {
        let profile = Profile(name: ProfileName.unique(name, among: profiles), colorHex: ProfileColor.next(after: profiles.map(\.colorHex)))
        profiles.append(profile)
        persist(profile)
        return profile
    }

    /// Applies the name and colour from the editor. Names stay unique so two profiles
    /// never write the same launcher.
    func update(_ profile: Profile) {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        var updated = profiles[index]
        let name = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty, name != updated.name {
            updated.name = ProfileName.unique(name, among: profiles.filter { $0.id != profile.id })
        }
        updated.colorHex = profile.colorHex
        profiles[index] = updated
        persist(updated)
    }

    /// Creates a profile from the normal Claude's data. Returns the new profile, or nil
    /// (with `errorMessage` set) if the copy failed.
    func importDefaultClaude(name: String) async -> Profile? {
        let profile = Profile(name: ProfileName.unique(name, among: profiles),
                              colorHex: ProfileColor.next(after: profiles.map(\.colorHex)))
        let importer = ProfileImporter(paths: paths)
        do {
            try await Task.detached(priority: .userInitiated) {
                try importer.importDefaultData(into: profile)
            }.value
        } catch {
            errorMessage = "Could not import: \(error.localizedDescription)"
            return nil
        }
        profiles.append(profile)
        persist(profile)
        return profile
    }

    var canImportDefaultClaude: Bool { ProfileImporter(paths: paths).hasSourceData }

    func quitDefaultClaude() {
        if let pid = ClaudeProcessScanner.running().first(where: { $0.userDataDirectory == nil })?.pid {
            ClaudeLauncher.quit(pid: pid)
        }
    }

    func delete(_ profile: Profile, deleteData: Bool) {
        if let pid = running[profile.id] { ClaudeLauncher.quit(pid: pid) }
        profiles.removeAll { $0.id == profile.id }
        perform("delete the launcher") { try launcher?.uninstall(for: profile) }
        if deleteData {
            perform("delete the profile data") {
                try FileManager.default.trashItem(at: paths.dataDirectory(for: profile), resultingItemURL: nil)
            }
        }
        perform("save profiles") { try store.save(profiles) }
    }

    func move(from source: IndexSet, to destination: Int) {
        profiles.move(fromOffsets: source, toOffset: destination)
        perform("save profiles") { try store.save(profiles) }
    }

    private func persist(_ profile: Profile) {
        perform("save profiles") { try store.save(profiles) }
        perform("create the launcher") { try launcher?.install(for: profile) }
    }

    // MARK: Instances

    func isRunning(_ profile: Profile) -> Bool { running[profile.id] != nil }

    func open(_ profile: Profile) {
        let directory = paths.dataDirectory(for: profile)
        Task {
            do {
                try await ClaudeLauncher.openOrFocus(dataDirectory: directory)
            } catch {
                errorMessage = error.localizedDescription
            }
            refreshRunning()
        }
    }

    func quit(_ profile: Profile) {
        guard let pid = running[profile.id] else { return }
        ClaudeLauncher.quit(pid: pid)
    }

    func openDefaultClaude() {
        if let pid = ClaudeProcessScanner.running().first(where: { $0.userDataDirectory == nil })?.pid,
           ClaudeLauncher.focus(pid: pid) { return }
        guard let url = Claude.appURL else {
            errorMessage = ClaudeLauncher.LaunchError.claudeNotInstalled.localizedDescription
            return
        }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }

    func revealLauncher(_ profile: Profile) {
        perform("create the launcher") {
            if let app = try launcher?.install(for: profile) {
                NSWorkspace.shared.activateFileViewerSelecting([app])
            }
        }
    }

    func refreshRunning() {
        let processes = ClaudeProcessScanner.running()
        var map: [UUID: Int32] = [:]
        for profile in profiles {
            let dir = paths.dataDirectory(for: profile).standardizedFileURL.path
            if let match = processes.first(where: {
                $0.userDataDirectory.map { URL(fileURLWithPath: $0).standardizedFileURL.path } == dir
            }) {
                map[profile.id] = match.pid
            }
        }
        if map != running { running = map }
        var labelled: [Int32: Profile] = [:]
        for profile in profiles { if let pid = map[profile.id] { labelled[pid] = profile } }
        windowLabels.profilesByPID = labelled
        let defaultRunning = processes.contains { $0.userDataDirectory == nil }
        if defaultRunning != defaultClaudeRunning { defaultClaudeRunning = defaultRunning }
    }

    // MARK: Settings

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            errorMessage = "Could not change the login item: \(error.localizedDescription)"
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    // MARK: Helpers

    /// The `lanes-launcher` helper shipped next to the Lanes executable.
    private var launcher: LauncherBundle? {
        guard let dir = Bundle.main.executableURL?.deletingLastPathComponent() else { return nil }
        let candidates = ["claudelanes-launcher", "LanesLauncher"].map { dir.appendingPathComponent($0) }
        guard let helper = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0.path) }) else {
            return nil
        }
        return LauncherBundle(paths: paths, helperExecutable: helper)
    }

    private func perform(_ what: String, _ action: () throws -> Void) {
        do { try action() } catch { errorMessage = "Could not \(what): \(error.localizedDescription)" }
    }
}

extension Profile {
    var color: Color {
        let c = ProfileColor.components(colorHex) ?? (0.4, 0.4, 0.45)
        return Color(.sRGB, red: c.red, green: c.green, blue: c.blue)
    }

    func icon(size: CGFloat) -> NSImage {
        IconRenderer.image(for: self, size: size)
    }
}
