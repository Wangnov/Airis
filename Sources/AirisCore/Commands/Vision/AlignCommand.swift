import ArgumentParser
@preconcurrency import Vision
import CoreImage
import Foundation

struct AlignCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "align",
        abstract: HelpTextFactory.text(
            en: "Compute image registration/alignment transform",
            cn: "计算两张图片的对齐/配准变换"
        ),
        discussion: helpDiscussion(
            en: """
                Calculate the transformation needed to align two images.
                This is useful for image stitching, panorama creation, and motion tracking.

                QUICK START:
                  airis vision align reference.jpg floating.jpg

                HOW IT WORKS:
                  Image registration finds the best alignment transform between two images.
                  The reference image is the target, and the floating image is transformed to match it.
                  Returns the affine transform (translation, rotation, scale) needed to align them.

                EXAMPLES:
                  # Basic alignment
                  airis vision align reference.png floating.png

                  # Save aligned image
                  airis vision align ref.jpg target.jpg -o aligned.png

                  # JSON output for scripting
                  airis vision align ref.jpg target.jpg --format json

                OUTPUT EXAMPLE:
                  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  Image Alignment
                  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  Reference: reference.jpg
                  Floating:  floating.jpg
                  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

                  Alignment Transform:
                    Translation X: 12.5 px
                    Translation Y: -8.3 px

                REQUIREMENTS:
                  Both images should have the same dimensions for best results.
                  Works best with images that have overlapping content.

                NOTE:
                  This uses translational registration (shifts only).
                  For perspective transforms, consider homographic registration.
                """,
            cn: """
                计算将“floating”图片对齐到“reference”图片所需的变换参数（当前实现为平移对齐）。

                QUICK START:
                  airis vision align reference.jpg floating.jpg

                EXAMPLES:
                  # 基础对齐
                  airis vision align reference.png floating.png

                  # 保存对齐后的图片
                  airis vision align ref.jpg target.jpg -o aligned.png

                  # JSON 输出（便于脚本解析）
                  airis vision align ref.jpg target.jpg --format json

                说明：
                  - 两张图尺寸一致、且内容有重叠时效果最佳
                """
        )
    )

    @Argument(help: HelpTextFactory.help(en: "Reference image (alignment target)", cn: "参考图（对齐目标）"))
    var reference: String

    @Argument(help: HelpTextFactory.help(en: "Floating image (to be aligned)", cn: "待对齐图片（将被变换）"))
    var floating: String

    @Option(name: [.short, .long], help: HelpTextFactory.help(en: "Output aligned image path", cn: "输出对齐后图片路径"))
    var output: String?

    @Option(name: .long, help: HelpTextFactory.help(en: "Output format (table, json)", cn: "输出格式（table / json）"))
    var format: String = "table"

    func run() async throws {
        let referenceURL = try FileUtils.validateImageFile(at: reference)
        let floatingURL = try FileUtils.validateImageFile(at: floating)
        let outputFormat = OutputFormat.parse(format)
        let showHumanOutput = AirisOutput.shouldPrintHumanOutput(format: outputFormat)

        if showHumanOutput {
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("🔗 Image Alignment")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("📁 Reference: \(referenceURL.lastPathComponent)")
            print("📁 Floating:  \(floatingURL.lastPathComponent)")
            if let output = output {
                print("💾 Output: \(output)")
            }
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("")
            print("⏳ Computing alignment...")
        }

        let result: VisionService.ImageAlignmentResult
        #if DEBUG
        if ProcessInfo.processInfo.environment["AIRIS_TEST_ALIGN_FAKE_RESULT"] == "1" {
            result = Self.testAlignmentResult()
        } else {
            let vision = ServiceContainer.shared.visionService
            result = try await vision.computeImageAlignment(
                referenceURL: referenceURL,
                floatingURL: floatingURL
            )
        }
        #else
        let vision = ServiceContainer.shared.visionService
        result = try await vision.computeImageAlignment(
            referenceURL: referenceURL,
            floatingURL: floatingURL
        )
        #endif

        if outputFormat == .json {
            printJSON(
                result: result,
                reference: referenceURL.lastPathComponent,
                floating: floatingURL.lastPathComponent
            )
        } else if showHumanOutput {
            print("")
            print("✅ Alignment computed")
            print("")
            print("Alignment Transform:")
            print("  Translation X: \(String(format: "%.2f", result.translationX)) px")
            print("  Translation Y: \(String(format: "%.2f", result.translationY)) px")

            // Calculate magnitude
            let magnitude = sqrt(result.translationX * result.translationX + result.translationY * result.translationY)
            print("  Magnitude: \(String(format: "%.2f", magnitude)) px")
        }

        // Save aligned image if requested
        if let outputPath = output {
            try saveAlignedImage(
                floatingURL: floatingURL,
                transform: result.transform,
                to: outputPath
            )
            if showHumanOutput {
                print("")
                print(Strings.get("info.saved_to", outputPath))
            }
        }
    }

    private func printJSON(
        result: VisionService.ImageAlignmentResult,
        reference: String,
        floating: String
    ) {
        let magnitude = sqrt(result.translationX * result.translationX + result.translationY * result.translationY)

        let dict: [String: Any] = [
            "reference": reference,
            "floating": floating,
            "transform": [
                "translation_x": result.translationX,
                "translation_y": result.translationY,
                "magnitude": magnitude,
                "matrix": [
                    "a": result.transform.a,
                    "b": result.transform.b,
                    "c": result.transform.c,
                    "d": result.transform.d,
                    "tx": result.transform.tx,
                    "ty": result.transform.ty
                ]
            ]
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    }

    private func saveAlignedImage(floatingURL: URL, transform: CGAffineTransform, to outputPath: String) throws {
        let coreImage = ServiceContainer.shared.coreImageService
        let imageIO = ServiceContainer.shared.imageIOService

        // Load the floating image
        let cgImage = try imageIO.loadImage(at: floatingURL)
        let ciImage = CIImage(cgImage: cgImage)

        // Apply the alignment transform
        let alignedImage = ciImage.transformed(by: transform)

        // Render
        #if DEBUG
        let forceNil = ProcessInfo.processInfo.environment["AIRIS_FORCE_ALIGN_RENDER_NIL"] == "1"
        let renderedImage = forceNil ? nil : coreImage.render(ciImage: alignedImage)
        #else
        let renderedImage = coreImage.render(ciImage: alignedImage)
        #endif

        guard let outputCGImage = renderedImage else {
            throw AirisError.imageEncodeFailed
        }

        // Save
        let outputURL = URL(fileURLWithPath: outputPath)
        try FileUtils.ensureDirectory(for: outputPath)

        let format = outputPath.hasSuffix(".png") ? "png" : "jpg"
        try imageIO.saveImage(outputCGImage, to: outputURL, format: format)
    }

    #if DEBUG
    /// 测试桩：固定的平移矩阵，避免依赖 Vision 实际计算
    private static func testAlignmentResult() -> VisionService.ImageAlignmentResult {
        let transform = CGAffineTransform(translationX: 3, y: -2)
        return VisionService.ImageAlignmentResult(
            transform: transform,
            translationX: transform.tx,
            translationY: transform.ty
        )
    }
    #endif
}
