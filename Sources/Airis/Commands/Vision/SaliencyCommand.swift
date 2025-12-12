import ArgumentParser
@preconcurrency import Vision
import CoreImage
import Foundation

struct SaliencyCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "saliency",
        abstract: "Detect visual saliency (attention areas) in images",
        discussion: """
            Generate a saliency map highlighting visually important regions.
            Supports both attention-based and objectness-based detection.

            QUICK START:
              airis vision saliency photo.jpg

            SALIENCY TYPES:
              attention   - Human visual attention model (where eyes look)
                           Returns 1 salient region (default)
              objectness  - Object prominence model (likely objects)
                           Returns up to 3 salient regions

            EXAMPLES:
              # Attention-based saliency (default)
              airis vision saliency portrait.jpg

              # Objectness-based saliency
              airis vision saliency scene.jpg --type objectness

              # Save heatmap visualization
              airis vision saliency photo.jpg -o heatmap.png

              # JSON output with bounding boxes
              airis vision saliency photo.jpg --format json

            OUTPUT EXAMPLE:
              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              Saliency Detection
              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              File: portrait.jpg
              Type: attention
              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

              Heatmap: 68 x 68
              Salient regions: 1

              Region 1:
                Position: (0.25, 0.30)
                Size: 0.50 x 0.40

            USE CASES:
              - Smart cropping (crop around salient regions)
              - Thumbnail generation
              - Image composition analysis
              - Focus detection

            NOTE:
              The heatmap is a grayscale image where brighter = more salient.
              Bounding boxes use normalized coordinates (0.0 - 1.0).
            """
    )

    @Argument(help: "Path to image file")
    var imagePath: String

    @Option(name: .long, help: "Saliency type (attention, objectness)")
    var type: String = "attention"

    @Option(name: [.short, .long], help: "Output heatmap image path")
    var output: String?

    @Option(name: .long, help: "Output format (table, json)")
    var format: String = "table"

    func run() async throws {
        let url = try FileUtils.validateImageFile(at: imagePath)

        // Parse saliency type
        let saliencyType: VisionService.SaliencyType
        switch type.lowercased() {
        case "attention":
            saliencyType = .attention
        case "objectness":
            saliencyType = .objectness
        default:
            saliencyType = .attention
        }

        if format != "json" {
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("👁️ Saliency Detection")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("📁 File: \(url.lastPathComponent)")
            print("🎯 Type: \(type)")
            if let output = output {
                print("💾 Output: \(output)")
            }
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("")
            print("⏳ Detecting saliency...")
        }

        let result: VisionService.SaliencyResult
        #if DEBUG
        if ProcessInfo.processInfo.environment["AIRIS_TEST_SALIENCY_FAKE_RESULT"] == "1" {
            result = Self._testSaliencyResult(type: saliencyType)
        } else {
            let vision = ServiceContainer.shared.visionService
            result = try await vision.detectSaliency(at: url, type: saliencyType)
        }
        #else
        let vision = ServiceContainer.shared.visionService
        result = try await vision.detectSaliency(at: url, type: saliencyType)
        #endif

        // Get original image info for coordinate conversion
        let imageIO = ServiceContainer.shared.imageIOService
        let imageInfo = try imageIO.getImageInfo(at: url)

        if format == "json" {
            printJSON(result: result, file: url.lastPathComponent, imageInfo: imageInfo)
        } else {
            print("")
            print("✅ Detection complete")
            print("")
            print("Heatmap: \(result.width) × \(result.height)")
            print("Salient regions: \(result.salientBounds.count)")

            if !result.salientBounds.isEmpty {
                print("")
                for (index, bound) in result.salientBounds.enumerated() {
                    print("Region \(index + 1):")
                    print("  Position: (\(String(format: "%.2f", bound.origin.x)), \(String(format: "%.2f", bound.origin.y)))")
                    print("  Size: \(String(format: "%.2f", bound.width)) × \(String(format: "%.2f", bound.height))")

                    // Also show pixel coordinates
                    let pixelX = Int(bound.origin.x * CGFloat(imageInfo.width))
                    let pixelY = Int((1 - bound.origin.y - bound.height) * CGFloat(imageInfo.height))
                    let pixelW = Int(bound.width * CGFloat(imageInfo.width))
                    let pixelH = Int(bound.height * CGFloat(imageInfo.height))
                    print("  Pixels: (\(pixelX), \(pixelY)) \(pixelW)×\(pixelH)")
                }
            }
        }

        // Save heatmap if requested
        if let outputPath = output {
            try saveHeatmap(result: result, to: outputPath)
            if format != "json" {
                print("")
                print(Strings.get("info.saved_to", outputPath))
            }
        }
    }

    private func printJSON(result: VisionService.SaliencyResult, file: String, imageInfo: ImageIOService.ImageInfo) {
        let regions = result.salientBounds.map { bound -> [String: Any] in
            let pixelX = Int(bound.origin.x * CGFloat(imageInfo.width))
            let pixelY = Int((1 - bound.origin.y - bound.height) * CGFloat(imageInfo.height))
            let pixelW = Int(bound.width * CGFloat(imageInfo.width))
            let pixelH = Int(bound.height * CGFloat(imageInfo.height))

            return [
                "normalized": [
                    "x": bound.origin.x,
                    "y": bound.origin.y,
                    "width": bound.width,
                    "height": bound.height
                ],
                "pixels": [
                    "x": pixelX,
                    "y": pixelY,
                    "width": pixelW,
                    "height": pixelH
                ]
            ]
        }

        let dict: [String: Any] = [
            "file": file,
            "type": type,
            "heatmap": [
                "width": result.width,
                "height": result.height
            ],
            "salient_regions": regions
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    }

    private func saveHeatmap(result: VisionService.SaliencyResult, to outputPath: String) throws {
        let heatmapImage = CIImage(cvPixelBuffer: result.heatMapBuffer)

        let context = CIContext()
        #if DEBUG
        let forceNil = ProcessInfo.processInfo.environment["AIRIS_FORCE_SALIENCY_CGIMAGE_NIL"] == "1"
        let cgImageCandidate = forceNil ? nil : context.createCGImage(heatmapImage, from: heatmapImage.extent)
        #else
        let cgImageCandidate = context.createCGImage(heatmapImage, from: heatmapImage.extent)
        #endif

        guard let cgImage = cgImageCandidate else {
            throw AirisError.imageEncodeFailed
        }

        let imageIO = ServiceContainer.shared.imageIOService
        let outputURL = URL(fileURLWithPath: outputPath)

        try FileUtils.ensureDirectory(for: outputPath)

        let format = outputPath.hasSuffix(".png") ? "png" : "jpg"
        try imageIO.saveImage(cgImage, to: outputURL, format: format)
    }

    #if DEBUG
    /// 测试桩：快速生成带 1 个显著区域的 4x4 热力图
    private static func _testSaliencyResult(type: VisionService.SaliencyType) -> VisionService.SaliencyResult {
        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(nil, 4, 4, kCVPixelFormatType_OneComponent8, nil, &pixelBuffer)
        let buffer = pixelBuffer!
        let bounds: [CGRect]
        if ProcessInfo.processInfo.environment["AIRIS_TEST_SALIENCY_EMPTY"] == "1" {
            bounds = []
        } else if type == .objectness {
            bounds = [CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4), CGRect(x: 0.6, y: 0.5, width: 0.2, height: 0.2)]
        } else {
            bounds = [CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)]
        }
        return VisionService.SaliencyResult(heatMapBuffer: buffer, salientBounds: bounds, width: 4, height: 4)
    }
    #endif
}
