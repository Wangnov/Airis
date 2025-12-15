import ArgumentParser
@preconcurrency import Vision
import CoreImage
import Foundation

struct SaliencyCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "saliency",
        abstract: HelpTextFactory.text(
            en: "Detect visual saliency (attention areas) in images",
            cn: "显著性检测（注意力区域）"
        ),
        discussion: helpDiscussion(
            en: """
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
                """,
            cn: """
                生成显著性热力图（saliency map），高亮视觉上更重要/更吸引注意力的区域。
                支持 attention（注意力）与 objectness（物体显著性）两种模式。

                QUICK START:
                  airis vision saliency photo.jpg

                EXAMPLES:
                  # 默认：attention
                  airis vision saliency portrait.jpg

                  # objectness 模式
                  airis vision saliency scene.jpg --type objectness

                  # 保存热力图（PNG）
                  airis vision saliency photo.jpg -o heatmap.png

                  # JSON 输出（包含 bounding boxes）
                  airis vision saliency photo.jpg --format json

                OPTIONS:
                  --type <type>      attention / objectness
                  --format <fmt>     输出格式：table（默认）或 json
                """
        )
    )

    @Argument(help: HelpTextFactory.help(en: "Path to image file", cn: "输入图片路径"))
    var imagePath: String

    @Option(name: .long, help: HelpTextFactory.help(en: "Saliency type (attention, objectness)", cn: "显著性类型（attention / objectness）"))
    var type: String = "attention"

    @Option(name: [.short, .long], help: HelpTextFactory.help(en: "Output heatmap image path", cn: "输出热力图路径"))
    var output: String?

    @Option(name: .long, help: HelpTextFactory.help(en: "Output format (table, json)", cn: "输出格式（table / json）"))
    var format: String = "table"

    func run() async throws {
        let url = try FileUtils.validateImageFile(at: imagePath)
        let outputFormat = OutputFormat.parse(format)
        let showHumanOutput = AirisOutput.shouldPrintHumanOutput(format: outputFormat)

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

        if showHumanOutput {
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
            result = Self.testSaliencyResult(type: saliencyType)
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

        if outputFormat == .json {
            printJSON(result: result, file: url.lastPathComponent, imageInfo: imageInfo)
        } else if showHumanOutput {
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
            if showHumanOutput {
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
    private static func testSaliencyResult(type: VisionService.SaliencyType) -> VisionService.SaliencyResult {
        let forceCreateFailure = ProcessInfo.processInfo.environment["AIRIS_FORCE_SALIENCY_TEST_PIXELBUFFER_FAIL"] == "1"

        var pixelBuffer: CVPixelBuffer?
        let status: CVReturn = forceCreateFailure
            ? kCVReturnInvalidSize
            : CVPixelBufferCreate(nil, 4, 4, kCVPixelFormatType_OneComponent8, nil, &pixelBuffer)

        let buffer: CVPixelBuffer
        if status == kCVReturnSuccess, let created = pixelBuffer {
            buffer = created
        } else {
            // 理论上不应触发；若触发则持续尝试直到创建成功（测试桩仅用于覆盖与避免 fatalError）。
            var retryPixelBuffer: CVPixelBuffer!
            while retryPixelBuffer == nil {
                var retryBuffer: CVPixelBuffer?
                let retryStatus = CVPixelBufferCreate(nil, 4, 4, kCVPixelFormatType_OneComponent8, nil, &retryBuffer)
                if retryStatus == kCVReturnSuccess, let retryBuffer {
                    retryPixelBuffer = retryBuffer
                }
            }
            buffer = retryPixelBuffer
        }

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
