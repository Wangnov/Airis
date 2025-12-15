import ArgumentParser
import Foundation
import ImageIO

struct InfoCommand: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
        commandName: "info",
        abstract: HelpTextFactory.text(
            en: "Display basic image information",
            cn: "显示图像基础信息"
        ),
        discussion: helpDiscussion(
            en: """
                Show image dimensions, DPI, color space, and file metadata.

                QUICK START:
                  airis analyze info photo.jpg

                EXAMPLES:
                  # Display basic info in table format
                  airis analyze info image.jpg

                  # Output as JSON for scripting
                  airis analyze info photo.png --format json

                  # Show info for HEIC image
                  airis analyze info IMG_0001.heic

                OUTPUT FORMAT (table):
                  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  ℹ️  图像信息
                  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  📁 文件: photo.jpg
                  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

                  尺寸: 1920 × 1080 像素
                  DPI: 72
                  色彩模型: RGB
                  位深度: 8
                  包含透明通道: 否
                  文件大小: 2.3 MB

                OUTPUT FORMAT (json):
                  {
                    "width": 1920,
                    "height": 1080,
                    "dpi_width": 72,
                    "dpi_height": 72,
                    "color_model": "RGB",
                    "depth": 8,
                    "has_alpha": false,
                    "file_size": 2400000
                  }

                SUPPORTED FORMATS:
                  JPEG, PNG, HEIC, HEIF, TIFF, WebP, GIF, BMP
                """,
            cn: """
                显示图像尺寸、DPI、色彩模型、位深度、透明通道与文件大小等信息。

                QUICK START:
                  airis analyze info photo.jpg

                EXAMPLES:
                  # 表格输出（默认）
                  airis analyze info image.jpg

                  # JSON 输出（便于脚本解析）
                  airis analyze info photo.png --format json

                  # 查看 HEIC 信息
                  airis analyze info IMG_0001.heic

                OUTPUT FORMAT (table):
                  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  ℹ️  图像信息
                  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  📁 文件: photo.jpg
                  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

                  尺寸: 1920 × 1080 像素
                  DPI: 72
                  色彩模型: RGB
                  位深度: 8
                  包含透明通道: 否
                  文件大小: 2.3 MB

                OUTPUT FORMAT (json):
                  {
                    "width": 1920,
                    "height": 1080,
                    "dpi_width": 72,
                    "dpi_height": 72,
                    "color_model": "RGB",
                    "depth": 8,
                    "has_alpha": false,
                    "file_size": 2400000
                  }

                SUPPORTED FORMATS:
                  JPEG, PNG, HEIC, HEIF, TIFF, WebP, GIF, BMP
                """
        )
    )
    }

    @Argument(help: HelpTextFactory.help(en: "Path to the image file", cn: "输入图片路径"))
    var imagePath: String

    @Option(name: .long, help: HelpTextFactory.help(en: "Output format: table (default), json", cn: "输出格式：table（默认）或 json"))
    var format: String = "table"

    func run() async throws {
        let url = try FileUtils.validateImageFile(at: imagePath)
        let imageIO = ServiceContainer.shared.imageIOService

        let info = try imageIO.getImageInfo(at: url)

        let outputFormat = OutputFormat.parse(format)
        let showHumanOutput = AirisOutput.shouldPrintHumanOutput(format: outputFormat)

        AirisOutput.printBanner([
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
            "ℹ️  图像信息",
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
            "📁 文件: \(url.lastPathComponent)",
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        ], enabled: showHumanOutput)

        if outputFormat == .json {
            printJSON(info: info, url: url)
        } else if showHumanOutput {
            printTable(info: info, url: url)
        }
    }

    private func printTable(info: ImageIOService.ImageInfo, url: URL) {
        print(Strings.get("info.dimension", info.width, info.height))
        print(Strings.get("info.dpi", info.dpiWidth))

        let colorModel = ProcessInfo.processInfo.environment["AIRIS_FORCE_INFO_NO_COLOR"] == "1" ? nil : info.colorModel
        if let colorModel {
            print("色彩模型: \(colorModel)")
        }

        let depth = ProcessInfo.processInfo.environment["AIRIS_FORCE_INFO_NO_COLOR"] == "1" ? nil : info.depth
        if let depth {
            print("位深度: \(depth)")
        }

        print("包含透明通道: \(info.hasAlpha ? "是" : "否")")

        // 方向信息
        var orientationToDescribe = info.orientation
        if ProcessInfo.processInfo.environment["AIRIS_FORCE_UNKNOWN_ORIENTATION"] == "1",
           let unknown = CGImagePropertyOrientation(rawValue: 999) {
            orientationToDescribe = unknown
        }

        let orientationDesc = describeOrientation(orientationToDescribe)
        let alwaysShowOrientation = ProcessInfo.processInfo.environment["AIRIS_TEST_MODE"] == "1"
        if alwaysShowOrientation || orientationDesc != "正常" {
            print("方向: \(orientationDesc)")
        }

        if ProcessInfo.processInfo.environment["AIRIS_FORCE_INFO_NO_FILESIZE"] == "1" {
            // 覆盖无法获取文件大小的分支
        } else if let fileSize = FileUtils.getFormattedFileSize(at: url.path) {
            print(Strings.get("info.file_size", fileSize))
        }
    }

    private func printJSON(info: ImageIOService.ImageInfo, url: URL) {
        var dict: [String: Any] = [
            "width": info.width,
            "height": info.height,
            "dpi_width": info.dpiWidth,
            "dpi_height": info.dpiHeight,
            "has_alpha": info.hasAlpha,
            "orientation": info.orientation.rawValue
        ]

        if let colorModel = info.colorModel {
            dict["color_model"] = colorModel
        }

        if let depth = info.depth {
            dict["depth"] = depth
        }

        if let fileSize = FileUtils.getFileSize(at: url.path) {
            dict["file_size"] = fileSize
        }

        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    }

    private func describeOrientation(_ orientation: CGImagePropertyOrientation) -> String {
        // 使用映射表减少分支，便于测试覆盖所有方向
        let mapping: [CGImagePropertyOrientation: String] = [
            .up: "正常",
            .upMirrored: "水平翻转",
            .down: "旋转180°",
            .downMirrored: "垂直翻转",
            .leftMirrored: "逆时针90°+水平翻转",
            .right: "顺时针90°",
            .rightMirrored: "顺时针90°+水平翻转",
            .left: "逆时针90°"
        ]
        return mapping[orientation] ?? "未知"
    }

    #if DEBUG
    /// 测试辅助
    static func testDescribeOrientation(_ orientation: CGImagePropertyOrientation) -> String {
        InfoCommand().describeOrientation(orientation)
    }
    #endif
}
