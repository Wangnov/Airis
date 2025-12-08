import ArgumentParser
import Foundation
import ImageIO

struct InfoCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "info",
        abstract: "Display basic image information",
        discussion: """
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
            """
    )

    @Argument(help: "Path to the image file")
    var imagePath: String

    @Option(name: .long, help: "Output format: table (default), json")
    var format: String = "table"

    func run() async throws {
        let url = try FileUtils.validateImageFile(at: imagePath)
        let imageIO = ServiceContainer.shared.imageIOService

        let info = try imageIO.getImageInfo(at: url)

        // 显示参数总览
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("ℹ️  图像信息")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 文件: \(url.lastPathComponent)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")

        if format.lowercased() == "json" {
            printJSON(info: info, url: url)
        } else {
            printTable(info: info, url: url)
        }
    }

    private func printTable(info: ImageIOService.ImageInfo, url: URL) {
        print(Strings.get("info.dimension", info.width, info.height))
        print(Strings.get("info.dpi", info.dpiWidth))

        if let colorModel = info.colorModel {
            print("色彩模型: \(colorModel)")
        }

        if let depth = info.depth {
            print("位深度: \(depth)")
        }

        print("包含透明通道: \(info.hasAlpha ? "是" : "否")")

        // 方向信息
        let orientationDesc = describeOrientation(info.orientation)
        if orientationDesc != "正常" {
            print("方向: \(orientationDesc)")
        }

        if let fileSize = FileUtils.getFormattedFileSize(at: url.path) {
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
        switch orientation {
        case .up: return "正常"
        case .upMirrored: return "水平翻转"
        case .down: return "旋转180°"
        case .downMirrored: return "垂直翻转"
        case .leftMirrored: return "逆时针90°+水平翻转"
        case .right: return "顺时针90°"
        case .rightMirrored: return "顺时针90°+水平翻转"
        case .left: return "逆时针90°"
        @unknown default: return "未知"
        }
    }
}
