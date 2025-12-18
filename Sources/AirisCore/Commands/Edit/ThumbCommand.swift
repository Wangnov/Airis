import AppKit
import ArgumentParser
import Foundation
import ImageIO

struct ThumbCommand: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "thumb",
            abstract: HelpTextFactory.text(
                en: "Generate thumbnails from images",
                cn: "生成图片缩略图"
            ),
            discussion: helpDiscussion(
                en: """
                Create optimized thumbnails with automatic aspect ratio preservation.
                Uses efficient ImageIO downsampling for best performance.

                QUICK START:
                  airis edit thumb photo.jpg --size 256 -o thumb.jpg

                EXAMPLES:
                  # Generate 256px thumbnail
                  airis edit thumb photo.jpg --size 256 -o thumb.jpg

                  # Generate larger preview (512px)
                  airis edit thumb image.png --size 512 -o preview.png

                  # Generate small icon (64px)
                  airis edit thumb logo.png --size 64 -o icon.png

                  # With custom quality (for JPEG output)
                  airis edit thumb photo.jpg --size 200 --quality 0.8 -o thumb.jpg

                PARAMETERS:
                  --size: Maximum dimension in pixels (default: 256)
                          Both width and height will fit within this size
                  --quality: JPEG quality 0.0-1.0 (default: 0.85)

                OUTPUT:
                  Thumbnail image maintaining original aspect ratio

                NOTE:
                  - Aspect ratio is always preserved
                  - EXIF orientation is automatically applied
                  - Works efficiently even with very large source images
                """,
                cn: """
                生成缩略图并自动保持宽高比。
                通过 ImageIO Downsampling 高效处理大图，速度更快、内存占用更低。

                QUICK START:
                  airis edit thumb photo.jpg --size 256 -o thumb.jpg

                EXAMPLES:
                  # 256px 缩略图
                  airis edit thumb photo.jpg --size 256 -o thumb.jpg

                  # 512px 预览图
                  airis edit thumb image.png --size 512 -o preview.png

                  # 64px 图标
                  airis edit thumb logo.png --size 64 -o icon.png

                  # JPEG 自定义质量
                  airis edit thumb photo.jpg --size 200 --quality 0.8 -o thumb.jpg

                PARAMETERS:
                  --size: 最大边长（像素，默认：256）
                          输出宽高都会限制在该范围内
                  --quality: JPEG 输出质量 0.0-1.0（默认：0.85）

                OUTPUT:
                  输出为保持原始宽高比的缩略图

                NOTE:
                  - 永远保持宽高比
                  - 自动应用 EXIF 方向
                  - 即使源图很大也能高效处理
                """
            )
        )
    }

    @Argument(help: HelpTextFactory.help(en: "Input image path", cn: "输入图片路径"))
    var input: String

    @Option(name: [.short, .long], help: HelpTextFactory.help(en: "Output path", cn: "输出路径"))
    var output: String

    @Option(name: .long, help: HelpTextFactory.help(en: "Maximum dimension in pixels (default: 256)", cn: "最大边长（像素，默认：256）"))
    var size: Int = 256

    @Option(name: .long, help: HelpTextFactory.help(en: "JPEG quality 0.0-1.0 (default: 0.85)", cn: "JPEG 输出质量 0.0-1.0（默认：0.85）"))
    var quality: Float = 0.85

    @Flag(name: .long, help: HelpTextFactory.help(en: "Open result after processing", cn: "处理完成后打开输出文件"))
    var open: Bool = false

    @Flag(name: .long, help: HelpTextFactory.help(en: "Overwrite existing output file", cn: "覆盖已存在的输出文件"))
    var force: Bool = false

    func run() async throws {
        // 验证参数
        guard size > 0, size <= 4096 else {
            throw AirisError.invalidPath("Size must be 1-4096, got: \(size)")
        }

        guard quality >= 0, quality <= 1.0 else {
            throw AirisError.invalidPath("Quality must be 0.0-1.0, got: \(quality)")
        }

        let inputURL = try FileUtils.validateImageFile(at: input)
        let outputURL = URL(fileURLWithPath: FileUtils.absolutePath(output))

        // 检查输出文件是否已存在
        if FileManager.default.fileExists(atPath: outputURL.path), !force {
            throw AirisError.invalidPath("Output file already exists. Use --force to overwrite: \(output)")
        }

        // 确保输出目录存在
        try FileUtils.ensureDirectory(for: outputURL.path)

        // 获取输入信息
        let imageIO = ServiceContainer.shared.imageIOService
        let inputInfo = try imageIO.getImageInfo(at: inputURL)

        // 显示处理信息
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🖼️  " + Strings.get("edit.thumb.title"))
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 " + Strings.get("edit.input") + ": \(inputURL.lastPathComponent)")
        print("📐 " + Strings.get("edit.thumb.original_size") + ": \(inputInfo.width) × \(inputInfo.height)")
        print("🎯 " + Strings.get("edit.thumb.target_size") + ": \(size)px")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        print("⏳ " + Strings.get("edit.thumb.generating"))

        // 使用 ImageIO 高效生成缩略图
        #if DEBUG
            let forceSourceNil = ProcessInfo.processInfo.environment["AIRIS_FORCE_THUMB_SOURCE_NIL"] == "1"
            let imageSource = forceSourceNil ? nil : CGImageSourceCreateWithURL(inputURL as CFURL, nil)
        #else
            let imageSource = CGImageSourceCreateWithURL(inputURL as CFURL, nil)
        #endif

        guard let imageSource else {
            throw AirisError.imageDecodeFailed
        }

        let options: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: size,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceShouldCacheImmediately: true,
        ]

        #if DEBUG
            let forceThumbNil = ProcessInfo.processInfo.environment["AIRIS_FORCE_THUMB_THUMB_NIL"] == "1"
            let thumbnail = forceThumbNil ? nil : CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary)
        #else
            let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary)
        #endif

        guard let thumbnail else {
            throw AirisError.imageDecodeFailed
        }

        // 保存缩略图
        let outputFormat = FileUtils.getExtension(from: output)
        try imageIO.saveImage(thumbnail, to: outputURL, format: outputFormat, quality: quality)

        print("")
        print("✅ " + Strings.get("info.saved_to", output))

        // 显示结果尺寸
        print("📐 " + Strings.get("edit.thumb.result_size") + ": \(thumbnail.width) × \(thumbnail.height)")

        // 显示文件大小
        if let fileSize = FileUtils.getFormattedFileSize(at: outputURL.path) {
            print("📦 " + Strings.get("info.file_size", fileSize))
        }

        // 计算缩放比
        let scaleFactor = Double(thumbnail.width) / Double(inputInfo.width)
        print("📉 " + Strings.get("edit.thumb.scale_factor", String(format: "%.1f%%", scaleFactor * 100)))

        // 打开结果
        if open {
            NSWorkspace.openForCLI(outputURL)
        }
    }
}
