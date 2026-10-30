import LanesCore
import SwiftUI

struct MenuContent: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Button {
            model.openDefaultClaude()
        } label: {
            Text(model.defaultClaudeRunning ? "Claude (default) — open" : "Claude (default)")
        }

        Divider()

        if model.profiles.isEmpty {
            Text("No profiles yet")
        }
        ForEach(model.profiles) { profile in
            let running = model.isRunning(profile)
            Menu {
                Button(running ? "Bring to Front" : "Open") { model.open(profile) }
                if running {
                    Button("Quit") { model.quit(profile) }
                }
                Divider()
                Button("Show Launcher in Finder") { model.revealLauncher(profile) }
            } label: {
                Label {
                    Text(running ? "\(profile.name) — open" : profile.name)
                } icon: {
                    Image(nsImage: profile.icon(size: 16))
                }
            }
        }

        Divider()

        Button("Manage Profiles…") { showProfiles() }
            .keyboardShortcut(",")
        Toggle("Label Profile Windows", isOn: $model.labelWindows)
        Toggle("Open Lanes at Login", isOn: Binding(
            get: { model.launchAtLogin },
            set: { model.setLaunchAtLogin($0) }
        ))

        Divider()

        Button("Quit Lanes") { NSApplication.shared.terminate(nil) }
            .keyboardShortcut("q")
    }

    private func showProfiles() {
        (NSApplication.shared.delegate as? AppDelegate)?.showProfiles()
    }
}
