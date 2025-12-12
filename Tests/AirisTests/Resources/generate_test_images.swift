import CoreGraphics
import CoreImage
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

// MARK: - CLI

struct Arguments {
    let force: Bool

    init() {
        let args = Set(CommandLine.arguments.dropFirst())
        self.force = args.contains("--force")
    }
}

let args = Arguments()

let scriptDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let imagesDir = scriptDir.appendingPathComponent("images")
let assetsDir = imagesDir.appendingPathComponent("assets")

try FileManager.default.createDirectory(at: assetsDir, withIntermediateDirectories: true)

// MARK: - Utilities

enum GeneratorError: Error, CustomStringConvertible {
    case failedToCreateContext
    case failedToCreateCGImage
    case failedToCreateDestination
    case failedToFinalize

    var description: String {
        switch self {
        case .failedToCreateContext: return "failedToCreateContext"
        case .failedToCreateCGImage: return "failedToCreateCGImage"
        case .failedToCreateDestination: return "failedToCreateDestination"
        case .failedToFinalize: return "failedToFinalize"
        }
    }
}

func shouldWrite(_ url: URL, force: Bool) -> Bool {
    force || !FileManager.default.fileExists(atPath: url.path)
}

func save(_ cgImage: CGImage, to url: URL, type: UTType, properties: CFDictionary? = nil) throws {
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, type.identifier as CFString, 1, nil) else {
        throw GeneratorError.failedToCreateDestination
    }

    CGImageDestinationAddImage(dest, cgImage, properties)

    guard CGImageDestinationFinalize(dest) else {
        throw GeneratorError.failedToFinalize
    }
}

func makeRGBAContext(width: Int, height: Int) throws -> CGContext {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
    guard let ctx = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: colorSpace,
        bitmapInfo: bitmapInfo
    ) else {
        throw GeneratorError.failedToCreateContext
    }

    // Use a consistent coordinate system (origin at top-left) for drawing.
    ctx.translateBy(x: 0, y: CGFloat(height))
    ctx.scaleBy(x: 1, y: -1)

    return ctx
}

func cgImage(from ciImage: CIImage) throws -> CGImage {
    let context = CIContext(options: [CIContextOption.useSoftwareRenderer: true])
    guard let cg = context.createCGImage(ciImage, from: ciImage.extent) else {
        throw GeneratorError.failedToCreateCGImage
    }
    return cg
}

func drawText(_ text: String, in rect: CGRect, context: CGContext) {
    // CoreText uses a bottom-left origin; convert by flipping vertically in the target rect.
    context.saveGState()
    context.translateBy(x: rect.minX, y: rect.maxY)
    context.scaleBy(x: 1, y: -1)

    let font = CTFontCreateWithName("Helvetica" as CFString, 36, nil)
    let attrs: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key(rawValue: kCTFontAttributeName as String): font,
        NSAttributedString.Key(rawValue: kCTForegroundColorAttributeName as String): CGColor(gray: 0.05, alpha: 1.0)
    ]

    let attributed = NSAttributedString(string: text, attributes: attrs)
    let framesetter = CTFramesetterCreateWithAttributedString(attributed)
    let path = CGPath(rect: CGRect(origin: .zero, size: rect.size), transform: nil)
    let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attributed.length), path, nil)
    CTFrameDraw(frame, context)

    context.restoreGState()
}

func drawHorizonImage(size: CGSize, highContrast: Bool) throws -> CGImage {
    let w = Int(size.width)
    let h = Int(size.height)
    let ctx = try makeRGBAContext(width: w, height: h)

    // Background sky gradient.
    let skyTop = highContrast ? CGColor(red: 0.05, green: 0.2, blue: 0.85, alpha: 1) : CGColor(red: 0.2, green: 0.45, blue: 0.95, alpha: 1)
    let skyBottom = highContrast ? CGColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1) : CGColor(red: 0.55, green: 0.8, blue: 1.0, alpha: 1)
    let groundTop = highContrast ? CGColor(red: 0.15, green: 0.45, blue: 0.1, alpha: 1) : CGColor(red: 0.25, green: 0.55, blue: 0.2, alpha: 1)
    let groundBottom = highContrast ? CGColor(red: 0.1, green: 0.25, blue: 0.05, alpha: 1) : CGColor(red: 0.15, green: 0.35, blue: 0.1, alpha: 1)

    func drawVerticalGradient(top: CGColor, bottom: CGColor, rect: CGRect) {
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [top, bottom] as CFArray, locations: [0.0, 1.0]) else {
            return
        }
        let start = CGPoint(x: rect.midX, y: rect.minY)
        let end = CGPoint(x: rect.midX, y: rect.maxY)
        ctx.saveGState()
        ctx.addRect(rect)
        ctx.clip()
        ctx.drawLinearGradient(gradient, start: start, end: end, options: [])
        ctx.restoreGState()
    }

    let horizonY = CGFloat(h) * 0.55
    drawVerticalGradient(top: skyTop, bottom: skyBottom, rect: CGRect(x: 0, y: 0, width: CGFloat(w), height: horizonY))
    drawVerticalGradient(top: groundTop, bottom: groundBottom, rect: CGRect(x: 0, y: horizonY, width: CGFloat(w), height: CGFloat(h) - horizonY))

    // Crisp horizon line.
    ctx.setStrokeColor(CGColor(gray: highContrast ? 0.02 : 0.25, alpha: 1))
    ctx.setLineWidth(highContrast ? 3 : 2)
    ctx.move(to: CGPoint(x: 0, y: horizonY))
    ctx.addLine(to: CGPoint(x: CGFloat(w), y: horizonY))
    ctx.strokePath()

    guard let cg = ctx.makeImage() else { throw GeneratorError.failedToCreateCGImage }
    return cg
}

func drawRectangleTestImage(size: CGSize) throws -> CGImage {
    let w = Int(size.width)
    let h = Int(size.height)
    let ctx = try makeRGBAContext(width: w, height: h)

    // Background
    ctx.setFillColor(CGColor(gray: 0.85, alpha: 1))
    ctx.fill(CGRect(x: 0, y: 0, width: CGFloat(w), height: CGFloat(h)))

    // Document rectangle
    let docRect = CGRect(x: CGFloat(w) * 0.14, y: CGFloat(h) * 0.12, width: CGFloat(w) * 0.72, height: CGFloat(h) * 0.76)

    // Shadow
    ctx.setFillColor(CGColor(gray: 0.0, alpha: 0.10))
    ctx.fill(docRect.offsetBy(dx: 6, dy: 6))

    // Paper
    ctx.setFillColor(CGColor(gray: 0.98, alpha: 1))
    ctx.fill(docRect)

    // Border
    ctx.setStrokeColor(CGColor(gray: 0.08, alpha: 1))
    ctx.setLineWidth(6)
    ctx.stroke(docRect.insetBy(dx: 3, dy: 3))

    // Inner lines to help rectangle detector.
    ctx.setStrokeColor(CGColor(gray: 0.25, alpha: 1))
    ctx.setLineWidth(2)
    for i in 1...6 {
        let y = docRect.minY + CGFloat(i) * docRect.height / 7
        ctx.move(to: CGPoint(x: docRect.minX + 24, y: y))
        ctx.addLine(to: CGPoint(x: docRect.maxX - 24, y: y))
    }
    ctx.strokePath()

    guard let cg = ctx.makeImage() else { throw GeneratorError.failedToCreateCGImage }
    return cg
}

func drawLineArtImage(size: CGSize) throws -> CGImage {
    let w = Int(size.width)
    let h = Int(size.height)
    let ctx = try makeRGBAContext(width: w, height: h)

    ctx.setFillColor(CGColor(gray: 1.0, alpha: 1.0))
    ctx.fill(CGRect(x: 0, y: 0, width: CGFloat(w), height: CGFloat(h)))

    ctx.setStrokeColor(CGColor(gray: 0.05, alpha: 1.0))
    ctx.setLineWidth(4)

    // Border frame
    ctx.stroke(CGRect(x: 24, y: 24, width: CGFloat(w) - 48, height: CGFloat(h) - 48))

    // Diagonals
    ctx.move(to: CGPoint(x: 48, y: 48))
    ctx.addLine(to: CGPoint(x: CGFloat(w) - 48, y: CGFloat(h) - 48))
    ctx.move(to: CGPoint(x: CGFloat(w) - 48, y: 48))
    ctx.addLine(to: CGPoint(x: 48, y: CGFloat(h) - 48))

    // Circle
    ctx.strokeEllipse(in: CGRect(x: CGFloat(w) * 0.30, y: CGFloat(h) * 0.30, width: CGFloat(w) * 0.40, height: CGFloat(h) * 0.40))

    ctx.strokePath()

    guard let cg = ctx.makeImage() else { throw GeneratorError.failedToCreateCGImage }
    return cg
}

func drawTransparentImage(size: CGSize) throws -> CGImage {
    let w = Int(size.width)
    let h = Int(size.height)
    let ctx = try makeRGBAContext(width: w, height: h)

    // Fully transparent background.
    ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0))
    ctx.fill(CGRect(x: 0, y: 0, width: CGFloat(w), height: CGFloat(h)))

    // Semi-transparent shape.
    ctx.setFillColor(CGColor(red: 1, green: 0.2, blue: 0.2, alpha: 0.65))
    ctx.fillEllipse(in: CGRect(x: CGFloat(w) * 0.15, y: CGFloat(h) * 0.15, width: CGFloat(w) * 0.70, height: CGFloat(h) * 0.70))

    // Solid center
    ctx.setFillColor(CGColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0))
    ctx.fillEllipse(in: CGRect(x: CGFloat(w) * 0.35, y: CGFloat(h) * 0.35, width: CGFloat(w) * 0.30, height: CGFloat(h) * 0.30))

    guard let cg = ctx.makeImage() else { throw GeneratorError.failedToCreateCGImage }
    return cg
}

func drawSmallImage(size: CGSize) throws -> CGImage {
    let w = Int(size.width)
    let h = Int(size.height)
    let ctx = try makeRGBAContext(width: w, height: h)

    // Simple deterministic gradient.
    let colors = [
        CGColor(red: 0.95, green: 0.35, blue: 0.2, alpha: 1),
        CGColor(red: 0.2, green: 0.55, blue: 0.95, alpha: 1)
    ]

    if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: 0),
            end: CGPoint(x: CGFloat(w), y: CGFloat(h)),
            options: []
        )
    }

    // Small marker to ensure non-trivial content.
    ctx.setFillColor(CGColor(gray: 0.05, alpha: 1))
    ctx.fill(CGRect(x: CGFloat(w) * 0.10, y: CGFloat(h) * 0.10, width: CGFloat(w) * 0.20, height: CGFloat(h) * 0.20))

    guard let cg = ctx.makeImage() else { throw GeneratorError.failedToCreateCGImage }
    return cg
}

func drawDocumentTextImage(size: CGSize) throws -> CGImage {
    let w = Int(size.width)
    let h = Int(size.height)
    let ctx = try makeRGBAContext(width: w, height: h)

    ctx.setFillColor(CGColor(gray: 1.0, alpha: 1.0))
    ctx.fill(CGRect(x: 0, y: 0, width: CGFloat(w), height: CGFloat(h)))

    // Outer border for a more document-like structure.
    ctx.setStrokeColor(CGColor(gray: 0.05, alpha: 1.0))
    ctx.setLineWidth(6)
    ctx.stroke(CGRect(x: 24, y: 24, width: CGFloat(w) - 48, height: CGFloat(h) - 48))

    let text = "AIRIS TEST DOCUMENT\n\nHELLO 12345\nTHE QUICK BROWN FOX\nJUMPS OVER 67890\n\nOCR SHOULD DETECT THIS"
    drawText(text, in: CGRect(x: 48, y: 64, width: CGFloat(w) - 96, height: CGFloat(h) - 128), context: ctx)

    guard let cg = ctx.makeImage() else { throw GeneratorError.failedToCreateCGImage }
    return cg
}

func makeQRCodeImage(size: CGSize, message: String) throws -> CGImage {
    let data = message.data(using: .utf8) ?? Data()
    guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
        throw GeneratorError.failedToCreateCGImage
    }
    filter.setValue(data, forKey: "inputMessage")
    filter.setValue("M", forKey: "inputCorrectionLevel")

    guard let output = filter.outputImage else {
        throw GeneratorError.failedToCreateCGImage
    }

    // Scale QR code to target size.
    let extent = output.extent.integral
    let scale = min(size.width / extent.width, size.height / extent.height)
    let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

    // Composite on white background.
    let background = CIImage(color: CIColor(red: 1, green: 1, blue: 1, alpha: 1))
        .cropped(to: CGRect(origin: .zero, size: size))

    let centered = scaled
        .cropped(to: CGRect(origin: .zero, size: scaled.extent.size))
        .transformed(by: CGAffineTransform(translationX: (size.width - scaled.extent.width) / 2, y: (size.height - scaled.extent.height) / 2))

    let final = centered.composited(over: background)
        .cropped(to: CGRect(origin: .zero, size: size))

    return try cgImage(from: final)
}

// MARK: - Generate

struct Output {
    let url: URL
    let description: String
}

var outputs: [Output] = []

func generatePNG(_ name: String, _ make: () throws -> CGImage) throws {
    let url = assetsDir.appendingPathComponent(name)
    if shouldWrite(url, force: args.force) {
        let image = try make()
        try save(image, to: url, type: .png)
        outputs.append(Output(url: url, description: "generated"))
    } else {
        outputs.append(Output(url: url, description: "kept"))
    }
}

func generateJPEG(_ name: String, quality: Double, _ make: () throws -> CGImage) throws {
    let url = assetsDir.appendingPathComponent(name)
    if shouldWrite(url, force: args.force) {
        let image = try make()
        let props: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: quality]
        try save(image, to: url, type: .jpeg, properties: props as CFDictionary)
        outputs.append(Output(url: url, description: "generated"))
    } else {
        outputs.append(Output(url: url, description: "kept"))
    }
}

// Safe-to-generate assets (algorithmic, no external dependencies).
try generatePNG("small_100x100.png") { try drawSmallImage(size: CGSize(width: 100, height: 100)) }
try generatePNG("small_100x100_meta.png") { try drawSmallImage(size: CGSize(width: 100, height: 100)) }
try generatePNG("transparent_200x200.png") { try drawTransparentImage(size: CGSize(width: 200, height: 200)) }
try generatePNG("rectangle_512x512.png") { try drawRectangleTestImage(size: CGSize(width: 512, height: 512)) }
try generatePNG("line_art_512x512.png") { try drawLineArtImage(size: CGSize(width: 512, height: 512)) }
try generatePNG("document_text_512x512.png") { try drawDocumentTextImage(size: CGSize(width: 512, height: 512)) }
try generatePNG("document_1024x1024.png") { try drawDocumentTextImage(size: CGSize(width: 1024, height: 1024)) }
try generatePNG("qrcode_512x512.png") { try makeQRCodeImage(size: CGSize(width: 512, height: 512), message: "AIRIS_TEST_QR") }
try generateJPEG("horizon_clear_512x512.jpg", quality: 0.9) { try drawHorizonImage(size: CGSize(width: 512, height: 512), highContrast: false) }
try generateJPEG("horizon_contrast_512x512.jpg", quality: 0.9) { try drawHorizonImage(size: CGSize(width: 512, height: 512), highContrast: true) }

// NOTE: Other assets (face/cat/hand/foreground/real photos) are intentionally not generated here.
// They are checked into the repository to keep Vision detection behavior stable.

print("Test assets generation completed (force=\(args.force)).")
for item in outputs {
    print("- \(item.url.lastPathComponent): \(item.description)")
}
