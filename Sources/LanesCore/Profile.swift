import Foundation

/// A Claude account that runs in its own, isolated data folder.
public struct Profile: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    /// Colour as `#RRGGBB`, used for the launcher icon, the menu and the window label.
    public var colorHex: String
    public var createdAt: Date

    public init(id: UUID = UUID(), name: String, colorHex: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.createdAt = createdAt
    }

    /// Up to two letters shown on the launcher icon ("Personal" → "P", "Side Project" → "SP").
    public var initials: String {
        let words = name.split(whereSeparator: { $0.isWhitespace || $0 == "-" || $0 == "_" })
        let letters = words.prefix(2).compactMap { $0.first }
        let result = String(letters).uppercased()
        return result.isEmpty ? "?" : result
    }

    /// Short, stable identifier used for bundle ids.
    public var shortID: String {
        String(id.uuidString.replacingOccurrences(of: "-", with: "").prefix(12)).lowercased()
    }

    /// Display name of the launcher app, e.g. "Personal (ClaudeLanes)". The suffix makes
    /// clear it is a ClaudeLanes launcher, not Anthropic's own app.
    public var launcherName: String {
        Self.launcherName(for: name, fallback: shortID)
    }

    static func launcherName(for name: String, fallback: String) -> String {
        let safe = name
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (safe.isEmpty ? fallback : safe) + " (ClaudeLanes)"
    }
}

public enum ProfileName {
    /// Returns `name`, or `name 2`, `name 3`… so that no two profiles end up with the same
    /// launcher file. Comparison is case-insensitive, like the default APFS volume.
    public static func unique(_ name: String, among others: [Profile]) -> String {
        func key(_ candidate: String) -> String {
            Profile.launcherName(for: candidate, fallback: "").lowercased()
        }
        let taken = Set(others.map { $0.launcherName.lowercased() })
        guard taken.contains(key(name)) else { return name }
        var n = 2
        while taken.contains(key("\(name) \(n)")) { n += 1 }
        return "\(name) \(n)"
    }
}

public enum ProfileColor {
    /// Preset palette offered in the editor; the first unused one is picked for new profiles.
    public static let palette = ["#E5484D", "#3E63DD", "#30A46C", "#F76B15", "#8E4EC6", "#12A594", "#D6409F", "#6F6E77"]

    public static func next(after used: [String]) -> String {
        let taken = Set(used.map { $0.uppercased() })
        return palette.first { !taken.contains($0) } ?? palette[used.count % palette.count]
    }

    /// Parses `#RRGGBB` (with or without `#`) into 0…1 components.
    public static func components(_ hex: String) -> (red: Double, green: Double, blue: Double)? {
        var s = hex.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let value = UInt32(s, radix: 16) else { return nil }
        return (Double((value >> 16) & 0xFF) / 255, Double((value >> 8) & 0xFF) / 255, Double(value & 0xFF) / 255)
    }

    public static func hex(red: Double, green: Double, blue: Double) -> String {
        func byte(_ v: Double) -> Int { Int((min(max(v, 0), 1) * 255).rounded()) }
        return String(format: "#%02X%02X%02X", byte(red), byte(green), byte(blue))
    }
}
