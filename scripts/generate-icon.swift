#!/usr/bin/env swift
// Generates AppIcon.icns from the exímIA logo paths
// Usage: swift scripts/generate-icon.swift

import Cocoa

let sizes = [16, 32, 64, 128, 256, 512, 1024]

func drawLogo(size: Int) -> NSImage {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        fatalError("No graphics context")
    }

    // Background: rounded rect with #0A0A0A
    let bgColor = NSColor(red: 10/255, green: 10/255, blue: 10/255, alpha: 1)
    ctx.setFillColor(bgColor.cgColor)
    let radius = s * 0.2
    let bgPath = CGPath(roundedRect: CGRect(x: 0, y: 0, width: s, height: s),
                        cornerWidth: radius, cornerHeight: radius, transform: nil)
    ctx.addPath(bgPath)
    ctx.fillPath()

    // Scale logo to fit with padding
    let vw: CGFloat = 120.4
    let vh: CGFloat = 136.01
    let padding = s * 0.18
    let availableSize = s - (padding * 2)
    let scale = min(availableSize / vw, availableSize / vh)
    let ox = (s - vw * scale) / 2
    let oy = (s - vh * scale) / 2

    ctx.saveGState()
    // Flip Y axis (CoreGraphics is bottom-up, our paths are top-down)
    ctx.translateBy(x: 0, y: s)
    ctx.scaleBy(x: 1, y: -1)
    ctx.translateBy(x: ox, y: oy)
    ctx.scaleBy(x: scale, y: scale)

    // Right path (amber #F59E0B)
    let r = CGMutablePath()
    r.move(to: CGPoint(x: 58.88, y: 132.06))
    r.addCurve(to: CGPoint(x: 64.41, y: 135.56), control1: CGPoint(x: 58.88, y: 134.9), control2: CGPoint(x: 61.84, y: 136.78))
    r.addLine(to: CGPoint(x: 115.41, y: 111.47))
    r.addCurve(to: CGPoint(x: 120.39, y: 103.58), control1: CGPoint(x: 118.45, y: 110.03), control2: CGPoint(x: 120.4, y: 106.96))
    r.addLine(to: CGPoint(x: 120.37, y: 79.71))
    r.addLine(to: CGPoint(x: 120.37, y: 77.9))
    r.addLine(to: CGPoint(x: 120.31, y: 16.95))
    r.addCurve(to: CGPoint(x: 114.59, y: 9.14), control1: CGPoint(x: 120.31, y: 13.38), control2: CGPoint(x: 118.0, y: 10.22))
    r.addLine(to: CGPoint(x: 87.3, y: 0.46))
    r.addCurve(to: CGPoint(x: 76.61, y: 8.29), control1: CGPoint(x: 82.01, y: -1.22), control2: CGPoint(x: 76.6, y: 2.73))
    r.addLine(to: CGPoint(x: 76.65, y: 46.8))
    r.addCurve(to: CGPoint(x: 94.28, y: 71.12), control1: CGPoint(x: 76.66, y: 57.87), control2: CGPoint(x: 83.77, y: 67.68))
    r.addLine(to: CGPoint(x: 117.89, y: 78.9))
    r.addLine(to: CGPoint(x: 64.61, y: 100.28))
    r.addCurve(to: CGPoint(x: 58.86, y: 108.79), control1: CGPoint(x: 61.13, y: 101.67), control2: CGPoint(x: 58.86, y: 105.05))
    r.addLine(to: CGPoint(x: 58.88, y: 132.06))
    r.closeSubpath()

    let amberColor = NSColor(red: 245/255, green: 158/255, blue: 11/255, alpha: 1)
    ctx.setFillColor(amberColor.cgColor)
    ctx.addPath(r)
    ctx.fillPath()

    // Left path (white)
    let l = CGMutablePath()
    l.move(to: CGPoint(x: 61.33, y: 3.85))
    l.addCurve(to: CGPoint(x: 55.77, y: 0.38), control1: CGPoint(x: 61.31, y: 1.01), control2: CGPoint(x: 58.34, y: -0.85))
    l.addLine(to: CGPoint(x: 4.93, y: 24.8))
    l.addCurve(to: CGPoint(x: 0.0, y: 32.73), control1: CGPoint(x: 1.9, y: 26.27), control2: CGPoint(x: -0.02, y: 29.35))
    l.addLine(to: CGPoint(x: 0.18, y: 56.6))
    l.addLine(to: CGPoint(x: 0.18, y: 58.41))
    l.addLine(to: CGPoint(x: 0.65, y: 119.35))
    l.addCurve(to: CGPoint(x: 6.42, y: 127.12), control1: CGPoint(x: 0.68, y: 122.92), control2: CGPoint(x: 3.01, y: 126.06))
    l.addLine(to: CGPoint(x: 33.77, y: 135.63))
    l.addCurve(to: CGPoint(x: 44.41, y: 127.74), control1: CGPoint(x: 39.07, y: 137.28), control2: CGPoint(x: 44.45, y: 133.3))
    l.addLine(to: CGPoint(x: 44.12, y: 89.23))
    l.addCurve(to: CGPoint(x: 26.33, y: 65.02), control1: CGPoint(x: 44.04, y: 78.16), control2: CGPoint(x: 36.86, y: 68.4))
    l.addLine(to: CGPoint(x: 2.67, y: 57.4))
    l.addLine(to: CGPoint(x: 55.81, y: 35.67))
    l.addCurve(to: CGPoint(x: 61.5, y: 27.12), control1: CGPoint(x: 59.28, y: 34.25), control2: CGPoint(x: 61.53, y: 30.87))
    l.addLine(to: CGPoint(x: 61.33, y: 3.85))
    l.closeSubpath()

    ctx.setFillColor(NSColor.white.cgColor)
    ctx.addPath(l)
    ctx.fillPath()

    ctx.restoreGState()
    image.unlockFocus()
    return image
}

// Generate iconset
let scriptDir = URL(fileURLWithPath: #file).deletingLastPathComponent()
let projectDir = scriptDir.deletingLastPathComponent()
let resourcesDir = projectDir.appendingPathComponent("Resources")
let iconsetDir = resourcesDir.appendingPathComponent("AppIcon.iconset")

try? FileManager.default.createDirectory(at: iconsetDir, withIntermediateDirectories: true)

let iconSizes: [(name: String, size: Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

for entry in iconSizes {
    let image = drawLogo(size: entry.size)
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to generate \(entry.name)")
        continue
    }
    let filePath = iconsetDir.appendingPathComponent("\(entry.name).png")
    try pngData.write(to: filePath)
    print("Generated \(entry.name).png (\(entry.size)x\(entry.size))")
}

// Convert to icns
let icnsPath = resourcesDir.appendingPathComponent("AppIcon.icns")
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetDir.path, "-o", icnsPath.path]
try process.run()
process.waitUntilExit()

if process.terminationStatus == 0 {
    // Clean up iconset directory
    try? FileManager.default.removeItem(at: iconsetDir)
    print("Successfully generated AppIcon.icns")
} else {
    print("iconutil failed with status \(process.terminationStatus)")
}
