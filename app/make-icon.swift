import AppKit
// Draws the Aerial Swap icon at the given pixel size and writes a PNG.
// usage: make-icon <size> <out.png>
let size = CGFloat(Int(CommandLine.arguments[1])!)
let out = URL(fileURLWithPath: CommandLine.arguments[2])
let img = NSImage(size: NSSize(width: size, height: size))
img.lockFocus()
let ctx = NSGraphicsContext.current!.cgContext
let r = CGRect(x: 0, y: 0, width: size, height: size)
// macOS-style rounded square, inset like system icons
let inset = size * 0.08
let squircle = NSBezierPath(roundedRect: r.insetBy(dx: inset, dy: inset), xRadius: size * 0.2, yRadius: size * 0.2)
squircle.addClip()
// dusk sky gradient
let sky = NSGradient(colors: [NSColor(red: 0.07, green: 0.09, blue: 0.25, alpha: 1),
                              NSColor(red: 0.45, green: 0.20, blue: 0.55, alpha: 1),
                              NSColor(red: 0.98, green: 0.55, blue: 0.35, alpha: 1)])!
sky.draw(in: r, angle: 90)
// sun
let sunR = size * 0.11
let sun = NSBezierPath(ovalIn: CGRect(x: size * 0.62 - sunR, y: size * 0.50 - sunR, width: sunR * 2, height: sunR * 2))
NSColor(red: 1, green: 0.90, blue: 0.70, alpha: 0.95).setFill(); sun.fill()
// distant hills
func hill(_ pts: [(CGFloat, CGFloat)], _ color: NSColor) {
    let p = NSBezierPath(); p.move(to: CGPoint(x: 0, y: 0))
    for (x, y) in pts { p.line(to: CGPoint(x: x * size, y: y * size)) }
    p.line(to: CGPoint(x: size, y: 0)); p.close(); color.setFill(); p.fill()
}
hill([(0, 0.30), (0.18, 0.44), (0.34, 0.36), (0.52, 0.50), (0.70, 0.40), (0.86, 0.47), (1, 0.38)], NSColor(red: 0.25, green: 0.14, blue: 0.40, alpha: 1))
hill([(0, 0.20), (0.15, 0.30), (0.30, 0.24), (0.48, 0.34), (0.66, 0.26), (0.84, 0.33), (1, 0.24)], NSColor(red: 0.12, green: 0.08, blue: 0.24, alpha: 1))
// swap arrows around a play glyph, bottom-left heavy so it reads as a badge
let cx = size * 0.5, cy = size * 0.47, rad = size * 0.20
NSColor.white.withAlphaComponent(0.92).setStroke()
ctx.setLineCap(.round)
for (start, end) in [(CGFloat(20), CGFloat(160)), (CGFloat(200), CGFloat(340))] {
    let arc = NSBezierPath(); arc.lineWidth = size * 0.045
    arc.appendArc(withCenter: CGPoint(x: cx, y: cy), radius: rad, startAngle: start, endAngle: end)
    arc.stroke()
    // arrow head at the end angle
    let a = end * .pi / 180
    let tip = CGPoint(x: cx + rad * cos(a), y: cy + rad * sin(a))
    let head = NSBezierPath()
    let dir = CGPoint(x: -sin(a), y: cos(a))          // tangent direction
    let normal = CGPoint(x: cos(a), y: sin(a))
    let l = size * 0.075
    head.move(to: CGPoint(x: tip.x + dir.x * l * 0.9, y: tip.y + dir.y * l * 0.9))
    head.line(to: CGPoint(x: tip.x - normal.x * l * 0.55 - dir.x * l * 0.2, y: tip.y - normal.y * l * 0.55 - dir.y * l * 0.2))
    head.line(to: CGPoint(x: tip.x + normal.x * l * 0.55 - dir.x * l * 0.2, y: tip.y + normal.y * l * 0.55 - dir.y * l * 0.2))
    head.close(); NSColor.white.withAlphaComponent(0.92).setFill(); head.fill()
}
let play = NSBezierPath()
play.move(to: CGPoint(x: cx - rad * 0.38, y: cy + rad * 0.5))
play.line(to: CGPoint(x: cx + rad * 0.55, y: cy))
play.line(to: CGPoint(x: cx - rad * 0.38, y: cy - rad * 0.5))
play.close(); NSColor.white.setFill(); play.fill()
img.unlockFocus()
let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
rep.size = NSSize(width: size, height: size)
try! rep.representation(using: .png, properties: [:])!.write(to: out)
