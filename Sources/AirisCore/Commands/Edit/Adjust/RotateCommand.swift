import ArgumentParser
import Foundation
import AppKit

struct RotateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "rotate",
        abstract: HelpTextFactory.text(
            en: "Rotate image by specified angle",
            cn: "按角度旋转图片"
        ),
        discussion: helpDiscussion(
            en: """
                Rotate the image by any angle (clockwise positive).
                The output canvas expands to contain the entire rotated image.

                PARAMETERS:
                  Angle: Any value in degrees (positive = clockwise)
                         Common values: 90, 180, 270, -90

                QUICK START:
                  airis edit adjust rotate photo.jpg --angle 90 -o rotated.jpg

                EXAMPLES:
                  # Rotate 90 degrees clockwise
                  airis edit adjust rotate photo.jpg --angle 90 -o rotated.jpg

                  # Rotate 90 degrees counter-clockwise
                  airis edit adjust rotate photo.jpg --angle -90 -o rotated_ccw.jpg

                  # Rotate 180 degrees (upside down)
                  airis edit adjust rotate image.png --angle 180 -o flipped.png

                  # Slight rotation correction (straighten)
                  airis edit adjust rotate tilted.jpg --angle 2.5 -o straightened.jpg

                  # Arbitrary angle rotation
                  airis edit adjust rotate art.png --angle 45 -o diagonal.png

                NOTE:
                  - The image canvas expands to fit the rotated content
                  - No pixels are cropped during rotation
                  - For non-90-degree rotations, corners will extend the canvas
                  - Transparent areas (for PNG) or white areas (for JPEG) fill gaps

                OUTPUT:
                  Supports PNG, JPEG, HEIC, TIFF output formats.
                  Format is determined by output file extension.
                """,
            cn: """
                按指定角度旋转图片（正数为顺时针），输出画布会自动扩展以容纳完整旋转后的内容（不裁剪）。

                QUICK START:
                  airis edit adjust rotate photo.jpg --angle 90 -o rotated.jpg

                EXAMPLES:
                  # 顺时针 90°
                  airis edit adjust rotate photo.jpg --angle 90 -o rotated.jpg

                  # 逆时针 90°
                  airis edit adjust rotate photo.jpg --angle -90 -o rotated_ccw.jpg

                  # 轻微矫正（拉直）
                  airis edit adjust rotate tilted.jpg --angle 2.5 -o straightened.jpg
                """
        )
    )

    @Argument(help: HelpTextFactory.help(en: "Input image path", cn: "输入图片路径"))
    var input: String

    @Option(name: [.short, .long], help: HelpTextFactory.help(en: "Output path", cn: "输出路径"))
    var output: String

    @Option(name: .long, help: HelpTextFactory.help(en: "Rotation angle in degrees (positive = clockwise)", cn: "旋转角度（度；正数为顺时针）"))
    var angle: Double

    @Option(name: .long, help: HelpTextFactory.help(en: "Output quality for JPEG/HEIC (0.0-1.0)", cn: "输出质量（JPEG/HEIC：0.0-1.0）"))
    var quality: Float = 0.9

    @Flag(name: .long, help: HelpTextFactory.help(en: "Open result after processing", cn: "处理完成后打开输出文件"))
    var open: Bool = false

    @Flag(name: .long, help: HelpTextFactory.help(en: "Overwrite existing output file", cn: "覆盖已存在的输出文件"))
    var force: Bool = false

    func run() async throws {
        let inputURL = try FileUtils.validateImageFile(at: input)
        let outputURL = URL(fileURLWithPath: FileUtils.absolutePath(output))
        let outputFormat = FileUtils.getExtension(from: output).lowercased()

        // 检查输出文件是否已存在
        if FileManager.default.fileExists(atPath: outputURL.path) && !force {
            throw AirisError.invalidPath("Output file already exists. Use --force to overwrite: \(output)")
        }

        // 确保输出目录存在
        try FileUtils.ensureDirectory(for: outputURL.path)

        // 规范化角度显示
        let normalizedAngle = angle.truncatingRemainder(dividingBy: 360)
        let direction = angle >= 0 ? "clockwise" : "counter-clockwise"

        // 显示处理信息
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔃 " + Strings.get("edit.adjust.rotate.title"))
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 " + Strings.get("edit.input") + ": \(inputURL.lastPathComponent)")
        print("💾 " + Strings.get("edit.output") + ": \(output)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        print("📐 " + Strings.get("edit.adjust.angle") + ": \(String(format: "%.1f", normalizedAngle))° (\(direction))")
        print("")
        print("⏳ " + Strings.get("info.processing"))

        // 获取原始图像信息
        let imageIO = ServiceContainer.shared.imageIOService
        let imageInfo = try imageIO.getImageInfo(at: inputURL)

        // 应用旋转效果
        let coreImage = ServiceContainer.shared.coreImageService

        try coreImage.applyAndSave(
            inputURL: inputURL,
            outputURL: outputURL,
            format: outputFormat,
            quality: quality
        ) { ciImage in
            coreImage.rotateAroundCenter(ciImage: ciImage, degrees: angle)
        }

        print("")
        print("✅ " + Strings.get("info.saved_to", output))

        // 显示输出图像信息
        let outputInfo = try imageIO.getImageInfo(at: outputURL)
        print("📏 " + Strings.get("edit.resize.original") + ": \(imageInfo.width) × \(imageInfo.height)")
        print("📐 " + Strings.get("edit.resize.result") + ": \(outputInfo.width) × \(outputInfo.height)")

        if let fileSize = FileUtils.getFormattedFileSize(at: outputURL.path) {
            print("📦 " + Strings.get("info.file_size", fileSize))
        }

        // 打开结果
        if open {
            NSWorkspace.openForCLI(outputURL)
        }
    }
}
