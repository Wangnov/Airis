import AppKit
import ArgumentParser
import CoreImage
import Foundation
@preconcurrency import Vision

struct PersonsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "persons",
        abstract: HelpTextFactory.text(
            en: "Generate person segmentation mask",
            cn: "人物分割（输出 mask）"
        ),
        discussion: helpDiscussion(
            en: """
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
            """,
            cn: """
            生成人像分割 mask（灰度图），可用于背景替换/抠图/后期编辑。

            QUICK START:
              airis vision persons photo.jpg -o mask.png

            EXAMPLES:
              # 生成 mask（建议输出 PNG）
              airis vision persons portrait.jpg -o mask.png

              # 高质量分割
              airis vision persons photo.jpg --quality accurate -o mask.png

              # JSON 输出（仅输出 mask 信息）
              airis vision persons photo.jpg --format json

            QUALITY:
              fast / balanced（默认）/ accurate

            说明：
              - mask 中白色表示人物、黑色表示背景，灰色表示边缘过渡
              - 建议输出 PNG 以保留灰度细节
              - macOS 12.0+
            """
        )
    )

    @Argument(help: HelpTextFactory.help(en: "Path to image file", cn: "输入图片路径"))
    var imagePath: String

    @Option(name: [.short, .long], help: HelpTextFactory.help(en: "Output mask image path (PNG recommended)", cn: "输出 mask 路径（建议 PNG）"))
    var output: String?

    @Option(name: .long, help: HelpTextFactory.help(en: "Segmentation quality (fast, balanced, accurate)", cn: "分割质量（fast / balanced / accurate）"))
    var quality: String = "balanced"

    @Option(name: .long, help: HelpTextFactory.help(en: "Output format (table, json)", cn: "输出格式（table / json）"))
    var format: String = "table"

    @Flag(name: .long, help: HelpTextFactory.help(en: "Open result after processing", cn: "处理完成后打开输出文件"))
    var open: Bool = false

    func run() async throws {
        let url = try FileUtils.validateImageFile(at: imagePath)
        let outputFormat = OutputFormat.parse(format)
        let showHumanOutput = AirisOutput.shouldPrintHumanOutput(format: outputFormat)
        #if DEBUG
            let forceStub = ProcessInfo.processInfo.environment["AIRIS_TEST_PERSONS_FAKE_RESULT"] == "1"
            let forceCGImageNil = ProcessInfo.processInfo.environment["AIRIS_FORCE_PERSONS_CGIMAGE_NIL"] == "1"
        #else
            let forceStub = false
            let forceCGImageNil = false
        #endif

        // Parse quality level
        let qualityLevel: VisionService.PersonSegmentationQuality = switch quality.lowercased() {
        case "fast":
            .fast
        case "balanced":
            .balanced
        case "accurate":
            .accurate
        default:
            .balanced
        }

        if showHumanOutput {
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("👤 Person Segmentation")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("📁 File: \(url.lastPathComponent)")
            print("🎯 Quality: \(quality)")
            if let output {
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
                result = Self.testPersonResult()
            } else {
                result = try await vision.generatePersonSegmentation(at: url, quality: qualityLevel)
            }
        #else
            result = try await vision.generatePersonSegmentation(at: url, quality: qualityLevel)
        #endif

        if outputFormat == .json {
            printJSON(result: result, file: url.lastPathComponent)
        } else if showHumanOutput {
            print("")
            print("✅ Segmentation complete")
            print("")
            print("Mask: \(result.width) × \(result.height)")
        }

        // Save mask if output specified
        if let outputPath = output {
            try saveMask(result: result, to: outputPath)
            if showHumanOutput {
                print("")
                print(Strings.get("info.saved_to", outputPath))
            }

            if open {
                openImage(at: outputPath)
            }
        } else if showHumanOutput {
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
                "format": "grayscale_8bit",
            ],
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8)
        {
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
        private static func testPersonResult() -> VisionService.PersonSegmentationResult {
            let forceCreateFailure = ProcessInfo.processInfo.environment["AIRIS_FORCE_PERSONS_TEST_PIXELBUFFER_FAIL"] == "1"

            var pixelBuffer: CVPixelBuffer?
            let status: CVReturn = forceCreateFailure
                ? kCVReturnInvalidSize
                : CVPixelBufferCreate(nil, 2, 2, kCVPixelFormatType_OneComponent8, nil, &pixelBuffer)

            if status == kCVReturnSuccess, let buffer = pixelBuffer {
                return VisionService.PersonSegmentationResult(maskBuffer: buffer, width: 2, height: 2)
            }

            // 理论上不应触发；若触发则持续尝试直到创建成功（测试桩仅用于覆盖与避免 fatalError）。
            var retryPixelBuffer: CVPixelBuffer!
            while retryPixelBuffer == nil {
                var retryBuffer: CVPixelBuffer?
                let retryStatus = CVPixelBufferCreate(nil, 2, 2, kCVPixelFormatType_OneComponent8, nil, &retryBuffer)
                if retryStatus == kCVReturnSuccess, let retryBuffer {
                    retryPixelBuffer = retryBuffer
                }
            }

            return VisionService.PersonSegmentationResult(maskBuffer: retryPixelBuffer, width: 2, height: 2)
        }
    #endif
}
