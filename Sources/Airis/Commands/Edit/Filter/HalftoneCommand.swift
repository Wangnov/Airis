import ArgumentParser
import Foundation
import AppKit

struct HalftoneCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "halftone",
        abstract: "Apply halftone printing effect",
        discussion: """
            Apply halftone (dot screen) effect to images using CoreImage.

            Creates a retro print/newspaper style with dot patterns.
            Simulates the look of traditional offset printing.

            PARAMETERS:
              --width:     Dot spacing (1-50, default: 6)
                           Smaller = finer detail, larger = more obvious dots
              --angle:     Dot pattern angle in degrees (0-360, default: 0)
              --sharpness: Edge sharpness of dots (0-1, default: 0.7)

            QUICK START:
              airis edit filter halftone photo.jpg -o halftone.png

            EXAMPLES:
              # Default halftone effect
              airis edit filter halftone photo.jpg -o halftone.png

              # Newspaper style (larger dots)
              airis edit filter halftone photo.jpg --width 12 -o newspaper.png

              # Fine halftone
              airis edit filter halftone photo.jpg --width 3 -o fine.png

              # Angled halftone pattern
              airis edit filter halftone photo.jpg --angle 45 --width 8 -o angled.png

              # Soft halftone (less sharp dots)
              airis edit filter halftone photo.jpg --sharpness 0.3 -o soft.png

            OUTPUT:
              Halftone-styled image in the specified format
            """
    )

    @Argument(help: "Input image path")
    var input: String

    @Option(name: [.short, .long], help: "Output path")
    var output: String

    @Option(name: .long, help: "Dot spacing (1-50, default: 6)")
    var width: Double = 6

    @Option(name: .long, help: "Pattern angle in degrees (0-360, default: 0)")
    var angle: Double = 0

    @Option(name: .long, help: "Dot sharpness (0-1, default: 0.7)")
    var sharpness: Double = 0.7

    @Flag(name: .long, help: "Open result after processing")
    var open: Bool = false

    @Flag(name: .long, help: "Overwrite existing output file")
    var force: Bool = false

    func run() async throws {
        // 验证宽度参数
        guard width >= 1 && width <= 50 else {
            throw AirisError.invalidPath("Width must be 1-50, got: \(width)")
        }

        // 验证角度参数
        guard angle >= 0 && angle <= 360 else {
            throw AirisError.invalidPath("Angle must be 0-360 degrees, got: \(angle)")
        }

        // 验证锐度参数
        guard sharpness >= 0 && sharpness <= 1 else {
            throw AirisError.invalidPath("Sharpness must be 0-1, got: \(sharpness)")
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
        print("📰 " + Strings.get("filter.halftone.title"))
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 " + Strings.get("edit.input") + ": \(inputURL.lastPathComponent)")
        print("📏 " + Strings.get("filter.halftone.width") + ": \(width)")
        print("📐 " + Strings.get("filter.halftone.angle") + ": \(angle)°")
        print("🔪 " + Strings.get("filter.halftone.sharpness") + ": \(sharpness)")
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
                coreImage.halftone(ciImage: ciImage, width: width, angle: angle, sharpness: sharpness)
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
