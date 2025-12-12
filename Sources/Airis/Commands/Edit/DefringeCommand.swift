import ArgumentParser
import Foundation
import AppKit

struct DefringeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "defringe",
        abstract: "Remove chromatic aberration (purple/green fringing)",
        discussion: """
            Reduce color fringing artifacts around high-contrast edges.
            Common in images with chromatic aberration from lenses.

            QUICK START:
              airis edit defringe photo.jpg -o fixed.jpg

            EXAMPLES:
              # Basic defringe with default amount
              airis edit defringe photo.jpg -o defringed.jpg

              # Strong defringe effect
              airis edit defringe image.jpg --amount 1.0 -o fixed.jpg

              # Light defringe
              airis edit defringe portrait.png --amount 0.3 -o clean.png

            PARAMETERS:
              --amount: Defringe intensity (0.0-1.0, default: 0.5)
                        0.0 = no effect, 1.0 = maximum correction

            OUTPUT:
              Image with reduced chromatic aberration

            NOTE:
              Works best on images with visible purple or green fringing
              around high-contrast edges (e.g., backlit subjects, windows).
            """
    )

    @Argument(help: "Input image path")
    var input: String

    @Option(name: [.short, .long], help: "Output path")
    var output: String

    @Option(name: .long, help: "Defringe intensity (0.0-1.0, default: 0.5)")
    var amount: Double = 0.5

    @Flag(name: .long, help: "Open result after processing")
    var open: Bool = false

    @Flag(name: .long, help: "Overwrite existing output file")
    var force: Bool = false

    func run() async throws {
        // 验证参数
        guard amount >= 0 && amount <= 1.0 else {
            throw AirisError.invalidPath("Amount must be 0.0-1.0, got: \(amount)")
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
        print("🔮 " + Strings.get("edit.defringe.title"))
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 " + Strings.get("edit.input") + ": \(inputURL.lastPathComponent)")
        print("📊 " + Strings.get("edit.defringe.amount") + ": \(String(format: "%.0f%%", amount * 100))")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        print("⏳ " + Strings.get("info.processing"))

        // 加载图像
        let imageIO = ServiceContainer.shared.imageIOService
        let cgImage = try imageIO.loadImage(at: inputURL)
        let ciImage = CIImage(cgImage: cgImage)

        // 应用去紫边效果
        let coreImage = ServiceContainer.shared.coreImageService
        let defringed = coreImage.defringe(ciImage: ciImage, amount: amount)

        // 渲染并保存
#if DEBUG
        let forceNil = ProcessInfo.processInfo.environment["AIRIS_FORCE_DEFRINGE_RENDER_NIL"] == "1"
        let rendered = forceNil ? nil : coreImage.render(ciImage: defringed)
#else
        let rendered = coreImage.render(ciImage: defringed)
#endif

        guard let outputCGImage = rendered else {
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
