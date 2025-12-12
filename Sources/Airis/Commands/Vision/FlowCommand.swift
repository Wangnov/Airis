import ArgumentParser
@preconcurrency import Vision
import CoreImage
import Foundation

struct FlowCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "flow",
        abstract: "Analyze optical flow between two images",
        discussion: """
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
            """
    )

    @Argument(help: "First image (source/previous frame)")
    var image1: String

    @Argument(help: "Second image (target/next frame)")
    var image2: String

    @Option(name: [.short, .long], help: "Output flow visualization (PNG)")
    var output: String?

    @Option(name: .long, help: "Computation accuracy (low, medium, high, veryHigh)")
    var accuracy: String = "medium"

    @Option(name: .long, help: "Output format (table, json)")
    var format: String = "table"

    func run() async throws {
        let url1 = try FileUtils.validateImageFile(at: image1)
        let url2 = try FileUtils.validateImageFile(at: image2)

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

        if format != "json" {
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

        if format == "json" {
            printJSON(result: result, file1: url1.lastPathComponent, file2: url2.lastPathComponent)
        } else {
            print("")
            print("✅ Analysis complete")
            print("")
            print("Flow field: \(result.width) × \(result.height)")
        }

        // Save visualization if requested
        if let outputPath = output {
            try saveFlowVisualization(result: result, to: outputPath)
            if format != "json" {
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
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(nil, 2, 2, kCVPixelFormatType_32BGRA, nil, &pixelBuffer)
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            fatalError("CVPixelBufferCreate failed in testFlowResult")
        }
        return VisionService.OpticalFlowResult(pixelBuffer: buffer, width: 2, height: 2)
    }
    #endif
}
