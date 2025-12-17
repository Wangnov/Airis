import ArgumentParser
import Foundation
import AppKit

struct FlipCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "flip",
        abstract: HelpTextFactory.text(
            en: "Flip image horizontally or vertically",
            cn: "翻转图片（水平/垂直）"
        ),
        discussion: helpDiscussion(
            en: """
                Flip (mirror) the image horizontally and/or vertically.

                OPTIONS:
                  --horizontal, -h   Flip horizontally (left-right mirror)
                  --vertical, -v     Flip vertically (top-bottom mirror)

                At least one flip direction must be specified.
                Both can be specified for 180-degree rotation effect.

                QUICK START:
                  airis edit adjust flip photo.jpg --horizontal -o flipped.jpg

                EXAMPLES:
                  # Horizontal flip (mirror)
                  airis edit adjust flip selfie.jpg --horizontal -o mirrored.jpg

                  # Vertical flip
                  airis edit adjust flip photo.jpg --vertical -o flipped_v.jpg

                  # Both horizontal and vertical (180 degree rotation)
                  airis edit adjust flip image.png --horizontal --vertical -o rotated180.png

                  # Short form
                  airis edit adjust flip photo.jpg -h -o mirror.jpg
                """,
            cn: """
                水平/垂直镜像翻转图片。

                QUICK START:
                  airis edit adjust flip photo.jpg --horizontal -o flipped.jpg

                EXAMPLES:
                  # 水平翻转（镜像）
                  airis edit adjust flip selfie.jpg --horizontal -o mirrored.jpg

                  # 垂直翻转
                  airis edit adjust flip photo.jpg --vertical -o flipped_v.jpg

                  # 同时水平+垂直（等价 180°）
                  airis edit adjust flip image.png --horizontal --vertical -o rotated180.png
                """
        )
    )

    @Argument(help: HelpTextFactory.help(en: "Input image path", cn: "输入图片路径"))
    var input: String

    @Option(name: [.short, .long], help: HelpTextFactory.help(en: "Output path", cn: "输出路径"))
    var output: String

    @Flag(name: [.customShort("h"), .long], help: HelpTextFactory.help(en: "Flip horizontally (left-right)", cn: "水平翻转（左右镜像）"))
    var horizontal: Bool = false

    @Flag(name: [.customShort("v"), .long], help: HelpTextFactory.help(en: "Flip vertically (top-bottom)", cn: "垂直翻转（上下镜像）"))
    var vertical: Bool = false

    @Option(name: .long, help: HelpTextFactory.help(en: "Output quality for JPEG/HEIC (0.0-1.0)", cn: "输出质量（JPEG/HEIC：0.0-1.0）"))
    var quality: Float = 0.9

    @Flag(name: .long, help: HelpTextFactory.help(en: "Open result after processing", cn: "处理完成后打开输出文件"))
    var open: Bool = false

    @Flag(name: .long, help: HelpTextFactory.help(en: "Overwrite existing output file", cn: "覆盖已存在的输出文件"))
    var force: Bool = false

    func run() async throws {
        // 参数验证
        guard horizontal || vertical else {
            throw AirisError.invalidPath("Must specify --horizontal (-h) and/or --vertical (-v)")
        }

        let inputURL = try FileUtils.validateImageFile(at: input)
        let outputURL = URL(fileURLWithPath: FileUtils.absolutePath(output))
        let outputFormat = FileUtils.getExtension(from: output).lowercased()

        // 检查输出文件是否已存在
        if FileManager.default.fileExists(atPath: outputURL.path) && !force {
            throw AirisError.invalidPath("Output file already exists. Use --force to overwrite: \(output)")
        }

        // 确保输出目录存在
        try FileUtils.ensureDirectory(for: outputURL.path)

        // 确定翻转类型描述
        let flipType: String
        if horizontal && vertical {
            flipType = Strings.get("edit.adjust.flip.both")
        } else if horizontal {
            flipType = Strings.get("edit.adjust.flip.horizontal")
        } else {
            flipType = Strings.get("edit.adjust.flip.vertical")
        }

        // 显示处理信息
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔄 " + Strings.get("edit.adjust.flip.title"))
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 " + Strings.get("edit.input") + ": \(inputURL.lastPathComponent)")
        print("💾 " + Strings.get("edit.output") + ": \(output)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        print("↔️  " + Strings.get("edit.adjust.flip.direction") + ": \(flipType)")
        print("")
        print("⏳ " + Strings.get("info.processing"))

        // 应用翻转效果
        let coreImage = ServiceContainer.shared.coreImageService

        try coreImage.applyAndSave(
            inputURL: inputURL,
            outputURL: outputURL,
            format: outputFormat,
            quality: quality
        ) { ciImage in
            coreImage.flip(ciImage: ciImage, horizontal: horizontal, vertical: vertical)
        }

        print("")
        print("✅ " + Strings.get("info.saved_to", output))

        if let fileSize = FileUtils.getFormattedFileSize(at: outputURL.path) {
            print("📦 " + Strings.get("info.file_size", fileSize))
        }

        // 打开结果
        if open {
            NSWorkspace.openForCLI(outputURL)
        }
    }
}
