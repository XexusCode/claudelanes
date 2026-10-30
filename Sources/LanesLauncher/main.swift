import AppKit
import LanesCore

// Runs inside each generated "<Name> (Lanes).app": opens or focuses Claude for the
// data folder stored in this bundle's Info.plist, then exits.

// Build-time use: `lanes-launcher --write-app-icon <path.icns>` renders the Lanes icon.
if CommandLine.arguments.count == 3, CommandLine.arguments[1] == "--write-app-icon" {
    do {
        try IconRenderer.writeICNS(IconRenderer.image(initials: "L", colorHex: "#2F3A4F"), to: URL(fileURLWithPath: CommandLine.arguments[2]))
        exit(0)
    } catch {
        FileHandle.standardError.write(Data("lanes-launcher: \(error)\n".utf8))
        exit(1)
    }
}

guard let path = Bundle.main.object(forInfoDictionaryKey: LauncherBundle.dataDirectoryKey) as? String else {
    FileHandle.standardError.write(Data("lanes-launcher: missing \(LauncherBundle.dataDirectoryKey) in Info.plist\n".utf8))
    exit(1)
}

Task { @MainActor in
    do {
        try await ClaudeLauncher.openOrFocus(dataDirectory: URL(fileURLWithPath: path, isDirectory: true))
        exit(0)
    } catch {
        let alert = NSAlert()
        alert.messageText = "Could not open Claude"
        alert.informativeText = error.localizedDescription
        NSApplication.shared.activate(ignoringOtherApps: true)
        alert.runModal()
        exit(1)
    }
}

NSApplication.shared.setActivationPolicy(.accessory)
NSApplication.shared.run()
