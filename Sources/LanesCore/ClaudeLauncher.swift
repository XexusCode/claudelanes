import AppKit

/// Starts, focuses and quits Claude instances.
///
/// Claude does not stop a second instance from opening the same data folder, and two
/// processes sharing one folder can corrupt it. So every launch path goes through
/// `openOrFocus`, which brings an already running instance forward instead.
public enum ClaudeLauncher {
    public enum LaunchError: LocalizedError {
        case claudeNotInstalled
        case openFailed

        public var errorDescription: String? {
            switch self {
            case .claudeNotInstalled: "Claude is not installed. Download it from claude.ai/download."
            case .openFailed: "macOS could not start Claude."
            }
        }
    }

    public static func runningProcess(for dataDirectory: URL) -> ClaudeProcess? {
        let wanted = dataDirectory.standardizedFileURL.path
        return ClaudeProcessScanner.running().first {
            guard let dir = $0.userDataDirectory else { return false }
            return URL(fileURLWithPath: dir).standardizedFileURL.path == wanted
        }
    }

    @MainActor
    public static func openOrFocus(dataDirectory: URL) async throws {
        if let running = runningProcess(for: dataDirectory), focus(pid: running.pid) {
            return
        }
        guard let app = Claude.appURL else { throw LaunchError.claudeNotInstalled }
        try FileManager.default.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = openArguments(app: app, dataDirectory: dataDirectory)
        try process.run()
        await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
            process.terminationHandler = { _ in done.resume() }
        }
        guard process.terminationStatus == 0 else { throw LaunchError.openFailed }
    }

    /// `open -n` starts a new instance of exactly that app with the profile's data folder.
    static func openArguments(app: URL, dataDirectory: URL) -> [String] {
        ["-n", "-a", app.path, "--args", Claude.userDataArgument(dataDirectory)]
    }

    @discardableResult
    public static func focus(pid: Int32) -> Bool {
        guard let app = NSRunningApplication(processIdentifier: pid) else { return false }
        if app.isHidden { app.unhide() }
        return app.activate()
    }

    /// Asks the instance to quit normally, so it saves its state.
    @discardableResult
    public static func quit(pid: Int32) -> Bool {
        NSRunningApplication(processIdentifier: pid)?.terminate() ?? false
    }
}
