import AppKit
import ArgumentParser
import Foundation

struct ThresholdCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "threshold",
        abstract: HelpTextFactory.text(
            en: "Convert to black and white based on threshold",
            cn: "阈值化黑白（Threshold）"
        ),
        discussion: helpDiscussion(
            en: """
            Apply threshold effect using CIColorThreshold filter.
            Converts image to pure black and white based on luminance threshold.

            PARAMETERS:
              Threshold: 0.0 to 1.0 (default: 0.5)
                        Pixels brighter than threshold become white
                        Pixels darker than threshold become black

            QUICK START:
              airis edit adjust threshold photo.jpg -o bw.jpg

            EXAMPLES:
              # Standard threshold (50%)
              airis edit adjust threshold photo.jpg -o bw.jpg

              # Lower threshold (more white areas)
              airis edit adjust threshold doc.png --threshold 0.3 -o high_contrast.png

              # Higher threshold (more black areas)
              airis edit adjust threshold sketch.jpg --threshold 0.7 -o dark.jpg

              # Create silhouette effect
              airis edit adjust threshold portrait.jpg --threshold 0.4 -o silhouette.png

            OUTPUT:
              Supports PNG, JPEG, HEIC, TIFF output formats.
              Format is determined by output file extension.
            """,
            cn: """
            使用 CIColorThreshold 将图片按阈值转换为纯黑白（无灰度）。

            参数范围：
              threshold: 0.0 ~ 1.0（默认：0.5；越小越“白”）

            QUICK START:
              airis edit adjust threshold photo.jpg -o bw.jpg

            EXAMPLES:
              airis edit adjust threshold doc.png --threshold 0.3 -o high_contrast.png
              airis edit adjust threshold sketch.jpg --threshold 0.7 -o dark.jpg
            """
        )
    )

    @Argument(help: HelpTextFactory.help(en: "Input image path", cn: "输入图片路径"))
    var input: String

    @Option(name: [.short, .long], help: HelpTextFactory.help(en: "Output path", cn: "输出路径"))
    var output: String

    @Option(name: .long, help: HelpTextFactory.help(en: "Threshold value (0.0 to 1.0, default: 0.5)", cn: "阈值（0.0~1.0，默认：0.5）"))
    var threshold: Double = 0.5

    @Option(name: .long, help: HelpTextFactory.help(en: "Output quality for JPEG/HEIC (0.0-1.0)", cn: "输出质量（JPEG/HEIC：0.0-1.0）"))
    var quality: Float = 0.9

    @Flag(name: .long, help: HelpTextFactory.help(en: "Open result after processing", cn: "处理完成后打开输出文件"))
    var open: Bool = false

    @Flag(name: .long, help: HelpTextFactory.help(en: "Overwrite existing output file", cn: "覆盖已存在的输出文件"))
    var force: Bool = false

    func run() async throws {
        // 参数验证
        guard threshold >= 0, threshold <= 1.0 else {
            throw AirisError.invalidPath("Threshold must be 0.0 to 1.0, got: \(threshold)")
        }

        let inputURL = try FileUtils.validateImageFile(at: input)
        let outputURL = URL(fileURLWithPath: FileUtils.absolutePath(output))
        let outputFormat = FileUtils.getExtension(from: output).lowercased()

        // 检查输出文件是否已存在
        if FileManager.default.fileExists(atPath: outputURL.path), !force {
            throw AirisError.invalidPath("Output file already exists. Use --force to overwrite: \(output)")
        }

        // 确保输出目录存在
        try FileUtils.ensureDirectory(for: outputURL.path)

        // 显示处理信息
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("⚫ " + Strings.get("edit.adjust.threshold.title"))
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 " + Strings.get("edit.input") + ": \(inputURL.lastPathComponent)")
        print("💾 " + Strings.get("edit.output") + ": \(output)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        print("📊 " + Strings.get("edit.adjust.threshold_value") + ": \(String(format: "%.2f", threshold))")
        print("")
        print("⏳ " + Strings.get("info.processing"))

        // 应用阈值化效果
        let coreImage = ServiceContainer.shared.coreImageService

        try coreImage.applyAndSave(
            inputURL: inputURL,
            outputURL: outputURL,
            format: outputFormat,
            quality: quality
        ) { ciImage in
            coreImage.threshold(ciImage: ciImage, threshold: threshold)
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
