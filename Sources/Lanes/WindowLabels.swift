import AppKit
import LanesCore
import SwiftUI

/// Pins a small label with the profile colour and name to the top of each Claude window
/// that belongs to a profile, so you can tell which account a window is.
///
/// It does not touch Claude: it reads window positions with `CGWindowListCopyWindowInfo`
/// (bounds and owner need no special permission) and keeps a click-through panel ordered
/// just above each window.
@MainActor
final class WindowLabels {
    /// Profiles of the running Claude instances, keyed by process id.
    var profilesByPID: [Int32: Profile] = [:] { didSet { schedule() } }
    var isEnabled = true { didSet { schedule() } }

    private var panels: [CGWindowID: LabelPanel] = [:]
    private var timer: Timer?

    private func schedule() {
        let active = isEnabled && !profilesByPID.isEmpty
        if active, timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor in self?.tick() }
            }
            tick()
        } else if !active {
            timer?.invalidate()
            timer = nil
            panels.values.forEach { $0.orderOut(nil) }
            panels.removeAll()
        }
    }

    private func tick() {
        let windows = Self.claudeWindows(pids: Set(profilesByPID.keys))
        var seen = Set<CGWindowID>()
        for window in windows {
            guard let profile = profilesByPID[window.pid] else { continue }
            seen.insert(window.id)
            let panel = panels[window.id] ?? LabelPanel()
            panels[window.id] = panel
            panel.show(profile: profile, above: window.id, windowFrame: window.frame)
        }
        for (id, panel) in panels where !seen.contains(id) {
            panel.orderOut(nil)
            panels[id] = nil
        }
    }

    struct WindowInfo {
        var id: CGWindowID
        var pid: Int32
        /// Cocoa coordinates (origin at the bottom left of the main screen).
        var frame: NSRect
    }

    /// Normal, on-screen windows of the given processes that are big enough to be a main window.
    static func claudeWindows(pids: Set<Int32>) -> [WindowInfo] {
        guard !pids.isEmpty,
              let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]],
              let mainHeight = NSScreen.screens.first?.frame.height else { return [] }
        return list.compactMap { info in
            guard let pid = info[kCGWindowOwnerPID as String] as? Int32, pids.contains(pid),
                  info[kCGWindowLayer as String] as? Int == 0,
                  let id = info[kCGWindowNumber as String] as? CGWindowID,
                  let boundsDict = info[kCGWindowBounds as String] as? NSDictionary,
                  let bounds = CGRect(dictionaryRepresentation: boundsDict),
                  bounds.width >= 300, bounds.height >= 200 else { return nil }
            let frame = NSRect(x: bounds.minX, y: mainHeight - bounds.maxY, width: bounds.width, height: bounds.height)
            return WindowInfo(id: id, pid: pid, frame: frame)
        }
    }
}

/// A borderless, click-through panel showing one label.
private final class LabelPanel: NSPanel {
    private static let height: CGFloat = 22
    private var shown: (name: String, color: String)?
    private let host = NSHostingView(rootView: LabelView(name: "", colorHex: "#000000"))

    init() {
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle, .transient]
        contentView = host
    }

    func show(profile: Profile, above windowID: CGWindowID, windowFrame: NSRect) {
        if shown?.name != profile.name || shown?.color != profile.colorHex {
            host.rootView = LabelView(name: profile.name, colorHex: profile.colorHex)
            shown = (profile.name, profile.colorHex)
        }
        let width = min(host.fittingSize.width, windowFrame.width - 160)
        // Centred at the top, inside the title bar area.
        let frame = NSRect(x: windowFrame.midX - width / 2, y: windowFrame.maxY - Self.height - 6,
                           width: width, height: Self.height)
        if self.frame != frame { setFrame(frame, display: true) }
        order(.above, relativeTo: Int(windowID))
    }
}

private struct LabelView: View {
    let name: String
    let colorHex: String

    var body: some View {
        let c = ProfileColor.components(colorHex) ?? (0.4, 0.4, 0.45)
        Text(name)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .frame(height: 22)
            .background(Capsule().fill(Color(.sRGB, red: c.red, green: c.green, blue: c.blue)))
    }
}
