import ArgumentParser
import Foundation
import AppKit

struct TraceCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "trace",
        abstract: "Apply vector tracing effect to images",
        discussion: """
            Convert images to a line art or sketch-like appearance.
            Uses edge detection filters to create a traced/outlined effect.

            QUICK START:
              airis edit trace photo.jpg -o traced.png

            STYLES:
              edges    - Basic edge detection (default)
              sketch   - Line overlay effect (sketch-like)
              work     - Edge work effect (woodcut-like)

            EXAMPLES:
              # Basic edge trace
              airis edit trace photo.jpg -o traced.png

              # Sketch-style effect
              airis edit trace portrait.jpg --style sketch -o sketch.png

              # Woodcut-style effect with custom radius
              airis edit trace image.jpg --style work --radius 5 -o woodcut.png

            PARAMETERS:
              --style: Tracing style (edges, sketch, work)
              --intensity: Effect intensity (0.1-5.0, default: 1.0)
              --radius: Edge thickness for 'work' style (1-10, default: 3)

            OUTPUT:
              Image with line art / traced effect applied
            """
    )

    @Argument(help: "Input image path")
    var input: String

    @Option(name: [.short, .long], help: "Output path")
    var output: String

    @Option(name: .long, help: "Tracing style: edges, sketch, work (default: edges)")
    var style: String = "edges"

    @Option(name: .long, help: "Effect intensity (0.1-5.0, default: 1.0)")
    var intensity: Double = 1.0

    @Option(name: .long, help: "Edge thickness for 'work' style (1-10, default: 3)")
    var radius: Double = 3.0

    @Flag(name: .long, help: "Open result after processing")
    var open: Bool = false

    @Flag(name: .long, help: "Overwrite existing output file")
    var force: Bool = false

    func run() async throws {
        // 验证参数
        let validStyles = ["edges", "sketch", "work"]
#if DEBUG
        let allowFallback = ProcessInfo.processInfo.environment["AIRIS_ALLOW_UNKNOWN_TRACE_STYLE"] == "1"
        let styleToUse: String
        if !validStyles.contains(style) && allowFallback {
            styleToUse = "edges"
        } else {
            guard validStyles.contains(style) else {
                throw AirisError.invalidPath("Invalid style: \(style). Use: edges, sketch, work")
            }
            styleToUse = style
        }
#else
        guard validStyles.contains(style) else {
            throw AirisError.invalidPath("Invalid style: \(style). Use: edges, sketch, work")
        }
        let styleToUse = style
#endif

        guard intensity >= 0.1 && intensity <= 5.0 else {
            throw AirisError.invalidPath("Intensity must be 0.1-5.0, got: \(intensity)")
        }

        guard radius >= 1 && radius <= 10 else {
            throw AirisError.invalidPath("Radius must be 1-10, got: \(radius)")
        }

        let inputURL = try FileUtils.validateImageFile(at: input)
        let outputURL = URL(fileURLWithPath: FileUtils.absolutePath(output))

        // 检查输出文件是否已存在
        if FileManager.default.fileExists(atPath: outputURL.path) && !force {
            throw AirisError.invalidPath("Output file already exists. Use --force to overwrite: \(output)")
        }

        // 确保输出目录存在
        try FileUtils.ensureDirectory(for: outputURL.path)

        // 显示处理信息
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("✏️  " + Strings.get("edit.trace.title"))
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 " + Strings.get("edit.input") + ": \(inputURL.lastPathComponent)")
        print("🎨 " + Strings.get("edit.trace.style") + ": \(style)")
        print("📊 " + Strings.get("edit.trace.intensity") + ": \(String(format: "%.1f", intensity))")
        if styleToUse == "work" {
            print("📏 " + Strings.get("edit.trace.radius") + ": \(String(format: "%.1f", radius))")
        }
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        print("⏳ " + Strings.get("info.processing"))

        // 加载图像
        let imageIO = ServiceContainer.shared.imageIOService
        let cgImage = try imageIO.loadImage(at: inputURL)
        let ciImage = CIImage(cgImage: cgImage)

        // 应用描摹效果
        let coreImage = ServiceContainer.shared.coreImageService

        var result: CIImage?

#if DEBUG
        let forceNilResult = ProcessInfo.processInfo.environment["AIRIS_FORCE_TRACE_RESULT_NIL"] == "1"
        let forceRenderNil = ProcessInfo.processInfo.environment["AIRIS_FORCE_TRACE_RENDER_NIL"] == "1"
        if forceNilResult {
            result = nil
        } else {
            if styleToUse == "edges" {
                result = coreImage.edges(ciImage: ciImage, intensity: intensity)
            } else if styleToUse == "sketch" {
                result = coreImage.lineOverlay(
                    ciImage: ciImage,
                    edgeIntensity: intensity
                )
            } else {
                result = coreImage.edgeWork(ciImage: ciImage, radius: radius)
            }
        }
#else
        if style == "edges" {
            result = coreImage.edges(ciImage: ciImage, intensity: intensity)
        } else if style == "sketch" {
            result = coreImage.lineOverlay(
                ciImage: ciImage,
                edgeIntensity: intensity
            )
        } else {
            result = coreImage.edgeWork(ciImage: ciImage, radius: radius)
        }
#endif

        guard let tracedImage = result else {
            throw AirisError.imageEncodeFailed
        }

        // 渲染并保存
        #if DEBUG
        if ProcessInfo.processInfo.environment["AIRIS_FORCE_TRACE_RENDER_FAIL"] == "1" {
            throw AirisError.imageEncodeFailed
        }
        let renderedImage = forceRenderNil ? nil : coreImage.render(ciImage: tracedImage)
        #else
        let renderedImage = coreImage.render(ciImage: tracedImage)
        #endif

        guard let outputCGImage = renderedImage else {
            throw AirisError.imageEncodeFailed
        }

        let outputFormat = FileUtils.getExtension(from: output)
        try imageIO.saveImage(outputCGImage, to: outputURL, format: outputFormat)

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
