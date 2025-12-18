import AppKit
import ArgumentParser
import Foundation

struct ScanCommand: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "scan",
            abstract: HelpTextFactory.text(
                en: "Scan documents with perspective correction",
                cn: "文档扫描（自动透视矫正）"
            ),
            discussion: helpDiscussion(
                en: """
                Detect document edges and apply perspective correction.
                Automatically finds rectangular documents and corrects for angle/perspective.

                QUICK START:
                  airis edit scan document.jpg -o scanned.png

                EXAMPLES:
                  # Basic document scanning
                  airis edit scan photo_of_document.jpg -o scanned.png

                  # Scan and open result
                  airis edit scan receipt.png -o receipt_scan.png --open

                  # Force overwrite existing file
                  airis edit scan page.heic -o page_scan.png --force

                OUTPUT:
                  Corrected rectangular document image with perspective fixed

                NOTE:
                  Works best with documents on contrasting backgrounds.
                  The document should be clearly visible in the image.
                """,
                cn: """
                检测文档边缘并进行透视校正，生成“扫描件”效果。
                会自动寻找矩形文档区域，并纠正拍摄角度/透视畸变。

                QUICK START:
                  airis edit scan document.jpg -o scanned.png

                EXAMPLES:
                  # 基础扫描
                  airis edit scan photo_of_document.jpg -o scanned.png

                  # 扫描并自动打开
                  airis edit scan receipt.png -o receipt_scan.png --open

                  # 覆盖已存在文件
                  airis edit scan page.heic -o page_scan.png --force

                OUTPUT:
                  输出为已透视矫正的矩形文档图片

                NOTE:
                  对“文档与背景对比明显、文档边缘清晰可见”的图片效果更好。
                """
            )
        )
    }

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

        // 显示处理信息
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📄 " + Strings.get("edit.scan.title"))
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 " + Strings.get("edit.input") + ": \(inputURL.lastPathComponent)")
        print("💾 " + Strings.get("edit.output") + ": \(output)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        print("⏳ " + Strings.get("edit.scan.detecting"))

        // 使用 VisionService 检测矩形
        let vision = ServiceContainer.shared.visionService
        var rectangles = try await vision.detectRectangles(at: inputURL)
        #if DEBUG
            if ProcessInfo.processInfo.environment["AIRIS_FORCE_SCAN_NO_RECT"] == "1" {
                rectangles = []
            }
        #endif

        guard let rect = rectangles.first else {
            throw AirisError.noResultsFound
        }

        print("✓ " + Strings.get("edit.scan.found", String(format: "%.0f%%", rect.confidence * 100)))
        print("⏳ " + Strings.get("edit.scan.correcting"))

        // 加载图像
        let imageIO = ServiceContainer.shared.imageIOService
        let cgImage = try imageIO.loadImage(at: inputURL)
        let ciImage = CIImage(cgImage: cgImage)
        let extent = ciImage.extent

        // 将归一化坐标转换为像素坐标
        let topLeft = CGPoint(
            x: rect.topLeft.x * extent.width,
            y: rect.topLeft.y * extent.height
        )
        let topRight = CGPoint(
            x: rect.topRight.x * extent.width,
            y: rect.topRight.y * extent.height
        )
        let bottomLeft = CGPoint(
            x: rect.bottomLeft.x * extent.width,
            y: rect.bottomLeft.y * extent.height
        )
        let bottomRight = CGPoint(
            x: rect.bottomRight.x * extent.width,
            y: rect.bottomRight.y * extent.height
        )

        // 应用透视校正
        let coreImage = ServiceContainer.shared.coreImageService
        #if DEBUG
            let forcePerspectiveNil = ProcessInfo.processInfo.environment["AIRIS_FORCE_SCAN_PERSPECTIVE_NIL"] == "1"
            let corrected = forcePerspectiveNil ? nil : coreImage.perspectiveCorrection(
                ciImage: ciImage,
                topLeft: topLeft,
                topRight: topRight,
                bottomLeft: bottomLeft,
                bottomRight: bottomRight
            )
        #else
            let corrected = coreImage.perspectiveCorrection(
                ciImage: ciImage,
                topLeft: topLeft,
                topRight: topRight,
                bottomLeft: bottomLeft,
                bottomRight: bottomRight
            )
        #endif

        guard let corrected else {
            throw AirisError.imageEncodeFailed
        }

        // 渲染并保存
        #if DEBUG
            let forceRenderNil = ProcessInfo.processInfo.environment["AIRIS_FORCE_SCAN_RENDER_NIL"] == "1"
            let outputCGImage = forceRenderNil ? nil : coreImage.render(ciImage: corrected)
        #else
            let outputCGImage = coreImage.render(ciImage: corrected)
        #endif

        guard let outputCGImage else {
            throw AirisError.imageEncodeFailed
        }

        let outputFormat = FileUtils.getExtension(from: output)
        try imageIO.saveImage(outputCGImage, to: outputURL, format: outputFormat)

        print("")
        print("✅ " + Strings.get("info.saved_to", output))

        // 显示结果尺寸
        print("📐 " + Strings.get("edit.scan.result_size", outputCGImage.width, outputCGImage.height))

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
