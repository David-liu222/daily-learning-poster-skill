import AppKit

// Usage: swift render_daily_learning.swift /absolute/path/to/card.json
// Required JSON fields: kind (learning|festival), date (MM/DD), weekday, lead,
// body, output. Optional: title, action, signature text, festivalBackground,
// darkBackground. Festival cards require festivalBackground and normally omit
// action and signature. The script's sibling assets directory contains the logo
// and QR code used for every card.

enum Signature: Decodable {
    case text(String)
    case legacyEnabled(Bool)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .text(value)
        } else {
            self = .legacyEnabled(try container.decode(Bool.self))
        }
    }

    var displayText: String? {
        switch self {
        case .text(let value):
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        case .legacyEnabled(true):
            return "力量发展集团董事长 具文忠"
        case .legacyEnabled(false):
            return nil
        }
    }
}

struct Card: Decodable {
    let kind: String
    let year: String?
    let date: String
    let weekday: String
    let title: String?
    let lead: String
    let body: String
    let action: String?
    let signature: Signature?
    let festivalBackground: String?
    let darkBackground: Bool?
    let output: String
}

guard CommandLine.arguments.count == 2 else {
    fatalError("Usage: swift render_daily_learning.swift /absolute/path/to/card.json")
}

let configURL = URL(fileURLWithPath: CommandLine.arguments[1])
let config = try JSONDecoder().decode(Card.self, from: Data(contentsOf: configURL))
let isFestival = config.kind == "festival"
guard !isFestival || config.festivalBackground != nil else {
    fatalError("Festival cards require festivalBackground.")
}

let canvas = NSSize(width: 1242, height: 1660)
let skillRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let logoPath = skillRoot.appendingPathComponent("assets/group-logo.png").path
let qrPath = skillRoot.appendingPathComponent("assets/follow-qr.jpg").path
guard let logo = NSImage(contentsOfFile: logoPath), let qr = NSImage(contentsOfFile: qrPath) else {
    fatalError("Brand assets are missing from the skill assets directory.")
}

func font(_ size: CGFloat, bold: Bool = false) -> NSFont {
    if bold { return NSFont(name: "Songti SC Semibold", size: size) ?? NSFont.systemFont(ofSize: size, weight: .semibold) }
    return NSFont(name: "Songti SC", size: size) ?? NSFont.systemFont(ofSize: size)
}

func draw(_ text: String, in rect: NSRect, font textFont: NSFont, color: NSColor, line: CGFloat = 1.25, alignment: NSTextAlignment = .left) {
    let style = NSMutableParagraphStyle()
    style.lineSpacing = textFont.pointSize * (line - 1)
    style.alignment = alignment
    NSAttributedString(string: text, attributes: [
        .font: textFont,
        .foregroundColor: color,
        .paragraphStyle: style
    ]).draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading])
}

func rounded(_ rect: NSRect, _ radius: CGFloat, _ color: NSColor) {
    color.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}

func drawLogoAndDate(dark: Bool) {
    logo.draw(in: NSRect(x: 64, y: 1440, width: 118, height: 92), from: NSRect(origin: .zero, size: logo.size), operation: .sourceOver, fraction: 1)
    rounded(NSRect(x: 842, y: 1422, width: 328, height: 144), 20, NSColor(calibratedWhite: 1, alpha: dark ? 0.92 : 0.96))
    let displayYear = config.year ?? "2026"
    draw("\(displayYear)  \(config.weekday)", in: NSRect(x: 876, y: 1518, width: 260, height: 30), font: font(23), color: .init(calibratedWhite: 0.25, alpha: 1))
    draw(config.date, in: NSRect(x: 874, y: 1443, width: 250, height: 70), font: font(56), color: .init(calibratedWhite: 0.11, alpha: 1))
}

func drawQR(darkLabel: Bool) {
    rounded(NSRect(x: 932, y: 120, width: 214, height: 214), 18, .white)
    qr.draw(in: NSRect(x: 946, y: 134, width: 186, height: 186), from: NSRect(origin: .zero, size: qr.size), operation: .sourceOver, fraction: 1)
    if isFestival {
        rounded(NSRect(x: 942, y: 70, width: 194, height: 42), 14, darkLabel ? NSColor(calibratedRed: 0.03, green: 0.11, blue: 0.22, alpha: 0.92) : NSColor(calibratedWhite: 1, alpha: 0.92))
    }
    draw("扫码关注", in: NSRect(x: 932, y: 80, width: 214, height: 26), font: font(21), color: darkLabel ? .white : .init(calibratedWhite: 0.20, alpha: 1), alignment: .center)
    rounded(NSRect(x: 997, y: 59, width: 84, height: 6), 3, darkLabel ? .white : .init(calibratedRed: 0.55, green: 0.20, blue: 0.10, alpha: 1))
}

func dailyCard() -> NSImage {
    let image = NSImage(size: canvas)
    image.lockFocus()
    NSColor(calibratedRed: 0.95, green: 0.96, blue: 0.95, alpha: 1).setFill()
    NSBezierPath(rect: NSRect(origin: .zero, size: canvas)).fill()
    NSColor(calibratedRed: 0.07, green: 0.16, blue: 0.25, alpha: 1).setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 1270, width: 1242, height: 390)).fill()
    NSColor(calibratedRed: 0.12, green: 0.29, blue: 0.40, alpha: 1).setFill()
    NSBezierPath(ovalIn: NSRect(x: 760, y: 1235, width: 600, height: 420)).fill()
    drawLogoAndDate(dark: false)
    draw("每日一学", in: NSRect(x: 64, y: 1374, width: 300, height: 38), font: font(28), color: .init(calibratedWhite: 1, alpha: 0.83))
    draw(config.title ?? "每日一学", in: NSRect(x: 62, y: 1285, width: 720, height: 80), font: font(60, bold: true), color: .white)
    rounded(NSRect(x: 60, y: 405, width: 1122, height: 770), 30, .white)
    let accent = NSColor(calibratedRed: 0.60, green: 0.24, blue: 0.12, alpha: 1)
    draw("今日主题 · \(config.lead)", in: NSRect(x: 104, y: 1082, width: 920, height: 50), font: font(37, bold: true), color: accent)
    rounded(NSRect(x: 104, y: 1050, width: 200, height: 4), 2, .init(calibratedRed: 0.90, green: 0.60, blue: 0.26, alpha: 1))
    let bodySize: CGFloat = config.body.count > 180 ? 25 : 27
    draw(config.body, in: NSRect(x: 104, y: 690, width: 950, height: 335), font: font(bodySize), color: .init(calibratedWhite: 0.16, alpha: 1), line: 1.42)
    if let signature = config.signature?.displayText {
        draw(signature, in: NSRect(x: 590, y: 630, width: 430, height: 34), font: font(bodySize), color: .init(calibratedWhite: 0.38, alpha: 1), alignment: .right)
    }
    if let action = config.action, !action.isEmpty {
        rounded(NSRect(x: 102, y: 475, width: 958, height: 118), 18, .init(calibratedRed: 0.95, green: 0.92, blue: 0.85, alpha: 1))
        draw("行动提示", in: NSRect(x: 132, y: 540, width: 200, height: 31), font: font(27, bold: true), color: .init(calibratedRed: 0.55, green: 0.20, blue: 0.10, alpha: 1))
        draw(action, in: NSRect(x: 132, y: 498, width: 880, height: 38), font: font(29), color: .init(calibratedWhite: 0.20, alpha: 1))
    }
    drawQR(darkLabel: false)
    image.unlockFocus()
    return image
}

func festivalCard() -> NSImage {
    let backgroundPath = config.festivalBackground!
    guard let background = NSImage(contentsOfFile: backgroundPath) else { fatalError("Unable to load festivalBackground: \(backgroundPath)") }
    let dark = config.darkBackground ?? false
    let image = NSImage(size: canvas)
    image.lockFocus()
    background.draw(in: NSRect(origin: .zero, size: canvas), from: NSRect(origin: .zero, size: background.size), operation: .sourceOver, fraction: 1)
    drawLogoAndDate(dark: dark)
    let panelColor = dark ? NSColor(calibratedRed: 0.04, green: 0.12, blue: 0.24, alpha: 0.84) : NSColor(calibratedRed: 1, green: 0.98, blue: 0.93, alpha: 0.88)
    let mainColor = dark ? NSColor.white : NSColor(calibratedWhite: 0.13, alpha: 1)
    let bodyColor = dark ? NSColor(calibratedWhite: 0.97, alpha: 1) : NSColor(calibratedWhite: 0.16, alpha: 1)
    let accent = dark ? NSColor(calibratedRed: 0.93, green: 0.72, blue: 0.27, alpha: 1) : NSColor(calibratedRed: 0.55, green: 0.20, blue: 0.10, alpha: 1)
    rounded(NSRect(x: 52, y: 370, width: 1138, height: 835), 28, panelColor)
    draw("每日一学 · 节日卡片", in: NSRect(x: 88, y: 1130, width: 500, height: 36), font: font(25), color: accent)
    draw(config.title ?? "节日卡片", in: NSRect(x: 86, y: 1014, width: 980, height: 100), font: font(68, bold: true), color: mainColor)
    rounded(NSRect(x: 88, y: 992, width: 430, height: 4), 2, accent)
    draw(config.lead, in: NSRect(x: 88, y: 905, width: 980, height: 48), font: font(34, bold: true), color: accent)
    draw(config.body, in: NSRect(x: 88, y: 650, width: 1000, height: 220), font: font(38), color: bodyColor, line: 1.45)
    if let action = config.action, !action.isEmpty {
        rounded(NSRect(x: 84, y: 486, width: 1010, height: 105), 16, dark ? NSColor(calibratedWhite: 1, alpha: 0.12) : NSColor(calibratedRed: 0.86, green: 0.68, blue: 0.43, alpha: 0.18))
        draw(action, in: NSRect(x: 110, y: 515, width: 940, height: 44), font: font(32, bold: true), color: bodyColor)
    }
    drawQR(darkLabel: dark)
    image.unlockFocus()
    return image
}

func pngData(for image: NSImage) -> Data {
    let target = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1242, pixelsHigh: 1660, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    target.size = canvas
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: target)
    image.draw(in: NSRect(origin: .zero, size: canvas), from: NSRect(origin: .zero, size: canvas), operation: .copy, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
    return target.representation(using: .png, properties: [:])!
}

let image = isFestival ? festivalCard() : dailyCard()
let outputURL = URL(fileURLWithPath: config.output)
try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
try pngData(for: image).write(to: outputURL)
print("Rendered \(outputURL.path)")
