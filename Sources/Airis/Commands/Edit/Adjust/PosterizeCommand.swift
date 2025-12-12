import ArgumentParser
import Foundation
import AppKit

struct PosterizeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "posterize",
        abstract: "Reduce color levels (poster effect)",
        discussion: """
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

            EFFECT:
              - Reduces continuous color gradients to discrete bands
              - Creates flat, graphic art appearance
              - Similar to screen printing or pop art style
              - Lower levels = Andy Warhol style effect

            USE CASES:
              - Creating pop art effects
              - Retro/vintage poster designs
              - Reducing color complexity for printing
              - Artistic stylization

            OUTPUT:
              Supports PNG, JPEG, HEIC, TIFF output formats.
              Format is determined by output file extension.
            """
    )

    @Argument(help: "Input image path")
    var input: String

    @Option(name: [.short, .long], help: "Output path")
    var output: String

    @Option(name: .long, help: "Number of color levels per channel (2 to 30, default: 6)")
    var levels: Double = 6.0

    @Option(name: .long, help: "Output quality for JPEG/HEIC (0.0-1.0)")
    var quality: Float = 0.9

    @Flag(name: .long, help: "Open result after processing")
    var open: Bool = false

    @Flag(name: .long, help: "Overwrite existing output file")
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
