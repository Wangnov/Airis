import AppKit
import ArgumentParser
import Foundation

struct ChromeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "chrome",
        abstract: HelpTextFactory.text(
            en: "Apply chrome photo effect",
            cn: "鲜艳对比（Chrome）"
        ),
        discussion: helpDiscussion(
            en: """
            Apply Chrome photo effect using CoreImage.

            Creates a dramatic look with:
            - Enhanced contrast
            - Boosted colors
            - Vivid, punchy appearance

            This is a one-click effect with no adjustable parameters.

            QUICK START:
              airis edit filter chrome photo.jpg -o chrome.png

            EXAMPLES:
              # Apply chrome effect
              airis edit filter chrome photo.jpg -o chrome.png

              # Process and open result
              airis edit filter chrome landscape.jpg -o vivid.png --open

            OUTPUT:
              Chrome-styled image in the specified format
            """,
            cn: """
            使用 Photo Effect Chrome 一键增强对比与色彩饱和度（更“鲜艳”）。

            QUICK START:
              airis edit filter chrome photo.jpg -o chrome.png

            EXAMPLES:
              airis edit filter chrome landscape.jpg -o vivid.png --open
            """
        )
    )

    @Argument(help: HelpTextFactory.help(en: "Input image path", cn: "输入图片路径"))
    var input: String

    @Option(name: [.short, .long], help: HelpTextFactory.help(en: "Output path", cn: "输出路径"))
    var output: String

    @Flag(name: .long, help: HelpTextFactory.help(en: "Open result after processing", cn: "处理完成后打开输出文件"))
    var open: Bool = false

    @Flag(name: .long, help: HelpTextFactory.help(en: "Overwrite existing output file", cn: "覆盖已存在的输出文件"))
    var force: Bool = false

    func run() async throws {
        let inputURL = try FileUtils.validateImageFile(at: input)
        let outputURL = URL(fileURLWithPath: FileUtils.absolutePath(output))

        // 检查输出文件是否已存在
        if FileManager.default.fileExists(atPath: outputURL.path), !force {
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
        print("✨ " + Strings.get("filter.chrome.title"))
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 " + Strings.get("edit.input") + ": \(inputURL.lastPathComponent)")
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
                coreImage.photoEffectChrome(ciImage: ciImage)
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
}
