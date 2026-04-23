// Build-time tool: renders the app icon as a 1024×1024 PNG.
// Invoked by build.sh; not part of the shipping app.
//
// Usage: generate_icon <output.png>

import Cocoa
import Foundation

guard CommandLine.arguments.count >= 2 else {
    fputs("Usage: generate_icon <output.png>\n", stderr)
    exit(1)
}

let outputPath = CommandLine.arguments[1]
let size: CGFloat = 1024

let canvas = NSImage(size: NSSize(width: size, height: size))
canvas.lockFocus()

// Rounded-square background with vertical gradient (macOS icon corner radius ≈ 22.37%)
let rect = NSRect(x: 0, y: 0, width: size, height: size)
let cornerRadius = size * 0.2237
let bgPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
bgPath.addClip()

let gradient = NSGradient(colors: [
    NSColor(red: 0.42, green: 0.50, blue: 0.98, alpha: 1.0),  // indigo
    NSColor(red: 0.68, green: 0.35, blue: 0.93, alpha: 1.0),  // violet
])!
gradient.draw(in: rect, angle: -90)

// Centered headphones symbol, white
guard let symbol = NSImage(systemSymbolName: "headphones", accessibilityDescription: nil) else {
    fputs("Missing SF Symbol 'headphones'\n", stderr)
    exit(1)
}
let sizeConfig = NSImage.SymbolConfiguration(pointSize: size * 0.55, weight: .medium)
let colorConfig = NSImage.SymbolConfiguration(paletteColors: [.white])
let config = sizeConfig.applying(colorConfig)

guard let tinted = symbol.withSymbolConfiguration(config) else {
    fputs("Failed to apply symbol configuration\n", stderr)
    exit(1)
}

let imgSize = tinted.size
let x = (size - imgSize.width) / 2
let y = (size - imgSize.height) / 2
tinted.draw(at: NSPoint(x: x, y: y), from: .zero, operation: .sourceOver, fraction: 1.0)

canvas.unlockFocus()

guard let tiff = canvas.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fputs("Failed to encode PNG\n", stderr)
    exit(1)
}

try png.write(to: URL(fileURLWithPath: outputPath))
print("Wrote \(outputPath) (\(png.count) bytes)")
