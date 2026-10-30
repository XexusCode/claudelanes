import AppKit
import ImageIO
import UniformTypeIdentifiers

/// Draws a rounded-square icon with the profile colour and initials.
public enum IconRenderer {
    public static func image(for profile: Profile, size: CGFloat = 1024) -> NSImage {
        image(initials: profile.initials, colorHex: profile.colorHex, size: size)
    }

    public static func image(initials: String, colorHex: String, size: CGFloat = 1024) -> NSImage {
        let rgb = ProfileColor.components(colorHex) ?? (0.4, 0.4, 0.45)
        let base = NSColor(srgbRed: rgb.red, green: rgb.green, blue: rgb.blue, alpha: 1)
        return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            // macOS icon grid: 824/1024 body with ~22% corner radius.
            let inset = rect.width * 100 / 1024
            let body = rect.insetBy(dx: inset, dy: inset)
            let radius = body.width * 0.225
            let path = NSBezierPath(roundedRect: body, xRadius: radius, yRadius: radius)
            let top = base.blended(withFraction: 0.18, of: .white) ?? base
            let bottom = base.blended(withFraction: 0.12, of: .black) ?? base
            NSGradient(starting: top, ending: bottom)?.draw(in: path, angle: -90)

            let fontSize = body.height * (initials.count > 1 ? 0.42 : 0.56)
            let text = NSAttributedString(string: initials, attributes: [
                .font: NSFont.systemFont(ofSize: fontSize, weight: .semibold),
                .foregroundColor: NSColor.white,
            ])
            let textSize = text.size()
            text.draw(at: NSPoint(x: body.midX - textSize.width / 2, y: body.midY - textSize.height / 2))
            return true
        }
    }

    /// Writes a multi-resolution `.icns` without needing `iconutil`.
    public static func writeICNS(_ source: NSImage, to url: URL) throws {
        let sizes: [CGFloat] = [16, 32, 64, 128, 256, 512, 1024]
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.icns.identifier as CFString, sizes.count, nil) else {
            throw IconError.cannotCreate
        }
        for size in sizes {
            guard let cg = cgImage(source, pixels: Int(size)) else { throw IconError.cannotRender }
            CGImageDestinationAddImage(destination, cg, nil)
        }
        guard CGImageDestinationFinalize(destination) else { throw IconError.cannotCreate }
    }

    static func cgImage(_ image: NSImage, pixels: Int) -> CGImage? {
        guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                                         bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                         colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) else { return nil }
        rep.size = NSSize(width: pixels, height: pixels)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        image.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
        NSGraphicsContext.restoreGraphicsState()
        return rep.cgImage
    }

    public enum IconError: Error {
        case cannotCreate, cannotRender
    }
}
