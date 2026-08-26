#!/usr/bin/swift
// Renders a simple 1024x1024 app icon: a blue-to-indigo squircle background with the
// app's menu bar glyph (SF Symbol "photo.on.rectangle.angled") centered in white.
// Run with: swift scripts/render-icon.swift <output.png>

import AppKit

guard CommandLine.arguments.count > 1 else {
    FileHandle.standardError.write("usage: render-icon.swift <output.png>\n".data(using: .utf8)!)
    exit(1)
}
let outputPath = CommandLine.arguments[1]

let size = 1024
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: size,
    pixelsHigh: size,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    FileHandle.standardError.write("failed to create bitmap\n".data(using: .utf8)!)
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

let rect = NSRect(x: 0, y: 0, width: size, height: size)

// Big Sur-style squircle background (approximated with a large corner radius).
let cornerRadius = CGFloat(size) * 0.224
let backgroundPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.20, green: 0.47, blue: 0.98, alpha: 1.0),
    NSColor(calibratedRed: 0.42, green: 0.27, blue: 0.86, alpha: 1.0),
])
gradient?.draw(in: backgroundPath, angle: -60)

// Centered glyph, matching the menu bar icon (AppDelegate.swift).
let symbolPointSize: CGFloat = CGFloat(size) * 0.52
// .withSymbolConfiguration resets to the config passed in rather than merging, so the
// size and color configs must be combined with `applying` before being applied together —
// applying them in two separate calls silently drops the size back to the ~20pt default.
let sizeConfig = NSImage.SymbolConfiguration(pointSize: symbolPointSize, weight: .medium)
let colorConfig = NSImage.SymbolConfiguration(paletteColors: [.white])
let combinedConfig = sizeConfig.applying(colorConfig)
if let symbol = NSImage(systemSymbolName: "photo.on.rectangle.angled", accessibilityDescription: nil)?
    .withSymbolConfiguration(combinedConfig) {
    let symbolSize = symbol.size
    let origin = NSPoint(x: (CGFloat(size) - symbolSize.width) / 2, y: (CGFloat(size) - symbolSize.height) / 2)
    symbol.draw(at: origin, from: .zero, operation: .sourceOver, fraction: 1.0)
} else {
    FileHandle.standardError.write("warning: could not load SF Symbol, background only\n".data(using: .utf8)!)
}

NSGraphicsContext.restoreGraphicsState()

guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write("failed to encode PNG\n".data(using: .utf8)!)
    exit(1)
}

do {
    try pngData.write(to: URL(fileURLWithPath: outputPath))
    print("Wrote \(outputPath)")
} catch {
    FileHandle.standardError.write("failed to write \(outputPath): \(error)\n".data(using: .utf8)!)
    exit(1)
}
