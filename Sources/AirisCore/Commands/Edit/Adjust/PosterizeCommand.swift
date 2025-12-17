import ArgumentParser
import Foundation
import AppKit

struct PosterizeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "posterize",
        abstract: HelpTextFactory.text(
            en: "Reduce color levels (poster effect)",
            cn: "色调分离（海报效果）"
        ),
        discussion: helpDiscussion(
            en: """
                Apply posterization effect using CIColorPosterize filter.
                Reduces the number of color levels, creating a poster-like appearance.

                PARAMETERS:
                  Levels: 2 to 30 (default: 6)
                          Lower values = fewer colors = more dramatic effect
                          Higher values = more colors = subtler effect

                QUICK START:
                  airis edit adjust posterize photo.jpg --levels 4 -o poster.jpg

                EXAMPLES:
                  # Strong poster effect (4 levels per channel)
                  airis edit adjust posterize photo.jpg --levels 4 -o poster.jpg

                  # Minimal posterization (2 levels = very graphic)
                  airis edit adjust posterize art.png --levels 2 -o graphic.png

                  # Subtle posterization (8 levels)
                  airis edit adjust posterize photo.jpg --levels 8 -o subtle.jpg

                  # Medium effect with PNG output
                  airis edit adjust posterize image.jpg --levels 6 -o medium.png

                OUTPUT:
                  Supports PNG, JPEG, HEIC, TIFF output formats.
                  Format is determined by output file extension.
                """,
            cn: """
                使用 CIColorPosterize 减少色阶数量，形成海报/波普风格的色调分离效果。

                参数范围：
                  levels: 2 ~ 30（默认：6；越小越夸张）

                QUICK START:
                  airis edit adjust posterize photo.jpg --levels 4 -o poster.jpg

                EXAMPLES:
                  airis edit adjust posterize art.png --levels 2 -o graphic.png
                  airis edit adjust posterize photo.jpg --levels 8 -o subtle.jpg
                """
        )
    )

    @Argument(help: HelpTextFactory.help(en: "Input image path", cn: "输入图片路径"))
    var input: String

    @Option(name: [.short, .long], help: HelpTextFactory.help(en: "Output path", cn: "输出路径"))
    var output: String

    @Option(name: .long, help: HelpTextFactory.help(en: "Number of color levels per channel (2 to 30, default: 6)", cn: "每通道色阶数（2~30，默认：6）"))
    var levels: Double = 6.0

    @Option(name: .long, help: HelpTextFactory.help(en: "Output quality for JPEG/HEIC (0.0-1.0)", cn: "输出质量（JPEG/HEIC：0.0-1.0）"))
    var quality: Float = 0.9

    @Flag(name: .long, help: HelpTextFactory.help(en: "Open result after processing", cn: "处理完成后打开输出文件"))
    var open: Bool = false

    @Flag(name: .long, help: HelpTextFactory.help(en: "Overwrite existing output file", cn: "覆盖已存在的输出文件"))
    var force: Bool = false

    func run() async throws {
        // 参数验证
        guard levels >= 2 && levels <= 30 else {
            throw AirisError.invalidPath("Levels must be 2 to 30, got: \(levels)")
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

        // 显示处理信息
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🎭 " + Strings.get("edit.adjust.posterize.title"))
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 " + Strings.get("edit.input") + ": \(inputURL.lastPathComponent)")
        print("💾 " + Strings.get("edit.output") + ": \(output)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        print("🎨 " + Strings.get("edit.adjust.levels") + ": \(Int(levels))")
        print("")
        print("⏳ " + Strings.get("info.processing"))

        // 应用色调分离效果
        let coreImage = ServiceContainer.shared.coreImageService

        try coreImage.applyAndSave(
            inputURL: inputURL,
            outputURL: outputURL,
            format: outputFormat,
            quality: quality
        ) { ciImage in
            coreImage.posterize(ciImage: ciImage, levels: levels)
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
