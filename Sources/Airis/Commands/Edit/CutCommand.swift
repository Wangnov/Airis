import ArgumentParser
import Foundation
import AppKit

struct CutCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "cut",
        abstract: "Remove background from images",
        discussion: """
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
            """
    )

    @Argument(help: "Input image path")
    var input: String

    @Option(name: [.short, .long], help: "Output path (must be .png for transparency)")
    var output: String

    @Flag(name: .long, help: "Open result after processing")
    var open: Bool = false

    @Flag(name: .long, help: "Overwrite existing output file")
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
