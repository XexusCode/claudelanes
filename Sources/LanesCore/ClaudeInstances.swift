import AppKit

public enum Claude {
    public static let bundleIdentifier = "com.anthropic.claudefordesktop"

    /// The flag that gives each instance its own session and settings.
    public static func userDataArgument(_ directory: URL) -> String {
        "--user-data-dir=" + directory.path
    }

    /// The installed Claude app, wherever it lives.
    public static var appURL: URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
    }

    /// The main executable inside the installed Claude app.
    public static var executablePath: String? {
        guard let app = appURL else { return nil }
        return Bundle(url: app)?.executableURL?.path
            ?? app.appendingPathComponent("Contents/MacOS/Claude").path
    }
}

/// A running Claude main process and the data folder it was started with.
public struct ClaudeProcess: Equatable, Sendable {
    public var pid: Int32
    /// `nil` for the normal Claude, which uses the default data folder.
    public var userDataDirectory: String?
}

public enum ClaudeProcessScanner {
    /// Parses `ps -o pid=,command=` output and keeps only main processes of the Claude
    /// executable at `executablePath` (not helpers, not other apps whose path merely
    /// contains "Claude").
    public static func parse(psOutput: String, executablePath: String) -> [ClaudeProcess] {
        psOutput.split(separator: "\n").compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard let space = trimmed.firstIndex(of: " "),
                  let pid = Int32(trimmed[..<space]) else { return nil }
            let command = String(trimmed[space...]).trimmingCharacters(in: .whitespaces)
            guard command == executablePath || command.hasPrefix(executablePath + " "),
                  !command.contains(" --type=") else { return nil }
            return ClaudeProcess(pid: pid, userDataDirectory: userDataDirectory(in: command))
        }
    }

    /// Extracts the `--user-data-dir=` value. Paths may contain spaces, so the value
    /// runs until the next ` --flag` or the end of the line.
    static func userDataDirectory(in command: String) -> String? {
        guard let range = command.range(of: " --user-data-dir=") else { return nil }
        var value = command[range.upperBound...]
        if let next = value.range(of: " --") { value = value[..<next.lowerBound] }
        var result = value.trimmingCharacters(in: .whitespaces)
        if result.count >= 2, result.first == "\"", result.last == "\"" {
            result = String(result.dropFirst().dropLast())
        }
        return result.isEmpty ? nil : result
    }

    /// Claude main processes of the current user.
    public static func running() -> [ClaudeProcess] {
        guard let executable = Claude.executablePath else { return [] }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-U", String(getuid()), "-ww", "-o", "pid=,command="]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do { try process.run() } catch { return [] }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return parse(psOutput: String(decoding: data, as: UTF8.self), executablePath: executable)
    }
}
