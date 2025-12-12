import ArgumentParser
import Foundation
import AppKit

struct ScanCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "scan",
        abstract: "Scan documents with perspective correction",
        discussion: """
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
            """
    )

    @Argument(help: "Input image path")
    var input: String

    @Option(name: [.short, .long], help: "Output path")
    var output: String

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
