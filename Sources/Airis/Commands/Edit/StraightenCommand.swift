import ArgumentParser
import Foundation
import AppKit

struct StraightenCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "straighten",
        abstract: "Automatically straighten tilted images",
        discussion: """
            Detect and correct image tilt using horizon detection.
            Automatically finds the horizon line and rotates to level.

            QUICK START:
              airis edit straighten tilted.jpg -o straight.jpg

            EXAMPLES:
              # Auto-straighten a photo
              airis edit straighten landscape.jpg -o leveled.jpg

              # Straighten and open result
              airis edit straighten photo.png -o corrected.png --open

              # Manual angle override (in degrees, positive = counterclockwise)
              airis edit straighten image.jpg --angle 2.5 -o fixed.jpg

            PARAMETERS:
              --angle: Manual rotation angle in degrees (overrides auto-detection)

            OUTPUT:
              Rotated image with corrected horizon

            NOTE:
              Works best with images containing clear horizon lines or
              strong horizontal/vertical features.
            """
    )

    @Argument(help: "Input image path")
    var input: String

    @Option(name: [.short, .long], help: "Output path")
    var output: String

    @Option(name: .long, help: "Manual rotation angle in degrees (overrides auto-detection)")
    var angle: Double?

    @Flag(name: .long, help: "Open result after processing")
    var open: Bool = false

    @Flag(name: .long, help: "Overwrite existing output file")
    var force: Bool = false

    func run() async throws {
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
        print("📐 " + Strings.get("edit.straighten.title"))
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 " + Strings.get("edit.input") + ": \(inputURL.lastPathComponent)")
        print("💾 " + Strings.get("edit.output") + ": \(output)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")

        var rotationAngle: Double

        if let manualAngle = angle {
            // 使用手动指定的角度
            rotationAngle = manualAngle
            print("📐 " + Strings.get("edit.straighten.manual", String(format: "%.2f", rotationAngle)))
        } else {
            // 自动检测倾斜角度
            print("⏳ " + Strings.get("edit.straighten.detecting"))

            let vision = ServiceContainer.shared.visionService
            let horizon = try await vision.detectHorizon(at: inputURL)

            if let h = horizon {
                rotationAngle = Double(h.angleInDegrees)

                if abs(rotationAngle) < 0.1 {
                    print("✓ " + Strings.get("edit.straighten.already_level"))
                } else {
                    print("✓ " + Strings.get("edit.straighten.detected", String(format: "%.2f", rotationAngle)))
                }
            } else {
                print("⚠️ " + Strings.get("edit.straighten.no_horizon"))
                // 无法检测到地平线，不进行旋转
                rotationAngle = 0
            }
        }

        print("⏳ " + Strings.get("edit.straighten.rotating"))

        // 加载图像
        let imageIO = ServiceContainer.shared.imageIOService
        let cgImage = try imageIO.loadImage(at: inputURL)
        let ciImage = CIImage(cgImage: cgImage)

        // 应用旋转校正
        let coreImage = ServiceContainer.shared.coreImageService

        // 注意：地平线角度是图像倾斜的角度，需要反向旋转来校正
        let corrected = coreImage.rotateAroundCenter(ciImage: ciImage, degrees: -rotationAngle)

        // 渲染并保存
        guard let outputCGImage = coreImage.render(ciImage: corrected) else {
            throw AirisError.imageEncodeFailed
        }

        let outputFormat = FileUtils.getExtension(from: output)
        try imageIO.saveImage(outputCGImage, to: outputURL, format: outputFormat)

        print("")
        print("✅ " + Strings.get("info.saved_to", output))

        // 显示旋转信息
        if abs(rotationAngle) >= 0.1 {
            print("🔄 " + Strings.get("edit.straighten.rotated", String(format: "%.2f", -rotationAngle)))
        }

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
