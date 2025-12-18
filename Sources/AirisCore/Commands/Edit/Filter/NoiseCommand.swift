import AppKit
import ArgumentParser
import Foundation

struct NoiseCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "noise",
        abstract: HelpTextFactory.text(
            en: "Reduce noise in images",
            cn: "降噪"
        ),
        discussion: helpDiscussion(
            en: """
            Apply noise reduction to images using CoreImage's noise reduction filter.

            Reduces digital noise (grain) while attempting to preserve image sharpness.
            Best for photos taken in low light or at high ISO settings.

            PARAMETERS:
              --level:     Noise level estimation (0-0.1, default: 0.02)
                           Higher values = more aggressive noise reduction
              --sharpness: Edge sharpness preservation (0-2, default: 0.4)
                           Higher values = more detail preserved but more noise remains

            QUICK START:
              airis edit filter noise photo.jpg -o denoised.png

            EXAMPLES:
              # Default noise reduction
              airis edit filter noise noisy.jpg -o clean.png

              # Aggressive noise reduction (may lose some detail)
              airis edit filter noise noisy.jpg --level 0.05 --sharpness 0.2 -o smooth.png

              # Gentle noise reduction (preserve detail)
              airis edit filter noise photo.jpg --level 0.01 --sharpness 0.6 -o gentle.png

              # Heavy noise reduction for very noisy images
              airis edit filter noise highiso.jpg --level 0.08 -o cleaned.png

            OUTPUT:
              Denoised image in the specified format
            """,
            cn: """
            使用 Core Image 降噪滤镜减少图片噪点（颗粒），并尽量保留边缘细节。

            QUICK START:
              airis edit filter noise photo.jpg -o denoised.png

            EXAMPLES:
              # 更强降噪（可能损失细节）
              airis edit filter noise noisy.jpg --level 0.05 --sharpness 0.2 -o smooth.png

              # 更温和降噪（保留细节）
              airis edit filter noise photo.jpg --level 0.01 --sharpness 0.6 -o gentle.png
            """
        )
    )

    @Argument(help: HelpTextFactory.help(en: "Input image path", cn: "输入图片路径"))
    var input: String

    @Option(name: [.short, .long], help: HelpTextFactory.help(en: "Output path", cn: "输出路径"))
    var output: String

    @Option(name: .long, help: HelpTextFactory.help(en: "Noise level (0-0.1, default: 0.02)", cn: "噪声水平（0-0.1，默认：0.02）"))
    var level: Double = 0.02

    @Option(name: .long, help: HelpTextFactory.help(en: "Sharpness preservation (0-2, default: 0.4)", cn: "细节保留（0-2，默认：0.4）"))
    var sharpness: Double = 0.4

    @Flag(name: .long, help: HelpTextFactory.help(en: "Open result after processing", cn: "处理完成后打开输出文件"))
    var open: Bool = false

    @Flag(name: .long, help: HelpTextFactory.help(en: "Overwrite existing output file", cn: "覆盖已存在的输出文件"))
    var force: Bool = false

    func run() async throws {
        // 验证噪声级别参数
        guard level >= 0, level <= 0.1 else {
            throw AirisError.invalidPath("Noise level must be 0-0.1, got: \(level)")
        }

        // 验证锐度参数
        guard sharpness >= 0, sharpness <= 2 else {
            throw AirisError.invalidPath("Sharpness must be 0-2, got: \(sharpness)")
        }

        let inputURL = try FileUtils.validateImageFile(at: input)
        let outputURL = URL(fileURLWithPath: FileUtils.absolutePath(output))

        // 检查输出文件是否已存在
        if FileManager.default.fileExists(atPath: outputURL.path), !force {
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
        print("🔇 " + Strings.get("filter.noise.title"))
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 " + Strings.get("edit.input") + ": \(inputURL.lastPathComponent)")
        print("📊 " + Strings.get("filter.noise.level") + ": \(level)")
        print("🔪 " + Strings.get("filter.noise.sharpness") + ": \(sharpness)")
        print("💾 " + Strings.get("edit.output") + ": \(output)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        print("⏳ " + Strings.get("info.processing"))

        // 应用滤镜
        let coreImage = ServiceContainer.shared.coreImageService

        #if DEBUG
            if ProcessInfo.processInfo.environment["AIRIS_FORCE_NOISE_RENDER_FAIL"] == "1" {
                throw AirisError.imageEncodeFailed
            }
        #endif

        try coreImage.applyAndSave(
            inputURL: inputURL,
            outputURL: outputURL,
            format: outputFormat == "jpeg" ? "jpg" : outputFormat,
            filterBlock: { ciImage in
                coreImage.noiseReduction(ciImage: ciImage, noiseLevel: level, sharpness: sharpness)
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
