import AppKit
import SwiftUI

@main
struct LanesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra("Lanes", systemImage: "square.stack.3d.up") {
            MenuContent()
                .environmentObject(delegate.model)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()
    private var profilesWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // The menu bar icon can end up hidden behind the notch on a full menu bar,
        // so show the window whenever Lanes is opened by hand (not at login).
        if !launchedAsLoginItem(notification) {
            showProfiles()
        }
    }

    /// Opening Lanes again from Finder, Spotlight or Launchpad brings the window back.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showProfiles()
        return false
    }

    func showProfiles() {
        if profilesWindow == nil {
            let window = NSWindow(contentViewController: NSHostingController(
                rootView: ProfilesView().environmentObject(model)
            ))
            window.title = "Lanes"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false
            window.center()
            profilesWindow = window
        }
        NSApplication.shared.activate(ignoringOtherApps: true)
        profilesWindow?.makeKeyAndOrderFront(nil)
    }

    private func launchedAsLoginItem(_ notification: Notification) -> Bool {
        guard let event = NSAppleEventManager.shared().currentAppleEvent else { return false }
        return event.eventID == kAEOpenApplication
            && event.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
    }
}
