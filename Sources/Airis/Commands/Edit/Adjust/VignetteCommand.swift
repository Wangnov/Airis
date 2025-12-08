import ArgumentParser
import Foundation
import AppKit

struct VignetteCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "vignette",
        abstract: "Add vignette effect (darkened edges)",
        discussion: """
            Add artistic vignette effect using CIVignette filter.
            Darkens the edges of the image to draw attention to the center.

            PARAMETERS:
              Intensity: 0.0 to 2.0 (0 = no effect, higher = darker edges)
              Radius:    0.0 to 2.0 (controls where darkening starts)
                         Lower values = larger dark area
                         Higher values = smaller dark area (more subtle)

            QUICK START:
              airis edit adjust vignette photo.jpg --intensity 1.0 -o vignetted.jpg

            EXAMPLES:
              # Standard vignette effect
              airis edit adjust vignette photo.jpg --intensity 1.0 -o vignetted.jpg

              # Strong dramatic vignette
              airis edit adjust vignette portrait.jpg --intensity 1.8 --radius 0.8 -o dramatic.jpg

              # Subtle vignette
              airis edit adjust vignette landscape.jpg --intensity 0.5 --radius 1.5 -o subtle.jpg

              # Wide vignette (larger darkened area)
              airis edit adjust vignette photo.jpg --intensity 1.2 --radius 0.5 -o wide.jpg

              # Tight center focus
              airis edit adjust vignette photo.jpg --intensity 1.5 --radius 1.8 -o focused.jpg

            NOTE:
              Vignette is commonly used in portrait and artistic photography
              to draw the viewer's eye to the subject in the center.

            OUTPUT:
              Supports PNG, JPEG, HEIC, TIFF output formats.
              Format is determined by output file extension.
            """
    )

    @Argument(help: "Input image path")
    var input: String

    @Option(name: [.short, .long], help: "Output path")
    var output: String

    @Option(name: .long, help: "Vignette intensity (0.0 to 2.0, default: 1.0)")
    var intensity: Double = 1.0

    @Option(name: .long, help: "Vignette radius (0.0 to 2.0, default: 1.0)")
    var radius: Double = 1.0

    @Option(name: .long, help: "Output quality for JPEG/HEIC (0.0-1.0)")
    var quality: Float = 0.9

    @Flag(name: .long, help: "Open result after processing")
    var open: Bool = false

    @Flag(name: .long, help: "Overwrite existing output file")
    var force: Bool = false

    func run() async throws {
        // 参数验证
        guard intensity >= 0 && intensity <= 2.0 else {
            throw AirisError.invalidPath("Intensity must be 0.0 to 2.0, got: \(intensity)")
        }
        guard radius >= 0 && radius <= 2.0 else {
            throw AirisError.invalidPath("Radius must be 0.0 to 2.0, got: \(radius)")
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
        print("🔲 " + Strings.get("edit.adjust.vignette.title"))
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 " + Strings.get("edit.input") + ": \(inputURL.lastPathComponent)")
        print("💾 " + Strings.get("edit.output") + ": \(output)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        print("💪 " + Strings.get("edit.adjust.intensity") + ": \(String(format: "%.2f", intensity))")
        print("📏 " + Strings.get("edit.adjust.radius") + ": \(String(format: "%.2f", radius))")
        print("")
        print("⏳ " + Strings.get("info.processing"))

        // 应用暗角效果
        let coreImage = ServiceContainer.shared.coreImageService

        try coreImage.applyAndSave(
            inputURL: inputURL,
            outputURL: outputURL,
            format: outputFormat,
            quality: quality
        ) { ciImage in
            coreImage.vignette(ciImage: ciImage, intensity: intensity, radius: radius)
        }

        print("")
        print("✅ " + Strings.get("info.saved_to", output))

        if let fileSize = FileUtils.getFormattedFileSize(at: outputURL.path) {
            print("📦 " + Strings.get("info.file_size", fileSize))
        }

        // 打开结果
        if open {
            NSWorkspace.shared.open(outputURL)
        }
    }
}
