// Draws the app icon and Top Shelf images and writes the tvOS asset catalog.
// Usage: swift scripts/make-assets.swift [HackerTube/Assets.xcassets]
import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

let catalog = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "HackerTube/Assets.xcassets")
let brand = catalog.appending(path: "App Icon & Top Shelf Image.brandassets")
let info: [String: Any] = ["author": "xcode", "version": 1]

let orange = CGColor(srgbRed: 1, green: 0.4, blue: 0, alpha: 1)
let orangeDark = CGColor(srgbRed: 0.85, green: 0.3, blue: 0, alpha: 1)
let white = CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)
let gray = CGColor(srgbRed: 0.67, green: 0.67, blue: 0.67, alpha: 1)
let black = CGColor(srgbRed: 0.06, green: 0.06, blue: 0.06, alpha: 1)

func writeJSON(_ object: [String: Any], in dir: URL) throws {
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
    try (data + Data("\n".utf8)).write(to: dir.appending(path: "Contents.json"))  // Xcode ends files with a newline
}

func render(_ width: Int, _ height: Int, to url: URL, draw: (CGContext, CGSize) -> Void) {
    let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    draw(ctx, CGSize(width: width, height: height))
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
    CGImageDestinationFinalize(dest)
}

func line(_ text: String, size: CGFloat, color: CGColor, bold: Bool = true) -> CTLine {
    let font = CTFontCreateWithName((bold ? "Helvetica-Bold" : "Helvetica") as CFString, size, nil)
    let attributes: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key(kCTFontAttributeName as String): font,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): color,
    ]
    return CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attributes))
}

func width(_ line: CTLine) -> CGFloat { CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil)) }

/// Draws a line with its visible glyphs centered on `center`.
func draw(_ line: CTLine, centeredAt center: CGPoint, in ctx: CGContext) {
    let bounds = CTLineGetImageBounds(line, ctx)
    ctx.textPosition = CGPoint(x: center.x - bounds.midX, y: center.y - bounds.midY)
    CTLineDraw(line, ctx)
}

func drawBack(_ ctx: CGContext, _ size: CGSize) {
    let gradient = CGGradient(colorsSpace: nil, colors: [orange, orangeDark] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size.height), end: .zero, options: [])
}

func drawFront(_ ctx: CGContext, _ size: CGSize) {
    draw(line("H", size: size.height * 0.62, color: white), centeredAt: CGPoint(x: size.width / 2, y: size.height / 2), in: ctx)
}

func drawTopShelf(_ ctx: CGContext, _ size: CGSize) {
    ctx.setFillColor(black)
    ctx.fill(CGRect(origin: .zero, size: size))
    let h = size.height
    let badge = h * 0.3, gap = h * 0.06
    let title = line("HackerTube", size: h * 0.15, color: white)
    let subtitle = line("The YouTube videos Hacker News keeps telling each other to watch", size: h * 0.045, color: gray, bold: false)
    let textWidth = max(width(title), width(subtitle))
    let x = (size.width - badge - gap - textWidth) / 2
    let badgeRect = CGRect(x: x, y: (h - badge) / 2, width: badge, height: badge)
    ctx.addPath(CGPath(roundedRect: badgeRect, cornerWidth: badge * 0.22, cornerHeight: badge * 0.22, transform: nil))
    ctx.setFillColor(orange)
    ctx.fillPath()
    draw(line("H", size: badge * 0.68, color: white), centeredAt: CGPoint(x: badgeRect.midX, y: badgeRect.midY), in: ctx)
    let textX = badgeRect.maxX + gap
    ctx.textPosition = CGPoint(x: textX, y: h * 0.5)
    CTLineDraw(title, ctx)
    ctx.textPosition = CGPoint(x: textX, y: h * 0.5 - h * 0.1)
    CTLineDraw(subtitle, ctx)
}

/// A layered icon: Front and Back layers, each an image set at the given scales.
func iconStack(_ name: String, width: Int, height: Int, scales: [Int]) throws {
    let stack = brand.appending(path: "\(name).imagestack")
    let layers: [(String, (CGContext, CGSize) -> Void)] = [("Front", drawFront), ("Back", drawBack)]
    try writeJSON(["info": info, "layers": layers.map { ["filename": "\($0.0).imagestacklayer"] }], in: stack)
    for (layer, drawLayer) in layers {
        let layerDir = stack.appending(path: "\(layer).imagestacklayer")
        try writeJSON(["info": info], in: layerDir)
        try imageSet(layerDir.appending(path: "Content.imageset"), name: layer.lowercased(), width: width, height: height, scales: scales, draw: drawLayer)
    }
}

func imageSet(_ dir: URL, name: String, width: Int, height: Int, scales: [Int], draw: (CGContext, CGSize) -> Void) throws {
    var images: [[String: Any]] = []
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    // Xcode lists a 1x and a 2x slot even when one is empty; match it so Xcode does not rewrite the file.
    for scale in [1, 2] {
        guard scales.contains(scale) else {
            images.append(["idiom": "tv", "scale": "\(scale)x"])
            continue
        }
        let file = scale == 1 ? "\(name).png" : "\(name)@\(scale)x.png"
        images.append(["filename": file, "idiom": "tv", "scale": "\(scale)x"])
        render(width * scale, height * scale, to: dir.appending(path: file), draw: draw)
    }
    try writeJSON(["images": images, "info": info], in: dir)
}

try? FileManager.default.removeItem(at: brand)
try writeJSON(["info": info], in: catalog)
try writeJSON([
    "colors": [["idiom": "universal", "color": ["color-space": "srgb",
        "components": ["red": "1.000", "green": "0.400", "blue": "0.000", "alpha": "1.000"]]]],
    "info": info,
], in: catalog.appending(path: "AccentColor.colorset"))
try writeJSON(["assets": [
    ["filename": "App Icon - App Store.imagestack", "idiom": "tv", "role": "primary-app-icon", "size": "1280x768"],
    ["filename": "App Icon.imagestack", "idiom": "tv", "role": "primary-app-icon", "size": "400x240"],
    ["filename": "Top Shelf Image Wide.imageset", "idiom": "tv", "role": "top-shelf-image-wide", "size": "2320x720"],
    ["filename": "Top Shelf Image.imageset", "idiom": "tv", "role": "top-shelf-image", "size": "1920x720"],
], "info": info], in: brand)
try iconStack("App Icon", width: 400, height: 240, scales: [1, 2])
try iconStack("App Icon - App Store", width: 1280, height: 768, scales: [1])
try imageSet(brand.appending(path: "Top Shelf Image.imageset"), name: "top-shelf", width: 1920, height: 720, scales: [1, 2], draw: drawTopShelf)
try imageSet(brand.appending(path: "Top Shelf Image Wide.imageset"), name: "top-shelf-wide", width: 2320, height: 720, scales: [1, 2], draw: drawTopShelf)
print("Wrote \(catalog.path)")
