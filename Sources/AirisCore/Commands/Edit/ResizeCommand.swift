import AppKit
import ArgumentParser
import Foundation

struct ResizeCommand: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "resize",
            abstract: HelpTextFactory.text(
                en: "Resize images with high-quality scaling",
                cn: "高质量缩放图片尺寸"
            ),
            discussion: helpDiscussion(
                en: """
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
                """,
                cn: """
                使用 Lanczos 算法进行高质量缩放，并支持自动保持宽高比。

                QUICK START:
                  airis edit resize photo.jpg --width 1920 -o resized.jpg

                尺寸参数：
                  --width <px>      目标宽度（像素）
                  --height <px>     目标高度（像素）
                  --scale <factor>  缩放倍率（例如 0.5 表示缩小为一半）

                  只指定 width 或 height 时会自动保持宽高比。
                  同时指定 width+height 时，需要配合 --stretch 才会忽略宽高比。

                EXAMPLES:
                  # 仅指定宽度（保持宽高比）
                  airis edit resize photo.jpg --width 1920 -o photo_1080p.jpg

                  # 仅指定高度
                  airis edit resize photo.jpg --height 1080 -o photo_1080h.jpg

                  # 指定精确尺寸（可能拉伸变形）
                  airis edit resize photo.jpg --width 800 --height 600 --stretch -o thumb.jpg

                  # 按倍率缩放
                  airis edit resize photo.jpg --scale 0.5 -o photo_half.jpg

                  # 高质量 HEIC 输出
                  airis edit resize large.png --width 2000 -o optimized.heic --quality 0.9

                OUTPUT:
                  支持 PNG/JPEG/HEIC/TIFF 输出格式，格式由输出文件后缀决定。
                """
            )
        )
    }

    @Argument(help: HelpTextFactory.help(en: "Input image path", cn: "输入图片路径"))
    var input: String

    @Option(name: [.short, .long], help: HelpTextFactory.help(en: "Output path", cn: "输出路径"))
    var output: String

    @Option(name: .long, help: HelpTextFactory.help(en: "Target width in pixels", cn: "目标宽度（像素）"))
    var width: Int?

    @Option(name: .long, help: HelpTextFactory.help(en: "Target height in pixels", cn: "目标高度（像素）"))
    var height: Int?

    @Option(name: .long, help: HelpTextFactory.help(en: "Scale factor (e.g., 0.5 for half size)", cn: "缩放倍率（例如 0.5 表示缩小为一半）"))
    var scale: Double?

    @Flag(name: .long, help: HelpTextFactory.help(en: "Stretch to exact dimensions (ignore aspect ratio)", cn: "拉伸到精确尺寸（忽略宽高比）"))
    var stretch: Bool = false

    @Option(name: .long, help: HelpTextFactory.help(en: "Output quality for JPEG/HEIC (0.0-1.0)", cn: "输出质量（JPEG/HEIC：0.0-1.0）"))
    var quality: Float = 0.9

    @Flag(name: .long, help: HelpTextFactory.help(en: "Open result after processing", cn: "处理完成后打开输出文件"))
    var open: Bool = false

    @Flag(name: .long, help: HelpTextFactory.help(en: "Overwrite existing output file", cn: "覆盖已存在的输出文件"))
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
        if FileManager.default.fileExists(atPath: outputURL.path), !force {
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
            NSWorkspace.openForCLI(outputURL)
        }
    }
}
