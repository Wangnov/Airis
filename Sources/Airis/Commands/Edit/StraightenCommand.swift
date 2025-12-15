import ArgumentParser
import Foundation
import AppKit

struct StraightenCommand: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
        commandName: "straighten",
        abstract: HelpTextFactory.text(
            en: "Automatically straighten tilted images",
            cn: "自动拉直倾斜的图片"
        ),
        discussion: helpDiscussion(
            en: """
                Detect and correct image tilt using horizon detection.
                Automatically finds the horizon line and rotates to level.

                QUICK START:
                  airis edit straighten tilted.jpg -o straight.jpg

                EXAMPLES:
                  # Auto-straighten a photo
                  airis edit straighten landscape.jpg -o leveled.jpg

                  # Straighten and open result
                  airis edit straighten photo.png -o corrected.png --open

                  # Manual angle override (in degrees, positive = counterclockwise)
                  airis edit straighten image.jpg --angle 2.5 -o fixed.jpg

                PARAMETERS:
                  --angle: Manual rotation angle in degrees (overrides auto-detection)

                OUTPUT:
                  Rotated image with corrected horizon

                NOTE:
                  Works best with images containing clear horizon lines or
                  strong horizontal/vertical features.
                """,
            cn: """
                通过地平线/水平线检测自动校正照片倾斜角度，并旋转到水平。

                QUICK START:
                  airis edit straighten tilted.jpg -o straight.jpg

                EXAMPLES:
                  # 自动拉直
                  airis edit straighten landscape.jpg -o leveled.jpg

                  # 拉直并自动打开
                  airis edit straighten photo.png -o corrected.png --open

                  # 手动指定角度（度；正数=逆时针）
                  airis edit straighten image.jpg --angle 2.5 -o fixed.jpg

                PARAMETERS:
                  --angle: 手动旋转角度（将覆盖自动检测结果）

                OUTPUT:
                  输出为已校正地平线的旋转图片

                NOTE:
                  对包含明显地平线，或有明显水平/垂直结构的图片效果更好。
                """
        )
    )
    }

    @Argument(help: HelpTextFactory.help(en: "Input image path", cn: "输入图片路径"))
    var input: String

    @Option(name: [.short, .long], help: HelpTextFactory.help(en: "Output path", cn: "输出路径"))
    var output: String

    @Option(name: .long, help: HelpTextFactory.help(en: "Manual rotation angle in degrees (overrides auto-detection)", cn: "手动旋转角度（度，将覆盖自动检测）"))
    var angle: Double?

    @Flag(name: .long, help: HelpTextFactory.help(en: "Open result after processing", cn: "处理完成后打开输出文件"))
    var open: Bool = false

    @Flag(name: .long, help: HelpTextFactory.help(en: "Overwrite existing output file", cn: "覆盖已存在的输出文件"))
    var force: Bool = false

    func run() async throws {
        let inputURL = try FileUtils.validateImageFile(at: input)
        let outputURL = URL(fileURLWithPath: FileUtils.absolutePath(output))

        // 检查输出文件是否已存在
        if FileManager.default.fileExists(atPath: outputURL.path) && !force {
            throw AirisError.invalidPath("Output file already exists. Use --force to overwrite: \(output)")
        }

        // 确保输出目录存在
        try FileUtils.ensureDirectory(for: outputURL.path)

        // 显示处理信息
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📐 " + Strings.get("edit.straighten.title"))
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 " + Strings.get("edit.input") + ": \(inputURL.lastPathComponent)")
        print("💾 " + Strings.get("edit.output") + ": \(output)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")

        var rotationAngle: Double

        if let manualAngle = angle {
            // 使用手动指定的角度
            rotationAngle = manualAngle
            print("📐 " + Strings.get("edit.straighten.manual", String(format: "%.2f", rotationAngle)))
        } else {
            // 自动检测倾斜角度
            print("⏳ " + Strings.get("edit.straighten.detecting"))

            let vision = ServiceContainer.shared.visionService
            let horizon = try await vision.detectHorizon(at: inputURL)
            let forceNoHorizon = ProcessInfo.processInfo.environment["AIRIS_FORCE_STRAIGHTEN_NO_HORIZON"] == "1"
            let forceZeroAngle = ProcessInfo.processInfo.environment["AIRIS_FORCE_STRAIGHTEN_ZERO"] == "1"

            if let h = horizon, !forceNoHorizon {
                rotationAngle = forceZeroAngle ? 0 : Double(h.angleInDegrees)

                if abs(rotationAngle) < 0.1 {
                    print("✓ " + Strings.get("edit.straighten.already_level"))
                } else {
                    print("✓ " + Strings.get("edit.straighten.detected", String(format: "%.2f", rotationAngle)))
                }
            } else {
                print("⚠️ " + Strings.get("edit.straighten.no_horizon"))
                // 无法检测到地平线，不进行旋转
                rotationAngle = 0
            }
        }

        print("⏳ " + Strings.get("edit.straighten.rotating"))

        // 加载图像
        let imageIO = ServiceContainer.shared.imageIOService
        let cgImage = try imageIO.loadImage(at: inputURL)
        let ciImage = CIImage(cgImage: cgImage)

        // 应用旋转校正
        let coreImage = ServiceContainer.shared.coreImageService

        // 注意：地平线角度是图像倾斜的角度，需要反向旋转来校正
        let corrected = coreImage.rotateAroundCenter(ciImage: ciImage, degrees: -rotationAngle)

        // 渲染并保存
#if DEBUG
        let forceNil = ProcessInfo.processInfo.environment["AIRIS_FORCE_STRAIGHTEN_RENDER_NIL"] == "1"
        let rendered = forceNil ? nil : coreImage.render(ciImage: corrected)
#else
        let rendered = coreImage.render(ciImage: corrected)
#endif

        guard let outputCGImage = rendered else {
            throw AirisError.imageEncodeFailed
        }

        let outputFormat = FileUtils.getExtension(from: output)
        try imageIO.saveImage(outputCGImage, to: outputURL, format: outputFormat)

        print("")
        print("✅ " + Strings.get("info.saved_to", output))

        // 显示旋转信息
        if abs(rotationAngle) >= 0.1 {
            print("🔄 " + Strings.get("edit.straighten.rotated", String(format: "%.2f", -rotationAngle)))
        }

        // 显示文件大小
        if let fileSize = FileUtils.getFormattedFileSize(at: outputURL.path) {
            print("📦 " + Strings.get("info.file_size", fileSize))
        }

        // 打开结果
        if open {
            NSWorkspace.openForCLI(outputURL)
        }
    }
}
