import ArgumentParser
import Foundation
import AppKit

struct BlurCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "blur",
        abstract: "Apply blur effects to images",
        discussion: """
            Apply various blur effects using CoreImage filters.

            BLUR TYPES:
              gaussian  Standard Gaussian blur (default)
              motion    Directional motion blur
              zoom      Radial zoom blur from center

            PARAMETERS:
              --radius: Blur intensity (0-100, default: 10)
              --type:   Blur algorithm (gaussian, motion, zoom)
              --angle:  Motion direction in degrees (motion blur only)

            QUICK START:
              airis edit filter blur photo.jpg -o blurred.png

            EXAMPLES:
              # Gaussian blur with radius 10
              airis edit filter blur photo.jpg -o blurred.png

              # Stronger Gaussian blur
              airis edit filter blur photo.jpg --radius 25 -o soft.png

              # Motion blur (horizontal, 20px)
              airis edit filter blur photo.jpg --type motion --radius 20 --angle 0 -o motion.png

              # Diagonal motion blur
              airis edit filter blur photo.jpg --type motion --radius 15 --angle 45 -o diagonal.png

              # Zoom blur from center
              airis edit filter blur photo.jpg --type zoom --radius 15 -o zoom.png

            OUTPUT:
              Blurred image in the specified format (png, jpg, heic)
            """
    )

    @Argument(help: "Input image path")
    var input: String

    @Option(name: [.short, .long], help: "Output path")
    var output: String

    @Option(name: .long, help: "Blur radius (0-100, default: 10)")
    var radius: Double = 10

    @Option(name: .long, help: "Blur type: gaussian, motion, zoom (default: gaussian)")
    var type: String = "gaussian"

    @Option(name: .long, help: "Motion blur angle in degrees (0-360, default: 0)")
    var angle: Double = 0

    @Flag(name: .long, help: "Open result after processing")
    var open: Bool = false

    @Flag(name: .long, help: "Overwrite existing output file")
    var force: Bool = false

    func run() async throws {
        // 验证模糊类型
        let validTypes = ["gaussian", "motion", "zoom"]
        guard validTypes.contains(type.lowercased()) else {
            throw AirisError.invalidPath("Invalid blur type: '\(type)'. Valid types: \(validTypes.joined(separator: ", "))")
        }

        // 验证半径参数
        guard radius >= 0 && radius <= 100 else {
            throw AirisError.invalidPath("Blur radius must be 0-100, got: \(radius)")
        }

        // 验证角度参数
        guard angle >= 0 && angle <= 360 else {
            throw AirisError.invalidPath("Angle must be 0-360 degrees, got: \(angle)")
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
        print("🌫️  " + Strings.get("filter.blur.title"))
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 " + Strings.get("edit.input") + ": \(inputURL.lastPathComponent)")
        print("🎨 " + Strings.get("filter.blur.type") + ": \(type)")
        print("📏 " + Strings.get("filter.blur.radius") + ": \(radius)")
        if type.lowercased() == "motion" {
            print("📐 " + Strings.get("filter.blur.angle") + ": \(angle)°")
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
                switch type.lowercased() {
                case "gaussian":
                    return coreImage.gaussianBlur(ciImage: ciImage, radius: radius)
                case "motion":
                    return coreImage.motionBlur(ciImage: ciImage, radius: radius, angle: angle)
                case "zoom":
                    return coreImage.zoomBlur(ciImage: ciImage, amount: radius)
                default:
                    return coreImage.gaussianBlur(ciImage: ciImage, radius: radius)
                }
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
            NSWorkspace.shared.open(outputURL)
        }
    }
}
