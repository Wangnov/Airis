import ArgumentParser
import Foundation
import AppKit

struct SepiaCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "sepia",
        abstract: "Apply sepia tone effect",
        discussion: """
            Apply vintage sepia tone effect to images using CoreImage.

            Creates a warm, brownish tint reminiscent of old photographs.
            Adjustable intensity allows for subtle aging to full antique look.

            PARAMETERS:
              --intensity: Effect strength (0-1, default: 1.0)
                           0 = no effect, 1 = full sepia

            QUICK START:
              airis edit filter sepia photo.jpg -o vintage.png

            EXAMPLES:
              # Full sepia effect
              airis edit filter sepia photo.jpg -o sepia.png

              # Subtle sepia tint
              airis edit filter sepia photo.jpg --intensity 0.5 -o subtle.png

              # Light vintage look
              airis edit filter sepia photo.jpg --intensity 0.3 -o light_vintage.png

            OUTPUT:
              Sepia-toned image in the specified format
            """
    )

    @Argument(help: "Input image path")
    var input: String

    @Option(name: [.short, .long], help: "Output path")
    var output: String

    @Option(name: .long, help: "Effect intensity (0-1, default: 1.0)")
    var intensity: Double = 1.0

    @Flag(name: .long, help: "Open result after processing")
    var open: Bool = false

    @Flag(name: .long, help: "Overwrite existing output file")
    var force: Bool = false

    func run() async throws {
        // 验证强度参数
        guard intensity >= 0 && intensity <= 1 else {
            throw AirisError.invalidPath("Intensity must be 0-1, got: \(intensity)")
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
        print("🟤 " + Strings.get("filter.sepia.title"))
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 " + Strings.get("edit.input") + ": \(inputURL.lastPathComponent)")
        print("💪 " + Strings.get("filter.intensity") + ": \(intensity)")
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
                coreImage.sepiaTone(ciImage: ciImage, intensity: intensity)
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
            NSWorkspace.shared.open(outputURL)
        }
    }
}
