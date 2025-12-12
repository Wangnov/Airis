import ArgumentParser
import Foundation
import AppKit

struct ColorCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "color",
        abstract: "Adjust brightness, contrast, and saturation",
        discussion: """
            Fine-tune image colors with precise control using CIColorControls filter.

            PARAMETERS:
              Brightness: -1.0 to 1.0 (0 = unchanged)
              Contrast:   0.0 to 4.0 (1.0 = unchanged)
              Saturation: 0.0 to 2.0 (1.0 = unchanged, 0 = grayscale)

            QUICK START:
              airis edit adjust color photo.jpg --brightness 0.2 -o bright.jpg

            EXAMPLES:
              # Increase brightness
              airis edit adjust color photo.jpg --brightness 0.2 -o bright.jpg

              # Boost contrast and saturation
              airis edit adjust color photo.jpg --contrast 1.3 --saturation 1.2 -o vivid.jpg

              # Desaturate (grayscale effect)
              airis edit adjust color photo.jpg --saturation 0 -o bw.jpg

              # All parameters at once
              airis edit adjust color dark.jpg \\
                --brightness 0.3 --contrast 1.2 --saturation 1.1 -o enhanced.jpg

              # Lower contrast for flat look
              airis edit adjust color photo.jpg --contrast 0.7 -o flat.jpg

            OUTPUT:
              Supports PNG, JPEG, HEIC, TIFF output formats.
              Format is determined by output file extension.
            """
    )

    @Argument(help: "Input image path")
    var input: String

    @Option(name: [.short, .long], help: "Output path")
    var output: String

    @Option(name: .long, help: "Brightness adjustment (-1.0 to 1.0, default: 0)")
    var brightness: Double = 0

    @Option(name: .long, help: "Contrast adjustment (0.0 to 4.0, default: 1.0)")
    var contrast: Double = 1.0

    @Option(name: .long, help: "Saturation adjustment (0.0 to 2.0, default: 1.0)")
    var saturation: Double = 1.0

    @Option(name: .long, help: "Output quality for JPEG/HEIC (0.0-1.0)")
    var quality: Float = 0.9

    @Flag(name: .long, help: "Open result after processing")
    var open: Bool = false

    @Flag(name: .long, help: "Overwrite existing output file")
    var force: Bool = false

    func run() async throws {
        // 参数验证
        guard brightness >= -1.0 && brightness <= 1.0 else {
            throw AirisError.invalidPath("Brightness must be -1.0 to 1.0, got: \(brightness)")
        }
        guard contrast >= 0 && contrast <= 4.0 else {
            throw AirisError.invalidPath("Contrast must be 0.0 to 4.0, got: \(contrast)")
        }
        guard saturation >= 0 && saturation <= 2.0 else {
            throw AirisError.invalidPath("Saturation must be 0.0 to 2.0, got: \(saturation)")
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
        print("🎨 " + Strings.get("edit.adjust.color.title"))
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 " + Strings.get("edit.input") + ": \(inputURL.lastPathComponent)")
        print("💾 " + Strings.get("edit.output") + ": \(output)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        print("☀️  " + Strings.get("edit.adjust.brightness") + ": \(String(format: "%+.2f", brightness))")
        print("🔆 " + Strings.get("edit.adjust.contrast") + ": \(String(format: "%.2f", contrast))×")
        print("🌈 " + Strings.get("edit.adjust.saturation") + ": \(String(format: "%.2f", saturation))×")
        print("")
        print("⏳ " + Strings.get("info.processing"))

        // 应用色彩调整
        let coreImage = ServiceContainer.shared.coreImageService

        try coreImage.applyAndSave(
            inputURL: inputURL,
            outputURL: outputURL,
            format: outputFormat,
            quality: quality
        ) { ciImage in
            coreImage.adjustColors(
                ciImage: ciImage,
                brightness: brightness,
                contrast: contrast,
                saturation: saturation
            )
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
