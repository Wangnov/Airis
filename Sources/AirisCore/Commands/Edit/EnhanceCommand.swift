import ArgumentParser
import Foundation
import AppKit

struct EnhanceCommand: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
        commandName: "enhance",
        abstract: HelpTextFactory.text(
            en: "Auto-enhance images with one click",
            cn: "一键自动增强图片"
        ),
        discussion: helpDiscussion(
            en: """
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
                """,
            cn: """
                使用 Core Image 的自动增强能力对图片进行一键优化。
                会根据图像内容分析自动选择合适的滤镜组合。

                可能应用的调整：
                  • 红眼修复（检测到人脸时）
                  • Face Balance（肤色/人像平衡）
                  • Vibrance（自然饱和度增强）
                  • Tone Curve（对比度/曝光曲线）
                  • 高光/阴影调整

                QUICK START:
                  airis edit enhance photo.jpg -o enhanced.jpg

                EXAMPLES:
                  # 基础增强
                  airis edit enhance photo.jpg -o enhanced.jpg

                  # 不进行红眼修复
                  airis edit enhance landscape.jpg -o enhanced.jpg --no-redeye

                  # 更高质量输出（JPEG/HEIC）
                  airis edit enhance portrait.heic -o enhanced.heic --quality 0.95

                  # 处理后自动打开
                  airis edit enhance photo.jpg -o enhanced.jpg --open

                NOTE:
                  自动增强是非破坏性的，但重复多次可能会出现“过度处理”的效果。
                """
        )
    )
    }

    @Argument(help: HelpTextFactory.help(en: "Input image path", cn: "输入图片路径"))
    var input: String

    @Option(name: [.short, .long], help: HelpTextFactory.help(en: "Output path", cn: "输出路径"))
    var output: String

    @Flag(name: .long, help: HelpTextFactory.help(en: "Disable red-eye correction", cn: "禁用红眼修复"))
    var noRedeye: Bool = false

    @Option(name: .long, help: HelpTextFactory.help(en: "Output quality for JPEG/HEIC (0.0-1.0)", cn: "输出质量（JPEG/HEIC：0.0-1.0）"))
    var quality: Float = 0.9

    @Flag(name: .long, help: HelpTextFactory.help(en: "Open result after processing", cn: "处理完成后打开输出文件"))
    var open: Bool = false

    @Flag(name: .long, help: HelpTextFactory.help(en: "Overwrite existing output file", cn: "覆盖已存在的输出文件"))
    var force: Bool = false

    @Flag(name: .long, help: HelpTextFactory.help(en: "Show which filters will be applied", cn: "显示将要应用的滤镜列表"))
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
