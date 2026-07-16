import AppKit

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()

let background = NSBezierPath(roundedRect: NSRect(origin: .zero, size: size).insetBy(dx: 44, dy: 44), xRadius: 210, yRadius: 210)
NSColor(calibratedRed: 0.95, green: 0.93, blue: 0.88, alpha: 1).setFill()
background.fill()

let ink = NSColor(calibratedRed: 0.09, green: 0.10, blue: 0.09, alpha: 1)
let signal = NSColor(calibratedRed: 0.94, green: 0.29, blue: 0.10, alpha: 1)
let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center

let wAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont(name: "IowanOldStyle-Bold", size: 500) ?? NSFont.systemFont(ofSize: 500, weight: .black),
    .foregroundColor: ink,
    .paragraphStyle: paragraph
]
("W" as NSString).draw(in: NSRect(x: 100, y: 210, width: 730, height: 610), withAttributes: wAttributes)

let slash = NSBezierPath()
slash.move(to: NSPoint(x: 700, y: 205))
slash.line(to: NSPoint(x: 880, y: 815))
slash.lineWidth = 62
slash.lineCapStyle = .round
signal.setStroke()
slash.stroke()

image.unlockFocus()
guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not render icon")
}
try png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]), options: .atomic)
