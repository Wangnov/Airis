import ArgumentParser
import Foundation
import AppKit

struct PixelCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pixel",
        abstract: HelpTextFactory.text(
            en: "Pixelate images",
            cn: "马赛克像素化（Pixelate）"
        ),
        discussion: helpDiscussion(
            en: """
                Apply pixelation effect to images using CoreImage.

                Creates a mosaic/pixelated appearance by grouping pixels into larger blocks.
                Useful for privacy (blurring faces/info) or creating retro/8-bit style effects.

                PARAMETERS:
                  --scale: Pixel block size (1-100, default: 8)
                           1 = no effect, larger = more pixelated

                QUICK START:
                  airis edit filter pixel photo.jpg -o pixelated.png

                EXAMPLES:
                  # Default pixelation (8px blocks)
                  airis edit filter pixel photo.jpg -o pixelated.png

                  # Stronger pixelation for privacy
                  airis edit filter pixel face.jpg --scale 20 -o blurred_face.png

                  # Retro 8-bit style (large blocks)
                  airis edit filter pixel photo.jpg --scale 32 -o retro.png

                  # Subtle pixelation
                  airis edit filter pixel photo.jpg --scale 4 -o subtle.png

                OUTPUT:
                  Pixelated image in the specified format
                """,
            cn: """
                使用 Core Image 将图片像素化/马赛克化（常用于隐私遮挡或复古风格）。

                QUICK START:
                  airis edit filter pixel photo.jpg -o pixelated.png

                EXAMPLES:
                  # 更强马赛克
                  airis edit filter pixel face.jpg --scale 20 -o blurred_face.png

                  # 更细马赛克
                  airis edit filter pixel photo.jpg --scale 4 -o subtle.png
                """
        )
    )

    @Argument(help: HelpTextFactory.help(en: "Input image path", cn: "输入图片路径"))
    var input: String

    @Option(name: [.short, .long], help: HelpTextFactory.help(en: "Output path", cn: "输出路径"))
    var output: String

    @Option(name: .long, help: HelpTextFactory.help(en: "Pixel block size (1-100, default: 8)", cn: "像素块大小（1-100，默认：8）"))
    var scale: Double = 8

    @Flag(name: .long, help: HelpTextFactory.help(en: "Open result after processing", cn: "处理完成后打开输出文件"))
    var open: Bool = false

    @Flag(name: .long, help: HelpTextFactory.help(en: "Overwrite existing output file", cn: "覆盖已存在的输出文件"))
    var force: Bool = false

    func run() async throws {
        // 验证缩放参数
        guard scale >= 1 && scale <= 100 else {
            throw AirisError.invalidPath("Scale must be 1-100, got: \(scale)")
        }

        let inputURL = try FileUtils.validateImageFile(at: input)
        let outputURL = URL(fileURLWithPath: FileUtils.absolutePath(output))

        // 检查输出文件是否已存在
        if FileManager.default.fileExists(atPath: outputURL.path) && !force {
            throw AirisError.invalidPath("Output file already exists. Use --force to overwrite: \(output)")
        }

        // 确保输出目录存在
        try FileUtils.ensureDirectory(for: outputURL.path)

        // 获取输出格式
        let outputFormat = FileUtils.getExtension(from: output).lowercased()
        let supportedFormats = ["png", "jpg", "jpeg", "heic", "tiff"]
        guard supportedFormats.contains(outputFormat) else {
            throw AirisError.unsupportedFormat("Unsupported output format: .\(outputFormat). Use: \(supportedFormats.joined(separator: ", "))")
        }

        // 显示处理信息
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🧱 " + Strings.get("filter.pixel.title"))
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 " + Strings.get("edit.input") + ": \(inputURL.lastPathComponent)")
        print("📏 " + Strings.get("filter.pixel.scale") + ": \(Int(scale))px")
        print("💾 " + Strings.get("edit.output") + ": \(output)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        print("⏳ " + Strings.get("info.processing"))

        // 应用滤镜
        let coreImage = ServiceContainer.shared.coreImageService

        try coreImage.applyAndSave(
            inputURL: inputURL,
            outputURL: outputURL,
            format: outputFormat == "jpeg" ? "jpg" : outputFormat,
            filterBlock: { ciImage in
                coreImage.pixellate(ciImage: ciImage, scale: scale)
            }
        )

        print("")
        print("✅ " + Strings.get("info.saved_to", output))

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
