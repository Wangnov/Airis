import ArgumentParser
import Foundation
import AppKit

struct CutCommand: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
        commandName: "cut",
        abstract: HelpTextFactory.text(
            en: "Remove background from images",
            cn: "背景移除（抠图）"
        ),
        discussion: helpDiscussion(
            en: """
                Remove image background using Vision's foreground segmentation.
                The subject is automatically detected and extracted with transparency.

                REQUIREMENTS:
                  macOS 14.0+
                  Output must be PNG format (for transparency)

                QUICK START:
                  airis edit cut photo.jpg -o cutout.png

                EXAMPLES:
                  # Basic background removal
                  airis edit cut photo.jpg -o cutout.png

                  # Process and open result
                  airis edit cut product.jpg -o product_nobg.png --open

                  # Overwrite existing file
                  airis edit cut portrait.heic -o portrait_nobg.png --force

                OUTPUT:
                  PNG image with transparent background (alpha channel)

                NOTE:
                  Works best with clear subject/background separation.
                  For complex scenes, results may vary.
                """,
            cn: """
                使用 Vision 的前景分割能力移除图片背景。
                会自动检测主体并导出带透明通道的抠图结果。

                REQUIREMENTS:
                  macOS 14.0+
                  输出必须是 PNG（用于透明背景）

                QUICK START:
                  airis edit cut photo.jpg -o cutout.png

                EXAMPLES:
                  # 基础抠图
                  airis edit cut photo.jpg -o cutout.png

                  # 处理后自动打开
                  airis edit cut product.jpg -o product_nobg.png --open

                  # 覆盖输出文件
                  airis edit cut portrait.heic -o portrait_nobg.png --force

                OUTPUT:
                  带透明背景（alpha 通道）的 PNG 图片

                NOTE:
                  对“主体与背景分离明显”的图片效果更好；复杂场景结果会有差异。
                """
        )
    )
    }

    @Argument(help: HelpTextFactory.help(en: "Input image path", cn: "输入图片路径"))
    var input: String

    @Option(
        name: [.short, .long],
        help: HelpTextFactory.help(
            en: "Output path (must be .png for transparency)",
            cn: "输出路径（必须为 .png 才能保留透明背景）"
        )
    )
    var output: String

    @Flag(name: .long, help: HelpTextFactory.help(en: "Open result after processing", cn: "处理完成后打开输出文件"))
    var open: Bool = false

    @Flag(name: .long, help: HelpTextFactory.help(en: "Overwrite existing output file", cn: "覆盖已存在的输出文件"))
    var force: Bool = false

    func run() async throws {
        // 验证 macOS 版本（测试可强制触发降级分支）
        let forceUnsupported = ProcessInfo.processInfo.environment["AIRIS_FORCE_CUT_OS_UNSUPPORTED"] == "1"
        guard #available(macOS 14.0, *), !forceUnsupported else {
            throw AirisError.unsupportedFormat("Background removal requires macOS 14.0+")
        }

        let inputURL = try FileUtils.validateImageFile(at: input)

        // 验证输出格式必须是 PNG（支持透明通道）
        let outputExt = FileUtils.getExtension(from: output).lowercased()
        guard outputExt == "png" else {
            throw AirisError.unsupportedFormat("Output must be PNG format for transparency. Got: .\(outputExt)")
        }

        let outputURL = URL(fileURLWithPath: FileUtils.absolutePath(output))

        // 检查输出文件是否已存在
        if FileManager.default.fileExists(atPath: outputURL.path) && !force {
            throw AirisError.invalidPath("Output file already exists. Use --force to overwrite: \(output)")
        }

        // 确保输出目录存在
        try FileUtils.ensureDirectory(for: outputURL.path)

        // 显示处理信息
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("✂️  " + Strings.get("edit.cut.title"))
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 " + Strings.get("edit.input") + ": \(inputURL.lastPathComponent)")
        print("💾 " + Strings.get("edit.output") + ": \(output)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        print("⏳ " + Strings.get("info.processing"))

        // 使用 VisionService 生成遮罩
        let vision = ServiceContainer.shared.visionService
        let maskedImage = try await vision.generateForegroundMask(at: inputURL)

        // 渲染并保存
        let coreImage = ServiceContainer.shared.coreImageService
        let imageIO = ServiceContainer.shared.imageIOService

#if DEBUG
        if ProcessInfo.processInfo.environment["AIRIS_FORCE_CUT_RENDER_FAIL"] == "1" {
            throw AirisError.imageEncodeFailed
        }

        let forceNilRender = ProcessInfo.processInfo.environment["AIRIS_FORCE_CUT_RENDER_NIL"] == "1"
        let renderResult: CGImage?
        if forceNilRender {
            renderResult = nil
        } else {
            renderResult = coreImage.render(ciImage: maskedImage)
        }
#else
        let renderResult = coreImage.render(ciImage: maskedImage)
#endif

        guard let cgImage = renderResult else {
            throw AirisError.imageEncodeFailed
        }

        try imageIO.saveImage(cgImage, to: outputURL, format: "png")

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
