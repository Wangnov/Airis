import ArgumentParser
@preconcurrency import Vision
import CoreImage
import Foundation
import AppKit

struct PersonsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "persons",
        abstract: "Generate person segmentation mask",
        discussion: """
            Create a segmentation mask for people in images.
            Useful for background removal, virtual backgrounds, and photo editing.

            QUICK START:
              airis vision persons photo.jpg -o mask.png

            QUALITY LEVELS:
              fast      - Fastest processing, lower edge quality
              balanced  - Good balance of speed and quality (default)
              accurate  - Best edge quality, slowest
                         Also smooths masks across video frames

            EXAMPLES:
              # Generate person mask
              airis vision persons portrait.jpg -o mask.png

              # High quality segmentation
              airis vision persons photo.jpg --quality accurate -o mask.png

              # Fast processing for video frames
              airis vision persons frame.jpg --quality fast -o mask.png

              # JSON output with mask info
              airis vision persons photo.jpg --format json

            OUTPUT FORMATS:
              The mask is a grayscale image where:
              - White (255) = Person pixels
              - Black (0)   = Background pixels
              - Gray values = Edge/semi-transparent areas

              NOTE: Output should be PNG format to preserve grayscale values.

            OUTPUT EXAMPLE:
              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              Person Segmentation
              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              File: portrait.jpg
              Quality: balanced
              Output: mask.png
              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

              Mask: 1920 x 1080
              Saved to: mask.png

            BEST PRACTICES:
              - Person should be mostly visible (not heavily occluded)
              - Works best when person height is at least half the image height
              - Good contrast between person and background improves results
              - Supports up to 4 people in an image

            REQUIREMENTS:
              macOS 12.0+ (Monterey or later)
            """
    )

    @Argument(help: "Path to image file")
    var imagePath: String

    @Option(name: [.short, .long], help: "Output mask image path (PNG recommended)")
    var output: String?

    @Option(name: .long, help: "Segmentation quality (fast, balanced, accurate)")
    var quality: String = "balanced"

    @Option(name: .long, help: "Output format (table, json)")
    var format: String = "table"

    @Flag(name: .long, help: "Open result after processing")
    var open: Bool = false

    func run() async throws {
        let url = try FileUtils.validateImageFile(at: imagePath)
        #if DEBUG
        let forceStub = ProcessInfo.processInfo.environment["AIRIS_TEST_PERSONS_FAKE_RESULT"] == "1"
        let forceCGImageNil = ProcessInfo.processInfo.environment["AIRIS_FORCE_PERSONS_CGIMAGE_NIL"] == "1"
        #else
        let forceStub = false
        let forceCGImageNil = false
        #endif

        // Parse quality level
        let qualityLevel: VisionService.PersonSegmentationQuality
        switch quality.lowercased() {
        case "fast":
            qualityLevel = .fast
        case "balanced":
            qualityLevel = .balanced
        case "accurate":
            qualityLevel = .accurate
        default:
            qualityLevel = .balanced
        }

        if format != "json" {
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("👤 Person Segmentation")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("📁 File: \(url.lastPathComponent)")
            print("🎯 Quality: \(quality)")
            if let output = output {
                print("💾 Output: \(output)")
            }
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("")
            print("⏳ Generating segmentation mask...")
        }

        let vision = ServiceContainer.shared.visionService
        let result: VisionService.PersonSegmentationResult
        #if DEBUG
        if forceStub {
            result = Self._testPersonResult()
        } else {
            result = try await vision.generatePersonSegmentation(at: url, quality: qualityLevel)
        }
        #else
        result = try await vision.generatePersonSegmentation(at: url, quality: qualityLevel)
        #endif

        if format == "json" {
            printJSON(result: result, file: url.lastPathComponent)
        } else {
            print("")
            print("✅ Segmentation complete")
            print("")
            print("Mask: \(result.width) × \(result.height)")
        }

        // Save mask if output specified
        if let outputPath = output {
            try saveMask(result: result, to: outputPath)
            if format != "json" {
                print("")
                print(Strings.get("info.saved_to", outputPath))
            }

            if open {
                openImage(at: outputPath)
            }
        } else if format != "json" {
            print("")
            print("💡 Use -o <path> to save the mask image")
        }
    }

    private func printJSON(result: VisionService.PersonSegmentationResult, file: String) {
        let dict: [String: Any] = [
            "file": file,
            "quality": quality,
            "mask": [
                "width": result.width,
                "height": result.height,
                "format": "grayscale_8bit"
            ]
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    }

    private func saveMask(result: VisionService.PersonSegmentationResult, to outputPath: String) throws {
        let maskImage = CIImage(cvPixelBuffer: result.maskBuffer)

        let context = CIContext()
        #if DEBUG
        let forceNil = ProcessInfo.processInfo.environment["AIRIS_FORCE_PERSONS_CGIMAGE_NIL"] == "1"
        let cgImageCandidate = forceNil ? nil : context.createCGImage(maskImage, from: maskImage.extent)
        #else
        let cgImageCandidate = context.createCGImage(maskImage, from: maskImage.extent)
        #endif

        guard let cgImage = cgImageCandidate else {
            throw AirisError.imageEncodeFailed
        }

        let imageIO = ServiceContainer.shared.imageIOService
        let outputURL = URL(fileURLWithPath: outputPath)

        try FileUtils.ensureDirectory(for: outputPath)

        // PNG is recommended for masks to preserve grayscale values
        let format = outputPath.hasSuffix(".png") ? "png" : "jpg"
        try imageIO.saveImage(cgImage, to: outputURL, format: format)
    }

    private func openImage(at path: String) {
        let url = URL(fileURLWithPath: path)
        NSWorkspace.openForCLI(url)
    }

    #if DEBUG
    /// 测试桩：生成 2x2 的人像分割结果
    private static func _testPersonResult() -> VisionService.PersonSegmentationResult {
        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(nil, 2, 2, kCVPixelFormatType_OneComponent8, nil, &pixelBuffer)
        let buffer = pixelBuffer!
        return VisionService.PersonSegmentationResult(maskBuffer: buffer, width: 2, height: 2)
    }
    #endif
}
