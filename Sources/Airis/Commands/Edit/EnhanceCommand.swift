import ArgumentParser
import Foundation
import AppKit

struct EnhanceCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "enhance",
        abstract: "Auto-enhance images with one click",
        discussion: """
            Automatically enhance images using CoreImage's intelligent adjustment.
            Applies optimal filters based on image analysis.

            APPLIED ADJUSTMENTS:
              • Red-eye correction (if faces detected)
              • Face balance (skin tone optimization)
              • Vibrance (natural saturation boost)
              • Tone curve (contrast and exposure)
              • Highlight/shadow adjustment

            QUICK START:
              airis edit enhance photo.jpg -o enhanced.jpg

            EXAMPLES:
              # Basic enhancement
              airis edit enhance photo.jpg -o enhanced.jpg

              # Enhancement without red-eye correction
              airis edit enhance landscape.jpg -o enhanced.jpg --no-redeye

              # High quality output
              airis edit enhance portrait.heic -o enhanced.heic --quality 0.95

              # Process and open result
              airis edit enhance photo.jpg -o enhanced.jpg --open

            NOTE:
              Enhancement is non-destructive and can be applied multiple times,
              but results may become over-processed with repeated applications.
            """
    )

    @Argument(help: "Input image path")
    var input: String

    @Option(name: [.short, .long], help: "Output path")
    var output: String

    @Flag(name: .long, help: "Disable red-eye correction")
    var noRedeye: Bool = false

    @Option(name: .long, help: "Output quality for JPEG/HEIC (0.0-1.0)")
    var quality: Float = 0.9

    @Flag(name: .long, help: "Open result after processing")
    var open: Bool = false

    @Flag(name: .long, help: "Overwrite existing output file")
    var force: Bool = false

    @Flag(name: .long, help: "Show which filters will be applied")
    var verbose: Bool = false

    func run() async throws {
        let inputURL = try FileUtils.validateImageFile(at: input)
        let testMode = ProcessInfo.processInfo.environment["AIRIS_TEST_MODE"] == "1"

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
        print("✨ " + Strings.get("edit.enhance.title"))
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 " + Strings.get("edit.input") + ": \(inputURL.lastPathComponent)")
        print("💾 " + Strings.get("edit.output") + ": \(output)")
        if noRedeye {
            print("👁️  " + Strings.get("edit.enhance.redeye_disabled"))
        }
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")

        let coreImage = ServiceContainer.shared.coreImageService
        let imageIO = ServiceContainer.shared.imageIOService

        // 如果 verbose 模式，显示将应用的滤镜
        if verbose {
            let cgImage = try imageIO.loadImage(at: inputURL)
            let ciImage = CIImage(cgImage: cgImage)
            var filters = coreImage.getAutoEnhanceFilters(for: ciImage)
            #if DEBUG
            if ProcessInfo.processInfo.environment["AIRIS_FORCE_ENHANCE_NO_FILTERS"] == "1" {
                filters = []
            }
            #endif

            if filters.isEmpty {
                print("📋 " + Strings.get("edit.enhance.no_filters"))
            } else {
                print("📋 " + Strings.get("edit.enhance.filters_applied") + ":")
                for filter in filters {
                    print("   • \(filter)")
                }
            }
            print("")
        }

        print("⏳ " + Strings.get("info.processing"))

        // 执行自动增强
        try coreImage.autoEnhanceAndSave(
            inputURL: inputURL,
            outputURL: outputURL,
            format: outputFormat,
            quality: quality,
            enableRedEye: !noRedeye
        )

        print("")
        print("✅ " + Strings.get("info.saved_to", output))

        if let fileSize = FileUtils.getFormattedFileSize(at: outputURL.path) {
            print("📦 " + Strings.get("info.file_size", fileSize))
        }

        // 打开结果
        if open {
            if testMode {
                // 测试模式跳过真正打开 Finder，避免 UI 依赖
                print("👁️  (TEST MODE) open skipped")
            } else {
                NSWorkspace.openForCLI(outputURL)
            }
        }
    }
}
