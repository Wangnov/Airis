import ArgumentParser
import Foundation
import AppKit
import ImageIO
import UniformTypeIdentifiers

struct FormatCommand: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
        commandName: "fmt",
        abstract: HelpTextFactory.text(
            en: "Convert image format (jpg/png/heic/tiff)",
            cn: "转换图片格式（jpg/png/heic/tiff）"
        ),
        discussion: helpDiscussion(
            en: """
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
                """,
            cn: """
                在不同图片格式之间转换，并支持质量参数控制（JPEG/HEIC）。

                QUICK START:
                  airis edit fmt image.png --format jpg -o output.jpg

                支持格式：
                  jpg/jpeg  - JPEG（有损，体积小）
                  png       - PNG（无损，支持透明通道）
                  heic      - HEIC（效率高，macOS 10.13+）
                  tiff/tif  - TIFF（无损，文件较大）

                EXAMPLES:
                  # PNG 转 JPEG（90% 质量）
                  airis edit fmt photo.png --format jpg --quality 0.9 -o photo.jpg

                  # 转 HEIC（更小体积）
                  airis edit fmt large.jpg --format heic -o smaller.heic

                  # 转换并保持元数据
                  airis edit fmt raw_export.tiff --format jpg -o web.jpg

                  # 转 PNG（保留透明）
                  airis edit fmt overlay.jpg --format png -o overlay.png

                PARAMETERS:
                  --format: 输出格式（jpg, png, heic, tiff）
                  --quality: 压缩质量 0.0-1.0（默认：0.9，仅 jpg/heic 生效）

                NOTE:
                  - JPEG/HEIC：quality 影响文件大小与细节保留
                  - PNG/TIFF：忽略 quality（始终无损）
                  - 透明通道仅在输出为 PNG 时保留
                """
        )
    )
    }

    @Argument(help: HelpTextFactory.help(en: "Input image path", cn: "输入图片路径"))
    var input: String

    @Option(name: [.short, .long], help: HelpTextFactory.help(en: "Output path", cn: "输出路径"))
    var output: String

    @Option(name: .long, help: HelpTextFactory.help(en: "Output format: jpg, png, heic, tiff", cn: "输出格式：jpg, png, heic, tiff"))
    var format: String

    @Option(
        name: .long,
        help: HelpTextFactory.help(
            en: "Compression quality 0.0-1.0 (default: 0.9, for jpg/heic)",
            cn: "压缩质量 0.0-1.0（默认：0.9，仅 jpg/heic 生效）"
        )
    )
    var quality: Float = 0.9

    @Flag(name: .long, help: HelpTextFactory.help(en: "Open result after processing", cn: "处理完成后打开输出文件"))
    var open: Bool = false

    @Flag(name: .long, help: HelpTextFactory.help(en: "Overwrite existing output file", cn: "覆盖已存在的输出文件"))
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
            NSWorkspace.openForCLI(outputURL)
        }
    }
}
