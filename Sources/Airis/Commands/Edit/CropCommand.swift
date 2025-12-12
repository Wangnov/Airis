import ArgumentParser
import Foundation
import AppKit

struct CropCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "crop",
        abstract: "Crop images to a specific region",
        discussion: """
            Crop images by specifying a rectangular region.
            Coordinates use top-left origin (standard screen coordinates).

            COORDINATE SYSTEM:
              Origin (0,0) is at top-left corner
              X increases to the right
              Y increases downward

            QUICK START:
              airis edit crop photo.jpg --x 100 --y 200 --width 800 --height 600 -o cropped.jpg

            EXAMPLES:
              # Crop specific region
              airis edit crop photo.jpg --x 100 --y 200 --width 800 --height 600 -o cropped.jpg

              # Crop from origin
              airis edit crop photo.jpg --width 1000 --height 1000 -o square.jpg

              # Crop and open result
              airis edit crop photo.jpg --x 50 --y 50 --width 500 --height 500 -o thumb.png --open

            VALIDATION:
              The crop region must be within the image bounds.
              If the region extends beyond the image, an error is returned.

            OUTPUT:
              Supports PNG, JPEG, HEIC, TIFF output formats.
              Format is determined by output file extension.
            """
    )

    @Argument(help: "Input image path")
    var input: String

    @Option(name: [.short, .long], help: "Output path")
    var output: String

    @Option(name: .customLong("x"), help: "X coordinate of crop region (default: 0)")
    var cropX: Int = 0

    @Option(name: .customLong("y"), help: "Y coordinate of crop region (default: 0)")
    var cropY: Int = 0

    @Option(name: .long, help: "Width of crop region (required)")
    var width: Int

    @Option(name: .long, help: "Height of crop region (required)")
    var height: Int

    @Option(name: .long, help: "Output quality for JPEG/HEIC (0.0-1.0)")
    var quality: Float = 0.9

    @Flag(name: .long, help: "Open result after processing")
    var open: Bool = false

    @Flag(name: .long, help: "Overwrite existing output file")
    var force: Bool = false

    func run() async throws {
        let inputURL = try FileUtils.validateImageFile(at: input)

        let outputURL = URL(fileURLWithPath: FileUtils.absolutePath(output))
        let outputFormat = FileUtils.getExtension(from: output).lowercased()

        // 检查输出文件是否已存在
        if FileManager.default.fileExists(atPath: outputURL.path) && !force {
            throw AirisError.invalidPath("Output file already exists. Use --force to overwrite: \(output)")
        }

        // 确保输出目录存在
        try FileUtils.ensureDirectory(for: outputURL.path)

        // 获取原始图像信息
        let imageIO = ServiceContainer.shared.imageIOService
        let imageInfo = try imageIO.getImageInfo(at: inputURL)
        let originalWidth = imageInfo.width
        let originalHeight = imageInfo.height

        // 验证裁剪区域
        guard cropX >= 0 && cropY >= 0 else {
            throw AirisError.invalidPath("Crop coordinates must be non-negative. Got: x=\(cropX), y=\(cropY)")
        }

        guard width > 0 && height > 0 else {
            throw AirisError.invalidPath("Crop dimensions must be positive. Got: \(width)×\(height)")
        }

        guard cropX + width <= originalWidth && cropY + height <= originalHeight else {
            throw AirisError.invalidPath(
                "Crop region (\(cropX),\(cropY) \(width)×\(height)) exceeds image bounds (\(originalWidth)×\(originalHeight))"
            )
        }

        // 显示处理信息
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("✂️  " + Strings.get("edit.crop.title"))
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 " + Strings.get("edit.input") + ": \(inputURL.lastPathComponent)")
        print("💾 " + Strings.get("edit.output") + ": \(output)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        print("📏 " + Strings.get("edit.crop.original") + ": \(originalWidth) × \(originalHeight)")
        print("📍 " + Strings.get("edit.crop.region") + ": (\(cropX), \(cropY)) → \(width) × \(height)")
        print("")
        print("⏳ " + Strings.get("info.processing"))

        // 使用 CoreImageService 进行裁剪
        let coreImage = ServiceContainer.shared.coreImageService

        // 注意：CoreImage 坐标系原点在左下角，需要转换
        // 用户输入的 Y 坐标是从顶部向下的，需要转换为从底部向上
        let ciY = originalHeight - cropY - height

        let cropRect = CGRect(x: cropX, y: ciY, width: width, height: height)

        try coreImage.applyAndSave(
            inputURL: inputURL,
            outputURL: outputURL,
            format: outputFormat,
            quality: quality
        ) { ciImage in
            coreImage.crop(ciImage: ciImage, rect: cropRect)
        }

        print("")
        print("✅ " + Strings.get("info.saved_to", output))

        // 显示输出图像信息
        let outputInfo = try imageIO.getImageInfo(at: outputURL)
        print("📐 " + Strings.get("edit.crop.result") + ": \(outputInfo.width) × \(outputInfo.height)")

        if let fileSize = FileUtils.getFormattedFileSize(at: outputURL.path) {
            print("📦 " + Strings.get("info.file_size", fileSize))
        }

        // 打开结果
        if open {
            NSWorkspace.openForCLI(outputURL)
        }
    }
}
