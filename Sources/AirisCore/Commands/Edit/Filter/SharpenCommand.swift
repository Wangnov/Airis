import ArgumentParser
import Foundation
import AppKit

struct SharpenCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "sharpen",
        abstract: HelpTextFactory.text(
            en: "Sharpen images",
            cn: "锐化"
        ),
        discussion: helpDiscussion(
            en: """
                Apply sharpening effects to enhance image details using CoreImage filters.

                SHARPEN METHODS:
                  luminance  Sharpen luminance channel only (default, preserves colors)
                  unsharp    Unsharp mask (traditional, more control)

                PARAMETERS:
                  --intensity: Sharpening strength (0-2, default: 0.5)
                  --radius:    Affected area radius for unsharp mask (0-10, default: 2.5)
                  --method:    Sharpening algorithm (luminance, unsharp)

                QUICK START:
                  airis edit filter sharpen photo.jpg -o sharpened.png

                EXAMPLES:
                  # Default luminance sharpening
                  airis edit filter sharpen photo.jpg -o sharp.png

                  # Stronger sharpening
                  airis edit filter sharpen photo.jpg --intensity 1.0 -o sharp.png

                  # Unsharp mask with custom radius
                  airis edit filter sharpen photo.jpg --method unsharp --radius 3.0 --intensity 0.8 -o sharp.png

                  # Subtle sharpening for portraits
                  airis edit filter sharpen portrait.jpg --intensity 0.3 -o portrait_sharp.png

                OUTPUT:
                  Sharpened image in the specified format
                """,
            cn: """
                使用 Core Image 锐化图片细节，支持 luminance（默认）与 unsharp 两种方法。

                QUICK START:
                  airis edit filter sharpen photo.jpg -o sharpened.png

                EXAMPLES:
                  # 更强锐化
                  airis edit filter sharpen photo.jpg --intensity 1.0 -o sharp.png

                  # Unsharp mask
                  airis edit filter sharpen photo.jpg --method unsharp --radius 3.0 --intensity 0.8 -o sharp.png
                """
        )
    )

    @Argument(help: HelpTextFactory.help(en: "Input image path", cn: "输入图片路径"))
    var input: String

    @Option(name: [.short, .long], help: HelpTextFactory.help(en: "Output path", cn: "输出路径"))
    var output: String

    @Option(name: .long, help: HelpTextFactory.help(en: "Sharpening intensity (0-2, default: 0.5)", cn: "锐化强度（0-2，默认：0.5）"))
    var intensity: Double = 0.5

    @Option(name: .long, help: HelpTextFactory.help(en: "Radius for unsharp mask (0-10, default: 2.5)", cn: "Unsharp 半径（0-10，默认：2.5）"))
    var radius: Double = 2.5

    @Option(
        name: .long,
        help: HelpTextFactory.help(
            en: "Sharpening method: luminance, unsharp (default: luminance)",
            cn: "方法：luminance / unsharp（默认：luminance）"
        )
    )
    var method: String = "luminance"

    @Flag(name: .long, help: HelpTextFactory.help(en: "Open result after processing", cn: "处理完成后打开输出文件"))
    var open: Bool = false

    @Flag(name: .long, help: HelpTextFactory.help(en: "Overwrite existing output file", cn: "覆盖已存在的输出文件"))
    var force: Bool = false

    func run() async throws {
        // 验证方法
        let validMethods = ["luminance", "unsharp"]
        guard validMethods.contains(method.lowercased()) else {
            throw AirisError.invalidPath("Invalid method: '\(method)'. Valid methods: \(validMethods.joined(separator: ", "))")
        }

        // 验证强度参数
        guard intensity >= 0 && intensity <= 2 else {
            throw AirisError.invalidPath("Intensity must be 0-2, got: \(intensity)")
        }

        // 验证半径参数
        guard radius >= 0 && radius <= 10 else {
            throw AirisError.invalidPath("Radius must be 0-10, got: \(radius)")
        }

        let inputURL = try FileUtils.validateImageFile(at: input)
        let outputURL = URL(fileURLWithPath: FileUtils.absolutePath(output))

        // 检查输出文件是否已存在
        if FileManager.default.fileExists(atPath: outputURL.path) && !force {
            throw AirisError.invalidPath("Output file already exists. Use --force to overwrite: \(output)")
        }

        // 确保输出目录存在
        try FileUtils.ensureDirectory(for: outputURL.path)

        // 获取输出格式
        let outputFormat = FileUtils.getExtension(from: output).lowercased()
        let supportedFormats = ["png", "jpg", "jpeg", "heic", "tiff"]
        guard supportedFormats.contains(outputFormat) else {
            throw AirisError.unsupportedFormat("Unsupported output format: .\(outputFormat). Use: \(supportedFormats.joined(separator: ", "))")
        }

        // 显示处理信息
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔪 " + Strings.get("filter.sharpen.title"))
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 " + Strings.get("edit.input") + ": \(inputURL.lastPathComponent)")
        print("🎨 " + Strings.get("filter.sharpen.method") + ": \(method)")
        print("💪 " + Strings.get("filter.sharpen.intensity") + ": \(intensity)")
        if method.lowercased() == "unsharp" {
            print("📏 " + Strings.get("filter.sharpen.radius") + ": \(radius)")
        }
        print("💾 " + Strings.get("edit.output") + ": \(output)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        print("⏳ " + Strings.get("info.processing"))

        // 应用滤镜
        let coreImage = ServiceContainer.shared.coreImageService

        try coreImage.applyAndSave(
            inputURL: inputURL,
            outputURL: outputURL,
            format: outputFormat == "jpeg" ? "jpg" : outputFormat,
            filterBlock: { ciImage in
                applySharpen(ciImage: ciImage, method: method, intensity: intensity, radius: radius, coreImage: coreImage)
            }
        )

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

    private func applySharpen(
        ciImage: CIImage,
        method: String,
        intensity: Double,
        radius: Double,
        coreImage: CoreImageService
    ) -> CIImage {
        switch method.lowercased() {
        case "luminance":
            return coreImage.sharpen(ciImage: ciImage, sharpness: intensity)
        case "unsharp":
            return coreImage.unsharpMask(ciImage: ciImage, radius: radius, intensity: intensity)
        default:
            return coreImage.sharpen(ciImage: ciImage, sharpness: intensity)
        }
    }

    #if DEBUG
    /// 测试辅助：无需文件 IO 即可覆盖不同 method 分支
    static func testFilter(method: String, intensity: Double = 0.5, radius: Double = 2.0) -> CIImage {
        let coreImage = ServiceContainer.shared.coreImageService
        let base = CIImage(color: CIColor(red: 0, green: 0, blue: 0)).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
        return SharpenCommand().applySharpen(ciImage: base, method: method, intensity: intensity, radius: radius, coreImage: coreImage)
    }
    #endif
}
