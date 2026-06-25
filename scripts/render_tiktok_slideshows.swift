import AppKit
import Foundation

let width: CGFloat = 1080
let height: CGFloat = 1920
let outputURL = URL(fileURLWithPath: "Marketing/TikTok/slideshows")

struct Theme {
    let bg1: NSColor
    let bg2: NSColor
    let bg3: NSColor
    let ink: NSColor
    let chip: NSColor
    let soft: NSColor
    let line: NSColor
}

struct Deck {
    let id: String
    let title: String
    let kicker: String
    let caption: String
    let comment: String
    let theme: String
    let style: String
    let slides: [String]
}

func color(_ hex: String) -> NSColor {
    let clean = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    var value: UInt64 = 0
    Scanner(string: clean).scanHexInt64(&value)
    return NSColor(
        calibratedRed: CGFloat((value >> 16) & 0xff) / 255,
        green: CGFloat((value >> 8) & 0xff) / 255,
        blue: CGFloat(value & 0xff) / 255,
        alpha: 1
    )
}

let themes: [String: Theme] = [
    "sun": Theme(bg1: color("#f6f0df"), bg2: color("#c7a66a"), bg3: color("#183b35"), ink: color("#14251f"), chip: color("#17352f"), soft: color("#f9f4e8"), line: color("#c3a35e")),
    "pool": Theme(bg1: color("#eef4ed"), bg2: color("#a9c7bf"), bg3: color("#173a4a"), ink: color("#10242c"), chip: color("#123544"), soft: color("#f4f0e6"), line: color("#b89555")),
    "gold": Theme(bg1: color("#f7f0df"), bg2: color("#d1b36f"), bg3: color("#26352c"), ink: color("#1a241d"), chip: color("#223027"), soft: color("#fbf5e6"), line: color("#b99453")),
    "travel": Theme(bg1: color("#f4ead6"), bg2: color("#b98f58"), bg3: color("#1c2f4a"), ink: color("#182235"), chip: color("#182a42"), soft: color("#f8f1e5"), line: color("#b89555"))
]

let decks: [Deck] = [
    Deck(
        id: "01-mare-tan-vibe",
        title: "Riviera tan routine",
        kicker: "RIVIERA NOTES",
        caption: "Routine mare: luce giusta, lato giusto, diario tan. Niente caos.",
        comment: "Commenta RIVIERA + fototipo e preparo una routine.",
        theme: "sun",
        style: "card",
        slides: [
            "routine mare da fare con calma",
            "linen shirt, acqua fredda, stessa luce",
            "il punto e' non andare a memoria",
            "a meta' apro Solea",
            "timer fronte e retro",
            "diario tan a fine giornata",
            "commenta RIVIERA + fototipo"
        ]
    ),
    Deck(
        id: "02-piscina-tan-routine",
        title: "Pool club routine",
        kicker: "POOL CLUB",
        caption: "Lettino, tuffo, lato: routine piscina con ritmo, non con fretta.",
        comment: "Team mare o piscina?",
        theme: "pool",
        style: "card",
        slides: [
            "pool club tan routine",
            "lettino, tuffo, lato A",
            "il ritmo fa la differenza",
            "qui uso Solea come tan timer",
            "durata, lato, pause, diario",
            "domani replico quello che funziona",
            "team mare o piscina?"
        ]
    ),
    Deck(
        id: "03-abbronzatura-uniforme",
        title: "Uniform tan notes",
        kicker: "UNIFORM TAN",
        caption: "Il tan uniforme non e' fortuna: lato, zone, costanza.",
        comment: "Quale zona ti si abbronza sempre peggio?",
        theme: "gold",
        style: "card",
        slides: [
            "abbronzatura uniforme",
            "non e' fortuna",
            "e' lato, zone, costanza",
            "qui entra Solea",
            "fronte e retro separati",
            "zone esposte nel diario",
            "meno caso, piu' risultato"
        ]
    ),
    Deck(
        id: "04-base-vacanza",
        title: "Resort base tan",
        kicker: "RESORT NOTES",
        caption: "Se parti tra pochi giorni, serve una base graduale, non fretta.",
        comment: "Dove parti? Scrivi meta + giorni alla partenza.",
        theme: "travel",
        style: "card",
        slides: [
            "parto tra 7 giorni",
            "voglio una base pulita",
            "non tutto il primo giorno",
            "a meta' apro Solea",
            "meta, date, UV, fototipo",
            "piano leggero + diario tan",
            "commenta la meta"
        ]
    ),
    Deck(
        id: "05-routine-mare-aesthetic",
        title: "Riviera aesthetic",
        kicker: "RIVIERA ROUTINE",
        caption: "Routine mare old money: pochi gesti, stesso ritmo, Solea solo quando serve.",
        comment: "Vuoi versione piscina o barca?",
        theme: "sun",
        style: "aesthetic",
        slides: [
            "routine mare old money",
            "lino, acqua fredda, lato A",
            "niente fretta, stesso ritmo",
            "a meta' apro Solea",
            "timer fronte / retro",
            "diario tan a fine giornata",
            "salva questa routine"
        ]
    ),
    Deck(
        id: "06-routine-piscina-aesthetic",
        title: "Poolside aesthetic",
        kicker: "POOLSIDE ROUTINE",
        caption: "Poolside tan: lettino, lato, pausa, diario. Product placement velato.",
        comment: "Team mare o piscina?",
        theme: "pool",
        style: "aesthetic",
        slides: [
            "poolside tan routine",
            "lettino, tuffo, lato A",
            "il ritmo fa il risultato",
            "qui entra Solea",
            "timer tan + pause in acqua",
            "domani replico quello che funziona",
            "team mare o piscina?"
        ]
    ),
    Deck(
        id: "07-tan-uniforme-aesthetic",
        title: "Tennis club tan",
        kicker: "TENNIS CLUB TAN",
        caption: "Uniform tan, ma con mood tennis club: lato, zone, diario.",
        comment: "Quale zona ti si abbronza sempre peggio?",
        theme: "gold",
        style: "aesthetic",
        slides: [
            "uniform tan notes",
            "girarsi prima di ricordarselo",
            "seguire le zone, non solo il tempo",
            "a meta' routine uso Solea",
            "fronte, retro, zone esposte",
            "ripeto quello che funziona",
            "quale punto ti manca?"
        ]
    )
]

func topRect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> NSRect {
    NSRect(x: x, y: height - y - h, width: w, height: h)
}

func rounded(_ rect: NSRect, _ radius: CGFloat, fill: NSColor, alpha: CGFloat = 1) {
    fill.withAlphaComponent(alpha).setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}

func strokeRounded(_ rect: NSRect, _ radius: CGFloat, color: NSColor, alpha: CGFloat = 1, lineWidth: CGFloat = 2) {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    path.lineWidth = lineWidth
    color.withAlphaComponent(alpha).setStroke()
    path.stroke()
}

func serifFont(size: CGFloat) -> NSFont {
    NSFont(name: "Didot", size: size)
        ?? NSFont(name: "Bodoni 72 Book", size: size)
        ?? NSFont(name: "Georgia", size: size)
        ?? NSFont.systemFont(ofSize: size, weight: .regular)
}

func sansFont(size: CGFloat, weight: NSFont.Weight) -> NSFont {
    NSFont.systemFont(ofSize: size, weight: weight)
}

func drawText(_ text: String, in rect: NSRect, size: CGFloat, weight: NSFont.Weight, color: NSColor, alignment: NSTextAlignment = .left, serif: Bool = false, kern: CGFloat = 0) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    paragraph.lineBreakMode = .byWordWrapping
    let attrs: [NSAttributedString.Key: Any] = [
        .font: serif ? serifFont(size: size) : sansFont(size: size, weight: weight),
        .foregroundColor: color,
        .paragraphStyle: paragraph,
        .kern: kern
    ]
    (text as NSString).draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attrs)
}

func drawCentered(_ text: String, centerY: CGFloat, size: CGFloat, color: NSColor) {
    let rect = topRect(100, centerY - 250, 880, 500)
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [
        .font: serifFont(size: size),
        .foregroundColor: color,
        .paragraphStyle: paragraph,
        .kern: -0.5
    ]
    let bounds = (text as NSString).boundingRect(
        with: NSSize(width: rect.width, height: 900),
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        attributes: attrs
    )
    let drawRect = NSRect(x: rect.minX, y: rect.midY - bounds.height / 2, width: rect.width, height: bounds.height + 20)
    (text as NSString).draw(with: drawRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attrs)
}

func drawBackground(theme: Theme) {
    NSGradient(colors: [theme.bg1, theme.bg2, theme.bg3])?.draw(in: topRect(0, 0, width, height), angle: -42)
    theme.soft.withAlphaComponent(0.22).setFill()
    topRect(72, 246, 936, 1220).fill()
    strokeRounded(topRect(72, 246, 936, 1220), 0, color: theme.line, alpha: 0.32, lineWidth: 2)
    theme.line.withAlphaComponent(0.18).setStroke()
    let line = NSBezierPath()
    line.move(to: NSPoint(x: 135, y: height - 320))
    line.line(to: NSPoint(x: 945, y: height - 320))
    line.lineWidth = 2
    line.stroke()
}

func backgroundImageURL(deck: Deck, index: Int) -> URL? {
    let base = URL(fileURLWithPath: "Marketing/TikTok/backgrounds")
        .appendingPathComponent(deck.id)
        .appendingPathComponent(String(format: "%02d", index + 1))
    for ext in ["jpg", "jpeg", "png"] {
        let candidate = base.appendingPathExtension(ext)
        if FileManager.default.fileExists(atPath: candidate.path) {
            return candidate
        }
    }
    return nil
}

func drawPhotoBackgroundIfAvailable(deck: Deck, index: Int, theme: Theme) -> Bool {
    guard
        let url = backgroundImageURL(deck: deck, index: index),
        let image = NSImage(contentsOf: url),
        let best = image.representations.first
    else {
        return false
    }

    let imageSize = NSSize(width: best.pixelsWide, height: best.pixelsHigh)
    let scale = max(width / imageSize.width, height / imageSize.height)
    let drawSize = NSSize(width: imageSize.width * scale, height: imageSize.height * scale)
    let rect = NSRect(
        x: (width - drawSize.width) / 2,
        y: (height - drawSize.height) / 2,
        width: drawSize.width,
        height: drawSize.height
    )
    image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
    NSColor.black.withAlphaComponent(0.16).setFill()
    topRect(0, 0, width, height).fill()
    return true
}

func drawTopBar(deck: Deck, index: Int, total: Int, theme: Theme, branded: Bool) {
    rounded(topRect(72, 82, 936, 86), 8, fill: theme.chip, alpha: branded ? 0.76 : 0.62)
    strokeRounded(topRect(72, 82, 936, 86), 8, color: theme.line, alpha: 0.70, lineWidth: 1.5)
    let left = branded ? "SOLEA" : "RIVIERA"
    let mid = branded ? "TAN COMPANION" : deck.kicker
    drawText(left, in: topRect(116, 108, 220, 44), size: 27, weight: .bold, color: .white, serif: true, kern: 1.2)
    drawText(mid, in: topRect(350, 112, 430, 44), size: 20, weight: .semibold, color: NSColor.white.withAlphaComponent(0.78), kern: 2.8)
    drawText(String(format: "%02d/%02d", index + 1, total), in: topRect(848, 111, 120, 44), size: 22, weight: .medium, color: NSColor.white.withAlphaComponent(0.82), alignment: .right, kern: 1.2)
}

func drawChips(theme: Theme, branded: Bool) {
    let values = branded
        ? [("UV", "reale"), ("FOTOTIPO", "tuo"), ("LATO", "on"), ("DIARIO", "save")]
        : [("VIBE", "mare"), ("TAN", "plan"), ("LATO", "mix"), ("MOOD", "estate")]
    for (idx, item) in values.enumerated() {
        let x = CGFloat(120 + idx * 210)
        rounded(topRect(x, 1390, 178, 154), 8, fill: theme.soft, alpha: 0.72)
        strokeRounded(topRect(x, 1390, 178, 154), 8, color: theme.line, alpha: 0.36, lineWidth: 1)
        drawText(item.0, in: topRect(x + 22, 1424, 134, 32), size: 18, weight: .semibold, color: theme.ink.withAlphaComponent(0.56), kern: 1.8)
        drawText(item.1, in: topRect(x + 22, 1470, 140, 54), size: item.1.count > 5 ? 30 : 38, weight: .medium, color: theme.ink, serif: true)
    }
}

func drawProductCard(theme: Theme) {
    rounded(topRect(230, 1048, 620, 216), 10, fill: theme.soft, alpha: 0.86)
    strokeRounded(topRect(230, 1048, 620, 216), 10, color: theme.line, alpha: 0.60, lineWidth: 1.5)
    drawText("SOLEA", in: topRect(274, 1088, 220, 42), size: 25, weight: .medium, color: theme.ink.withAlphaComponent(0.72), serif: true, kern: 1.8)
    drawText("tan companion", in: topRect(274, 1138, 460, 70), size: 46, weight: .regular, color: theme.ink, serif: true)
    drawText("front / back / diary", in: topRect(274, 1210, 500, 42), size: 23, weight: .medium, color: theme.ink.withAlphaComponent(0.62), kern: 1.2)
}

func renderCard(deck: Deck, slide: String, index: Int, total: Int, theme: Theme) {
    let branded = index >= max(3, total / 2)
    if !drawPhotoBackgroundIfAvailable(deck: deck, index: index, theme: theme) {
        drawBackground(theme: theme)
    }
    drawTopBar(deck: deck, index: index, total: total, theme: theme, branded: branded)
    rounded(topRect(92, 330, 896, 870), 10, fill: theme.soft, alpha: 0.78)
    strokeRounded(topRect(92, 330, 896, 870), 10, color: theme.line, alpha: 0.36, lineWidth: 1.5)
    let label = branded ? "SOLEA" : "NOTES"
    drawText(label, in: topRect(142, 386, 240, 40), size: 20, weight: .semibold, color: theme.ink.withAlphaComponent(0.54), kern: 2.4)
    drawText(slide, in: topRect(142, 502, 790, 560), size: slide.count > 58 ? 66 : 82, weight: .regular, color: theme.ink, serif: true)
    drawChips(theme: theme, branded: branded)
    rounded(topRect(80, 1698, 920, 116), 8, fill: theme.chip, alpha: 0.86)
    strokeRounded(topRect(80, 1698, 920, 116), 8, color: theme.line, alpha: 0.55, lineWidth: 1)
    drawText(branded ? "SOLEA, TAN COMPANION" : "SLOW TAN, BETTER NOTES", in: topRect(124, 1728, 830, 34), size: 20, weight: .semibold, color: .white.withAlphaComponent(0.78), kern: 2.2)
    drawText(branded ? "UV, fototipo, lato, diario." : "Abbronzatura con metodo, non a caso.", in: topRect(124, 1764, 830, 38), size: 24, weight: .regular, color: .white.withAlphaComponent(0.76), serif: true)
}

func renderAesthetic(deck: Deck, slide: String, index: Int, total: Int, theme: Theme) {
    let branded = index >= max(3, total / 2)
    if !drawPhotoBackgroundIfAvailable(deck: deck, index: index, theme: theme) {
        drawBackground(theme: theme)
    }
    NSColor.black.withAlphaComponent(branded ? 0.18 : 0.10).setFill()
    topRect(0, 0, width, height).fill()
    drawTopBar(deck: deck, index: index, total: total, theme: theme, branded: branded)
    drawCentered(slide, centerY: 735, size: slide.count > 42 ? 68 : 80, color: .white)
    if branded {
        drawProductCard(theme: theme)
    }
    rounded(topRect(72, 1698, 936, 104), 8, fill: theme.chip, alpha: 0.62)
    strokeRounded(topRect(72, 1698, 936, 104), 8, color: theme.line, alpha: 0.46, lineWidth: 1)
    drawText(branded ? "Solea entra solo quando serve: timer, lato, diario." : "linen, water, light, rhythm", in: topRect(116, 1733, 850, 42), size: 23, weight: .medium, color: .white.withAlphaComponent(0.88), serif: true)
}

func renderPNG(deck: Deck, slide: String, index: Int, total: Int, to url: URL) throws {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(width),
        pixelsHigh: Int(height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "SoleaTikTok", code: 1)
    }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let theme = themes[deck.theme]!
    if deck.style == "aesthetic" {
        renderAesthetic(deck: deck, slide: slide, index: index, total: total, theme: theme)
    } else {
        renderCard(deck: deck, slide: slide, index: index, total: total, theme: theme)
    }
    NSGraphicsContext.restoreGraphicsState()
    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "SoleaTikTok", code: 2)
    }
    try data.write(to: url)
}

let fm = FileManager.default
if fm.fileExists(atPath: outputURL.path) {
    try fm.removeItem(at: outputURL)
}
try fm.createDirectory(at: outputURL, withIntermediateDirectories: true)

var readme: [String] = [
    "# Solea TikTok slideshow assets",
    "",
    "Direzione: old money/resort, marketing velato. Le prime slide sono vibe/utility tan-first; Solea entra a meta' carousel.",
    "",
    "Carica i PNG in ordine numerico dentro ogni cartella.",
    ""
]
var pngCount = 0

for deck in decks {
    let deckURL = outputURL.appendingPathComponent(deck.id)
    try fm.createDirectory(at: deckURL, withIntermediateDirectories: true)
    readme.append("## \(deck.title)")
    readme.append("")
    readme.append("Directory: `\(deckURL.path)`")
    readme.append("Caption: \(deck.caption)")
    readme.append("Commento fissato: \(deck.comment)")
    readme.append("")
    for (idx, slide) in deck.slides.enumerated() {
        let fileURL = deckURL.appendingPathComponent(String(format: "%02d.png", idx + 1))
        try renderPNG(deck: deck, slide: slide, index: idx, total: deck.slides.count, to: fileURL)
        readme.append("\(idx + 1). \(slide)")
        pngCount += 1
    }
    readme.append("")
}

try readme.joined(separator: "\n").write(to: outputURL.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
print("Rendered \(decks.count) slideshows to \(outputURL.path)")
print("PNG files generated: \(pngCount)")
