import AppKit
import ArgumentParser
import Foundation

struct InvertCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "invert",
        abstract: HelpTextFactory.text(
            en: "Invert image colors (negative effect)",
            cn: "反相（负片效果）"
        ),
        discussion: helpDiscussion(
            en: """
            Invert all colors in the image using CIColorInvert filter.
            Creates a negative/inverse effect where each color becomes its opposite.

            QUICK START:
              airis edit adjust invert photo.jpg -o inverted.jpg

            EXAMPLES:
              # Basic color inversion
              airis edit adjust invert photo.jpg -o inverted.jpg

              # Invert and open result
              airis edit adjust invert artwork.png -o negative.png --open

              # Invert to HEIC format
              airis edit adjust invert image.jpg -o inverted.heic

            EFFECT:
              - White becomes black, black becomes white
              - Red becomes cyan, green becomes magenta
              - Blue becomes yellow, and vice versa
              - Each RGB value becomes (255 - original)

            USE CASES:
              - Creating negative film effects
              - Artistic image manipulation
              - Accessibility (some users prefer inverted colors)
              - X-ray style effects

            OUTPUT:
              Supports PNG, JPEG, HEIC, TIFF output formats.
              Format is determined by output file extension.
            """,
            cn: """
            使用 CIColorInvert 将图片颜色反相，生成负片效果。

            QUICK START:
              airis edit adjust invert photo.jpg -o inverted.jpg

            EXAMPLES:
              airis edit adjust invert artwork.png -o negative.png --open
            """
        )
    )

    @Argument(help: HelpTextFactory.help(en: "Input image path", cn: "输入图片路径"))
    var input: String

    @Option(name: [.short, .long], help: HelpTextFactory.help(en: "Output path", cn: "输出路径"))
    var output: String

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
        if FileManager.default.fileExists(atPath: outputURL.path), !force {
            throw AirisError.invalidPath("Output file already exists. Use --force to overwrite: \(output)")
        }

        // 确保输出目录存在
        try FileUtils.ensureDirectory(for: outputURL.path)

        // 显示处理信息
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔄 " + Strings.get("edit.adjust.invert.title"))
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 " + Strings.get("edit.input") + ": \(inputURL.lastPathComponent)")
        print("💾 " + Strings.get("edit.output") + ": \(output)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        print("⏳ " + Strings.get("info.processing"))

        // 应用反色效果
        let coreImage = ServiceContainer.shared.coreImageService

        try coreImage.applyAndSave(
            inputURL: inputURL,
            outputURL: outputURL,
            format: outputFormat,
            quality: quality
        ) { ciImage in
            coreImage.invert(ciImage: ciImage)
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
