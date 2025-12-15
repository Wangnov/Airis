import ArgumentParser
@preconcurrency import Vision
import CoreImage
import Foundation

struct FlowCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "flow",
        abstract: HelpTextFactory.text(
            en: "Analyze optical flow between two images",
            cn: "分析两张图片之间的光流"
        ),
        discussion: helpDiscussion(
            en: """
                Calculate pixel motion vectors between two consecutive frames or images.
                This is useful for motion estimation, video analysis, and tracking.

                QUICK START:
                  airis vision flow frame1.jpg frame2.jpg

                HOW IT WORKS:
                  Optical flow computes the apparent motion of pixels between two images.
                  The result is a vector field where each pixel has X and Y displacement values.

                EXAMPLES:
                  # Basic optical flow analysis
                  airis vision flow prev.png next.png

                  # High accuracy analysis
                  airis vision flow frame1.jpg frame2.jpg --accuracy high

                  # Save flow visualization
                  airis vision flow prev.png next.png -o flow_viz.png

                  # JSON output for scripting
                  airis vision flow prev.png next.png --format json

                ACCURACY LEVELS:
                  low       - Fastest, lower precision
                  medium    - Balanced (default)
                  high      - Higher precision
                  veryHigh  - Best precision, slowest

                OUTPUT EXAMPLE:
                  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  Optical Flow Analysis
                  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  Input: frame1.jpg -> frame2.jpg
                  Flow field: 1920 x 1080
                  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

                NOTE:
                  Works best with consecutive video frames or images with moderate motion.
                  Large displacements may reduce accuracy.
                """,
            cn: """
                计算两张图片（常用于连续帧）之间的像素运动向量（光流）。
                适用于运动估计、视频分析、目标跟踪等场景。

                QUICK START:
                  airis vision flow frame1.jpg frame2.jpg

                EXAMPLES:
                  # 基础光流分析
                  airis vision flow prev.png next.png

                  # 更高精度
                  airis vision flow frame1.jpg frame2.jpg --accuracy high

                  # 输出可视化图（PNG）
                  airis vision flow prev.png next.png -o flow_viz.png

                  # JSON 输出（便于脚本解析）
                  airis vision flow prev.png next.png --format json

                ACCURACY LEVELS:
                  low / medium（默认）/ high / veryHigh
                """
        )
    )

    @Argument(help: HelpTextFactory.help(en: "First image (source/previous frame)", cn: "第一张图片（上一帧/参考）"))
    var image1: String

    @Argument(help: HelpTextFactory.help(en: "Second image (target/next frame)", cn: "第二张图片（下一帧/目标）"))
    var image2: String

    @Option(name: [.short, .long], help: HelpTextFactory.help(en: "Output flow visualization (PNG)", cn: "输出光流可视化图路径（PNG）"))
    var output: String?

    @Option(
        name: .long,
        help: HelpTextFactory.help(
            en: "Computation accuracy (low, medium, high, veryHigh)",
            cn: "计算精度（low / medium / high / veryHigh）"
        )
    )
    var accuracy: String = "medium"

    @Option(name: .long, help: HelpTextFactory.help(en: "Output format (table, json)", cn: "输出格式（table / json）"))
    var format: String = "table"

    func run() async throws {
        let url1 = try FileUtils.validateImageFile(at: image1)
        let url2 = try FileUtils.validateImageFile(at: image2)
        let outputFormat = OutputFormat.parse(format)
        let showHumanOutput = AirisOutput.shouldPrintHumanOutput(format: outputFormat)

        // Parse accuracy level
        let accuracyLevel: VisionService.OpticalFlowAccuracy
        switch accuracy.lowercased() {
        case "low":
            accuracyLevel = .low
        case "medium":
            accuracyLevel = .medium
        case "high":
            accuracyLevel = .high
        case "veryhigh":
            accuracyLevel = .veryHigh
        default:
            accuracyLevel = .medium
        }

        if showHumanOutput {
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("🌊 Optical Flow Analysis")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("📁 Input: \(url1.lastPathComponent) → \(url2.lastPathComponent)")
            print("🎯 Accuracy: \(accuracy)")
            if let output = output {
                print("💾 Output: \(output)")
            }
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("")
            print("⏳ Processing...")
        }

        let result: VisionService.OpticalFlowResult
        #if DEBUG
        if ProcessInfo.processInfo.environment["AIRIS_TEST_FLOW_FAKE_RESULT"] == "1" {
            result = Self.testFlowResult()
        } else {
            let vision = ServiceContainer.shared.visionService
            result = try await vision.computeOpticalFlow(
                from: url1,
                to: url2,
                accuracy: accuracyLevel
            )
        }
        #else
        let vision = ServiceContainer.shared.visionService
        result = try await vision.computeOpticalFlow(
            from: url1,
            to: url2,
            accuracy: accuracyLevel
        )
        #endif

        if outputFormat == .json {
            printJSON(result: result, file1: url1.lastPathComponent, file2: url2.lastPathComponent)
        } else if showHumanOutput {
            print("")
            print("✅ Analysis complete")
            print("")
            print("Flow field: \(result.width) × \(result.height)")
        }

        // Save visualization if requested
        if let outputPath = output {
            try saveFlowVisualization(result: result, to: outputPath)
            if showHumanOutput {
                print("")
                print(Strings.get("info.saved_to", outputPath))
            }
        }
    }

    private func printJSON(result: VisionService.OpticalFlowResult, file1: String, file2: String) {
        let dict: [String: Any] = [
            "source": file1,
            "target": file2,
            "flow_field": [
                "width": result.width,
                "height": result.height
            ],
            "accuracy": accuracy
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    }

    private func saveFlowVisualization(result: VisionService.OpticalFlowResult, to outputPath: String) throws {
        // Convert flow buffer to grayscale visualization
        let flowImage = CIImage(cvPixelBuffer: result.pixelBuffer)

        // Apply a simple visualization: convert to grayscale magnitude
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CIContext()

        // Scale the flow field to match a visible range
        let scaledImage = flowImage.transformed(by: CGAffineTransform(scaleX: 1, y: 1))

        #if DEBUG
        let forceNil = ProcessInfo.processInfo.environment["AIRIS_FORCE_FLOW_CGIMAGE_NIL"] == "1"
        let cgImageCandidate: CGImage?
        if forceNil {
            cgImageCandidate = nil
        } else {
            cgImageCandidate = context.createCGImage(scaledImage, from: scaledImage.extent, format: .RGBAf, colorSpace: colorSpace)
        }
        #else
        let cgImageCandidate = context.createCGImage(scaledImage, from: scaledImage.extent, format: .RGBAf, colorSpace: colorSpace)
        #endif

        guard let cgImage = cgImageCandidate else {
            throw AirisError.imageEncodeFailed
        }

        let imageIO = ServiceContainer.shared.imageIOService
        let outputURL = URL(fileURLWithPath: outputPath)

        // Ensure directory exists
        try FileUtils.ensureDirectory(for: outputPath)

        try imageIO.saveImage(cgImage, to: outputURL, format: "png")
    }

    #if DEBUG
    /// 测试桩：快速生成 2x2 光流结果，避免依赖 Vision 实际计算
    private static func testFlowResult() -> VisionService.OpticalFlowResult {
        let forceCreateFailure = ProcessInfo.processInfo.environment["AIRIS_FORCE_FLOW_TEST_PIXELBUFFER_FAIL"] == "1"

        var pixelBuffer: CVPixelBuffer?
        let status: CVReturn = forceCreateFailure
            ? kCVReturnInvalidSize
            : CVPixelBufferCreate(nil, 2, 2, kCVPixelFormatType_32BGRA, nil, &pixelBuffer)

        if status == kCVReturnSuccess, let buffer = pixelBuffer {
            return VisionService.OpticalFlowResult(pixelBuffer: buffer, width: 2, height: 2)
        }

        // 理论上不应触发；若触发则持续尝试直到创建成功（测试桩仅用于覆盖与避免 fatalError）。
        var retryPixelBuffer: CVPixelBuffer!
        while retryPixelBuffer == nil {
            var retryBuffer: CVPixelBuffer?
            let retryStatus = CVPixelBufferCreate(nil, 2, 2, kCVPixelFormatType_32BGRA, nil, &retryBuffer)
            if retryStatus == kCVReturnSuccess, let retryBuffer {
                retryPixelBuffer = retryBuffer
            }
        }

        return VisionService.OpticalFlowResult(pixelBuffer: retryPixelBuffer, width: 2, height: 2)
    }
    #endif
}
