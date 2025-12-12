import ArgumentParser
import Foundation
import AppKit

struct NoiseCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "noise",
        abstract: "Reduce noise in images",
        discussion: """
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
            """
    )

    @Argument(help: "Input image path")
    var input: String

    @Option(name: [.short, .long], help: "Output path")
    var output: String

    @Option(name: .long, help: "Noise level (0-0.1, default: 0.02)")
    var level: Double = 0.02

    @Option(name: .long, help: "Sharpness preservation (0-2, default: 0.4)")
    var sharpness: Double = 0.4

    @Flag(name: .long, help: "Open result after processing")
    var open: Bool = false

    @Flag(name: .long, help: "Overwrite existing output file")
    var force: Bool = false

    func run() async throws {
        // 验证噪声级别参数
        guard level >= 0 && level <= 0.1 else {
            throw AirisError.invalidPath("Noise level must be 0-0.1, got: \(level)")
        }

        // 验证锐度参数
        guard sharpness >= 0 && sharpness <= 2 else {
            throw AirisError.invalidPath("Sharpness must be 0-2, got: \(sharpness)")
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
