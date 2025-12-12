import ArgumentParser
import Foundation
import AppKit

struct ExposureCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "exposure",
        abstract: "Adjust image exposure (EV value)",
        discussion: """
            Adjust image exposure using CIExposureAdjust filter.
            Uses logarithmic adjustment similar to camera EV settings.

            PARAMETERS:
              EV: -10.0 to 10.0 (0 = unchanged)
                  Each +1.0 EV doubles the brightness
                  Each -1.0 EV halves the brightness

            QUICK START:
              airis edit adjust exposure dark.jpg --ev 1.5 -o brighter.jpg

            EXAMPLES:
              # Brighten underexposed photo (+1.5 EV)
              airis edit adjust exposure dark.jpg --ev 1.5 -o brighter.jpg

              # Darken overexposed photo (-1.0 EV)
              airis edit adjust exposure bright.jpg --ev -1.0 -o darker.jpg

              # Subtle brightness increase (+0.5 EV)
              airis edit adjust exposure photo.jpg --ev 0.5 -o enhanced.jpg

              # Strong exposure boost for very dark images
              airis edit adjust exposure night.jpg --ev 3.0 -o night_bright.jpg

            NOTE:
              Exposure adjustment is more natural than brightness adjustment
              as it simulates camera exposure behavior.

            OUTPUT:
              Supports PNG, JPEG, HEIC, TIFF output formats.
              Format is determined by output file extension.
            """
    )

    @Argument(help: "Input image path")
    var input: String

    @Option(name: [.short, .long], help: "Output path")
    var output: String

    @Option(name: .long, help: "Exposure value in EV (-10.0 to 10.0, default: 0)")
    var ev: Double = 0

    @Option(name: .long, help: "Output quality for JPEG/HEIC (0.0-1.0)")
    var quality: Float = 0.9

    @Flag(name: .long, help: "Open result after processing")
    var open: Bool = false

    @Flag(name: .long, help: "Overwrite existing output file")
    var force: Bool = false

    func run() async throws {
        // 参数验证
        guard ev >= -10.0 && ev <= 10.0 else {
            throw AirisError.invalidPath("EV must be -10.0 to 10.0, got: \(ev)")
        }

        let inputURL = try FileUtils.validateImageFile(at: input)
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
        print("📷 " + Strings.get("edit.adjust.exposure.title"))
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 " + Strings.get("edit.input") + ": \(inputURL.lastPathComponent)")
        print("💾 " + Strings.get("edit.output") + ": \(output)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        print("📊 " + Strings.get("edit.adjust.ev") + ": \(String(format: "%+.2f", ev)) EV")
        print("")
        print("⏳ " + Strings.get("info.processing"))

        // 应用曝光调整
        let coreImage = ServiceContainer.shared.coreImageService

        try coreImage.applyAndSave(
            inputURL: inputURL,
            outputURL: outputURL,
            format: outputFormat,
            quality: quality
        ) { ciImage in
            coreImage.adjustExposure(ciImage: ciImage, ev: ev)
        }

        print("")
        print("✅ " + Strings.get("info.saved_to", output))

        if let fileSize = FileUtils.getFormattedFileSize(at: outputURL.path) {
            print("📦 " + Strings.get("info.file_size", fileSize))
        }

        // 打开结果
        if open {
            NSWorkspace.openForCLI(outputURL)
        }
    }
}
