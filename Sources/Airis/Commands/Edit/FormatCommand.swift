import ArgumentParser
import Foundation
import AppKit
import ImageIO
import UniformTypeIdentifiers

struct FormatCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "fmt",
        abstract: "Convert image format (jpg/png/heic/tiff)",
        discussion: """
            Convert images between different formats with quality control.
            Supports preserving or stripping metadata.

            QUICK START:
              airis edit fmt image.png --format jpg -o output.jpg

            SUPPORTED FORMATS:
              jpg/jpeg  - JPEG (lossy, small file size)
              png       - PNG (lossless, supports transparency)
              heic      - HEIC (efficient, macOS 10.13+)
              tiff/tif  - TIFF (lossless, large files)

            EXAMPLES:
              # Convert PNG to JPEG with 90% quality
              airis edit fmt photo.png --format jpg --quality 0.9 -o photo.jpg

              # Convert to HEIC (smaller file)
              airis edit fmt large.jpg --format heic -o smaller.heic

              # Convert keeping metadata
              airis edit fmt raw_export.tiff --format jpg -o web.jpg

              # Convert to PNG for transparency
              airis edit fmt overlay.jpg --format png -o overlay.png

            PARAMETERS:
              --format: Output format (jpg, png, heic, tiff)
              --quality: Compression quality 0.0-1.0 (default: 0.9, for jpg/heic)

            NOTE:
              - JPEG/HEIC: quality affects file size and detail preservation
              - PNG/TIFF: quality is ignored (always lossless)
              - Transparency is only preserved when converting to PNG
            """
    )

    @Argument(help: "Input image path")
    var input: String

    @Option(name: [.short, .long], help: "Output path")
    var output: String

    @Option(name: .long, help: "Output format: jpg, png, heic, tiff")
    var format: String

    @Option(name: .long, help: "Compression quality 0.0-1.0 (default: 0.9, for jpg/heic)")
    var quality: Float = 0.9

    @Flag(name: .long, help: "Open result after processing")
    var open: Bool = false

    @Flag(name: .long, help: "Overwrite existing output file")
    var force: Bool = false

    func run() async throws {
        // 验证格式
        let validFormats = ["jpg", "jpeg", "png", "heic", "tiff", "tif"]
        let normalizedFormat = format.lowercased()
        guard validFormats.contains(normalizedFormat) else {
            throw AirisError.unsupportedFormat("Invalid format: \(format). Use: jpg, png, heic, tiff")
        }

        // 验证质量
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

        // 获取输入格式信息
        let imageIO = ServiceContainer.shared.imageIOService
        let inputInfo = try imageIO.getImageInfo(at: inputURL)

        // 显示处理信息
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔄 " + Strings.get("edit.fmt.title"))
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 " + Strings.get("edit.input") + ": \(inputURL.lastPathComponent)")
        print("📐 " + Strings.get("info.dimension", inputInfo.width, inputInfo.height))
        print("🎯 " + Strings.get("edit.fmt.target_format") + ": \(normalizedFormat.uppercased())")
        if normalizedFormat == "jpg" || normalizedFormat == "jpeg" || normalizedFormat == "heic" {
            print("📊 " + Strings.get("edit.fmt.quality") + ": \(String(format: "%.0f%%", quality * 100))")
        }
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        print("⏳ " + Strings.get("edit.fmt.converting"))

        // 加载图像
        let cgImage = try imageIO.loadImage(at: inputURL)

        // 保存为新格式
        let saveFormat = normalizedFormat == "jpeg" ? "jpg" : (normalizedFormat == "tif" ? "tiff" : normalizedFormat)
        try imageIO.saveImage(cgImage, to: outputURL, format: saveFormat, quality: quality)

        print("")
        print("✅ " + Strings.get("info.saved_to", output))

        // 显示文件大小比较
        if let inputSize = FileUtils.getFileSize(at: inputURL.path),
           let outputSize = FileUtils.getFileSize(at: outputURL.path) {
            let inputSizeStr = ByteCountFormatter.string(fromByteCount: inputSize, countStyle: .file)
            let outputSizeStr = ByteCountFormatter.string(fromByteCount: outputSize, countStyle: .file)

            print("📦 " + Strings.get("edit.fmt.size_comparison", inputSizeStr, outputSizeStr))

            // 计算压缩比
            let ratio = Double(outputSize) / Double(inputSize)
            if ratio < 1.0 {
                print("📉 " + Strings.get("edit.fmt.compressed", String(format: "%.0f%%", (1 - ratio) * 100)))
            } else if ratio > 1.0 {
                print("📈 " + Strings.get("edit.fmt.expanded", String(format: "%.0f%%", (ratio - 1) * 100)))
            }
        }

        // 打开结果
        if open {
            NSWorkspace.shared.open(outputURL)
        }
    }
}
