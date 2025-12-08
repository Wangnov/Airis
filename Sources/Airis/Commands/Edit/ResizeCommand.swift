import ArgumentParser
import Foundation
import AppKit

struct ResizeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "resize",
        abstract: "Resize images with high-quality scaling",
        discussion: """
            Resize images using Lanczos algorithm for high-quality results.
            Supports maintaining aspect ratio automatically.

            QUICK START:
              airis edit resize photo.jpg --width 1920 -o resized.jpg

            SIZING OPTIONS:
              --width <px>      Target width in pixels
              --height <px>     Target height in pixels
              --scale <factor>  Scale factor (e.g., 0.5 for half size)

              If only width OR height is specified, aspect ratio is maintained.
              If both are specified, use --stretch to ignore aspect ratio.

            EXAMPLES:
              # Resize to specific width (maintain aspect ratio)
              airis edit resize photo.jpg --width 1920 -o photo_1080p.jpg

              # Resize to specific height
              airis edit resize photo.jpg --height 1080 -o photo_1080h.jpg

              # Resize to exact dimensions (may distort)
              airis edit resize photo.jpg --width 800 --height 600 --stretch -o thumb.jpg

              # Scale by factor
              airis edit resize photo.jpg --scale 0.5 -o photo_half.jpg

              # High quality HEIC output
              airis edit resize large.png --width 2000 -o optimized.heic --quality 0.9

            OUTPUT:
              Supports PNG, JPEG, HEIC, TIFF output formats.
              Format is determined by output file extension.
            """
    )

    @Argument(help: "Input image path")
    var input: String

    @Option(name: [.short, .long], help: "Output path")
    var output: String

    @Option(name: .long, help: "Target width in pixels")
    var width: Int?

    @Option(name: .long, help: "Target height in pixels")
    var height: Int?

    @Option(name: .long, help: "Scale factor (e.g., 0.5 for half size)")
    var scale: Double?

    @Flag(name: .long, help: "Stretch to exact dimensions (ignore aspect ratio)")
    var stretch: Bool = false

    @Option(name: .long, help: "Output quality for JPEG/HEIC (0.0-1.0)")
    var quality: Float = 0.9

    @Flag(name: .long, help: "Open result after processing")
    var open: Bool = false

    @Flag(name: .long, help: "Overwrite existing output file")
    var force: Bool = false

    func run() async throws {
        let inputURL = try FileUtils.validateImageFile(at: input)

        // 验证必须指定尺寸参数
        guard width != nil || height != nil || scale != nil else {
            throw AirisError.invalidPath("Must specify --width, --height, or --scale")
        }

        let outputURL = URL(fileURLWithPath: FileUtils.absolutePath(output))
        let outputFormat = FileUtils.getExtension(from: output).lowercased()

        // 检查输出文件是否已存在
        if FileManager.default.fileExists(atPath: outputURL.path) && !force {
            throw AirisError.invalidPath("Output file already exists. Use --force to overwrite: \(output)")
        }

        // 确保输出目录存在
        try FileUtils.ensureDirectory(for: outputURL.path)

        // 获取原始图像信息
        let imageIO = ServiceContainer.shared.imageIOService
        let imageInfo = try imageIO.getImageInfo(at: inputURL)
        let originalWidth = imageInfo.width
        let originalHeight = imageInfo.height

        // 计算目标尺寸
        var targetWidth: Int?
        var targetHeight: Int?

        if let scaleFactor = scale {
            targetWidth = Int(Double(originalWidth) * scaleFactor)
            targetHeight = Int(Double(originalHeight) * scaleFactor)
        } else {
            targetWidth = width
            targetHeight = height
        }

        // 显示处理信息
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📐 " + Strings.get("edit.resize.title"))
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 " + Strings.get("edit.input") + ": \(inputURL.lastPathComponent)")
        print("💾 " + Strings.get("edit.output") + ": \(output)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        print("📏 " + Strings.get("edit.resize.original") + ": \(originalWidth) × \(originalHeight)")

        if let w = targetWidth, let h = targetHeight {
            print("🎯 " + Strings.get("edit.resize.target") + ": \(w) × \(h)" + (stretch ? " (stretch)" : ""))
        } else if let w = targetWidth {
            print("🎯 " + Strings.get("edit.resize.target_width") + ": \(w)")
        } else if let h = targetHeight {
            print("🎯 " + Strings.get("edit.resize.target_height") + ": \(h)")
        }

        print("")
        print("⏳ " + Strings.get("info.processing"))

        // 使用 CoreImageService 进行缩放
        let coreImage = ServiceContainer.shared.coreImageService

        try coreImage.applyAndSave(
            inputURL: inputURL,
            outputURL: outputURL,
            format: outputFormat,
            quality: quality
        ) { ciImage in
            coreImage.resize(
                ciImage: ciImage,
                width: targetWidth,
                height: targetHeight,
                maintainAspectRatio: !stretch
            )
        }

        print("")
        print("✅ " + Strings.get("info.saved_to", output))

        // 显示输出图像信息
        let outputInfo = try imageIO.getImageInfo(at: outputURL)
        print("📐 " + Strings.get("edit.resize.result") + ": \(outputInfo.width) × \(outputInfo.height)")

        if let fileSize = FileUtils.getFormattedFileSize(at: outputURL.path) {
            print("📦 " + Strings.get("info.file_size", fileSize))
        }

        // 打开结果
        if open {
            NSWorkspace.shared.open(outputURL)
        }
    }
}
