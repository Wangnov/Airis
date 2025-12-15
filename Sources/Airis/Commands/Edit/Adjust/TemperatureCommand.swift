import ArgumentParser
import Foundation
import AppKit

struct TemperatureCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "temperature",
        abstract: HelpTextFactory.text(
            en: "Adjust color temperature and tint (white balance)",
            cn: "调整色温与色调（白平衡）"
        ),
        discussion: helpDiscussion(
            en: """
                Adjust white balance using CITemperatureAndTint filter.
                Simulates camera white balance adjustment.

                PARAMETERS:
                  Temperature: -5000 to 5000 (0 = unchanged)
                              Negative = cooler/bluer
                              Positive = warmer/yellower
                  Tint:       -150 to 150 (0 = unchanged)
                              Negative = greener
                              Positive = more magenta

                QUICK START:
                  airis edit adjust temperature photo.jpg --temp 1000 -o warm.jpg

                EXAMPLES:
                  # Warm up a photo (golden hour effect)
                  airis edit adjust temperature photo.jpg --temp 2000 -o warm.jpg

                  # Cool down a photo (blue tone)
                  airis edit adjust temperature photo.jpg --temp -1500 -o cool.jpg

                  # Add magenta tint (sunset effect)
                  airis edit adjust temperature photo.jpg --temp 1500 --tint 30 -o sunset.jpg

                  # Correct greenish fluorescent lighting
                  airis edit adjust temperature indoor.jpg --tint 20 -o corrected.jpg

                  # Create dramatic blue-cold effect
                  airis edit adjust temperature portrait.jpg --temp -2500 --tint -20 -o dramatic.jpg

                NOTE:
                  The filter uses 6500K as neutral reference point.
                  Temperature adjustments are relative to this neutral point.

                OUTPUT:
                  Supports PNG, JPEG, HEIC, TIFF output formats.
                  Format is determined by output file extension.
                """,
            cn: """
                使用 CITemperatureAndTint 调整白平衡（色温/色调）。

                参数范围：
                  temp: -5000 ~ 5000（默认：0；负值偏冷、正值偏暖）
                  tint:  -150 ~ 150（默认：0；负值偏绿、正值偏洋红）

                QUICK START:
                  airis edit adjust temperature photo.jpg --temp 1000 -o warm.jpg

                EXAMPLES:
                  airis edit adjust temperature photo.jpg --temp 2000 -o warm.jpg
                  airis edit adjust temperature photo.jpg --temp -1500 -o cool.jpg
                  airis edit adjust temperature indoor.jpg --tint 20 -o corrected.jpg
                """
        )
    )

    @Argument(help: HelpTextFactory.help(en: "Input image path", cn: "输入图片路径"))
    var input: String

    @Option(name: [.short, .long], help: HelpTextFactory.help(en: "Output path", cn: "输出路径"))
    var output: String

    @Option(name: .long, help: HelpTextFactory.help(en: "Temperature adjustment (-5000 to 5000, default: 0)", cn: "色温（-5000~5000，默认：0）"))
    var temp: Double = 0

    @Option(name: .long, help: HelpTextFactory.help(en: "Tint adjustment (-150 to 150, default: 0)", cn: "色调（-150~150，默认：0）"))
    var tint: Double = 0

    @Option(name: .long, help: HelpTextFactory.help(en: "Output quality for JPEG/HEIC (0.0-1.0)", cn: "输出质量（JPEG/HEIC：0.0-1.0）"))
    var quality: Float = 0.9

    @Flag(name: .long, help: HelpTextFactory.help(en: "Open result after processing", cn: "处理完成后打开输出文件"))
    var open: Bool = false

    @Flag(name: .long, help: HelpTextFactory.help(en: "Overwrite existing output file", cn: "覆盖已存在的输出文件"))
    var force: Bool = false

    func run() async throws {
        // 参数验证
        guard temp >= -5000 && temp <= 5000 else {
            throw AirisError.invalidPath("Temperature must be -5000 to 5000, got: \(temp)")
        }
        guard tint >= -150 && tint <= 150 else {
            throw AirisError.invalidPath("Tint must be -150 to 150, got: \(tint)")
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
        print("🌡️  " + Strings.get("edit.adjust.temperature.title"))
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 " + Strings.get("edit.input") + ": \(inputURL.lastPathComponent)")
        print("💾 " + Strings.get("edit.output") + ": \(output)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        let tempDesc = temp > 0 ? "warmer" : (temp < 0 ? "cooler" : "unchanged")
        let tintDesc = tint > 0 ? "magenta" : (tint < 0 ? "green" : "unchanged")
        print("🔥 " + Strings.get("edit.adjust.temp") + ": \(String(format: "%+.0f", temp)) (\(tempDesc))")
        print("🎨 " + Strings.get("edit.adjust.tint") + ": \(String(format: "%+.0f", tint)) (\(tintDesc))")
        print("")
        print("⏳ " + Strings.get("info.processing"))

        // 应用色温调整
        let coreImage = ServiceContainer.shared.coreImageService

        try coreImage.applyAndSave(
            inputURL: inputURL,
            outputURL: outputURL,
            format: outputFormat,
            quality: quality
        ) { ciImage in
            coreImage.adjustTemperatureAndTint(ciImage: ciImage, temperature: temp, tint: tint)
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
