import ArgumentParser
import Foundation
import AppKit
import ImageIO

struct ThumbCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "thumb",
        abstract: "Generate thumbnails from images",
        discussion: """
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
            """
    )

    @Argument(help: "Input image path")
    var input: String

    @Option(name: [.short, .long], help: "Output path")
    var output: String

    @Option(name: .long, help: "Maximum dimension in pixels (default: 256)")
    var size: Int = 256

    @Option(name: .long, help: "JPEG quality 0.0-1.0 (default: 0.85)")
    var quality: Float = 0.85

    @Flag(name: .long, help: "Open result after processing")
    var open: Bool = false

    @Flag(name: .long, help: "Overwrite existing output file")
    var force: Bool = false

    func run() async throws {
        // 验证参数
        guard size > 0 && size <= 4096 else {
            throw AirisError.invalidPath("Size must be 1-4096, got: \(size)")
        }

        guard quality >= 0 && quality <= 1.0 else {
            throw AirisError.invalidPath("Quality must be 0.0-1.0, got: \(quality)")
        }

        let inputURL = try FileUtils.validateImageFile(at: input)
        let outputURL = URL(fileURLWithPath: FileUtils.absolutePath(output))

        // 检查输出文件是否已存在
        if FileManager.default.fileExists(atPath: outputURL.path) && !force {
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
        guard let imageSource = CGImageSourceCreateWithURL(inputURL as CFURL, nil) else {
            throw AirisError.imageDecodeFailed
        }

        let options: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: size,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceShouldCacheImmediately: true
        ]

        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
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
            NSWorkspace.shared.open(outputURL)
        }
    }
}
