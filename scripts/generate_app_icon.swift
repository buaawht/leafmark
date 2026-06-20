#!/usr/bin/env swift

import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconsetURL = root.appendingPathComponent("Resources/LeafMark.app/AppIcon.iconset")
let fileManager = FileManager.default

try? fileManager.removeItem(at: iconsetURL)
try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

struct IconOutput {
    let filename: String
    let pixels: Int
}

let outputs: [IconOutput] = [
    .init(filename: "icon_16x16.png", pixels: 16),
    .init(filename: "icon_16x16@2x.png", pixels: 32),
    .init(filename: "icon_32x32.png", pixels: 32),
    .init(filename: "icon_32x32@2x.png", pixels: 64),
    .init(filename: "icon_128x128.png", pixels: 128),
    .init(filename: "icon_128x128@2x.png", pixels: 256),
    .init(filename: "icon_256x256.png", pixels: 256),
    .init(filename: "icon_256x256@2x.png", pixels: 512),
    .init(filename: "icon_512x512.png", pixels: 512),
    .init(filename: "icon_512x512@2x.png", pixels: 1024),
]

for output in outputs {
    let image = drawIcon(size: output.pixels)
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let data = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "LeafMarkIcon", code: 1)
    }
    try data.write(to: iconsetURL.appendingPathComponent(output.filename))
}

func drawIcon(size: Int) -> NSImage {
    let size = CGFloat(size)
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let radius = size * 0.22
    let background = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.035, dy: size * 0.035), xRadius: radius, yRadius: radius)

    NSGradient(
        starting: NSColor(calibratedRed: 0.88, green: 0.96, blue: 0.86, alpha: 1),
        ending: NSColor(calibratedRed: 0.39, green: 0.68, blue: 0.42, alpha: 1)
    )?.draw(in: background, angle: 315)

    NSColor(calibratedWhite: 0, alpha: 0.12).setStroke()
    background.lineWidth = max(1, size * 0.012)
    background.stroke()

    drawLeaf(in: rect, size: size)
    drawMarkdownMark(in: rect, size: size)

    return image
}

func drawLeaf(in rect: NSRect, size: CGFloat) {
    let leaf = NSBezierPath()
    leaf.move(to: CGPoint(x: size * 0.28, y: size * 0.35))
    leaf.curve(
        to: CGPoint(x: size * 0.75, y: size * 0.78),
        controlPoint1: CGPoint(x: size * 0.32, y: size * 0.68),
        controlPoint2: CGPoint(x: size * 0.56, y: size * 0.83)
    )
    leaf.curve(
        to: CGPoint(x: size * 0.42, y: size * 0.20),
        controlPoint1: CGPoint(x: size * 0.80, y: size * 0.43),
        controlPoint2: CGPoint(x: size * 0.64, y: size * 0.25)
    )
    leaf.curve(
        to: CGPoint(x: size * 0.28, y: size * 0.35),
        controlPoint1: CGPoint(x: size * 0.34, y: size * 0.18),
        controlPoint2: CGPoint(x: size * 0.29, y: size * 0.27)
    )
    leaf.close()

    NSGradient(
        starting: NSColor(calibratedRed: 0.22, green: 0.56, blue: 0.30, alpha: 1),
        ending: NSColor(calibratedRed: 0.72, green: 0.90, blue: 0.48, alpha: 1)
    )?.draw(in: leaf, angle: 35)

    let vein = NSBezierPath()
    vein.move(to: CGPoint(x: size * 0.35, y: size * 0.32))
    vein.curve(
        to: CGPoint(x: size * 0.68, y: size * 0.68),
        controlPoint1: CGPoint(x: size * 0.47, y: size * 0.46),
        controlPoint2: CGPoint(x: size * 0.57, y: size * 0.58)
    )
    NSColor(calibratedRed: 0.91, green: 1.0, blue: 0.74, alpha: 0.85).setStroke()
    vein.lineWidth = max(1, size * 0.028)
    vein.lineCapStyle = .round
    vein.stroke()
}

func drawMarkdownMark(in rect: NSRect, size: CGFloat) {
    let badgeRect = NSRect(
        x: size * 0.23,
        y: size * 0.18,
        width: size * 0.54,
        height: size * 0.22
    )
    let badge = NSBezierPath(roundedRect: badgeRect, xRadius: size * 0.045, yRadius: size * 0.045)
    NSColor(calibratedRed: 0.08, green: 0.14, blue: 0.12, alpha: 0.72).setFill()
    badge.fill()

    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedSystemFont(ofSize: size * 0.13, weight: .bold),
        .foregroundColor: NSColor.white,
        .paragraphStyle: paragraph
    ]
    let text = NSAttributedString(string: "MD", attributes: attrs)
    let textRect = badgeRect.insetBy(dx: 0, dy: size * 0.035)
    text.draw(in: textRect)
}
