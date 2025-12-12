import ArgumentParser
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import AppKit

struct PaletteCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "palette",
        abstract: "Extract color palette from images",
        discussion: """
            Extract dominant colors from an image using K-means clustering.
            Returns a color palette with hex codes and RGB values.

            QUICK START:
              airis analyze palette photo.jpg

            EXAMPLES:
              # Extract 5 colors (default)
              airis analyze palette photo.jpg

              # Extract custom number of colors
              airis analyze palette sunset.jpg --count 8

              # JSON output for scripting
              airis analyze palette image.png --format json

              # Include average color
              airis analyze palette photo.jpg --include-average

            OUTPUT FORMAT (table):
              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              🎨 色彩提取
              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              📁 文件: sunset.jpg
              🔢 提取数量: 5
              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

              主色调:
                1. #FF6B35  RGB(255, 107, 53)   ████
                2. #3498DB  RGB(52, 152, 219)   ████
                3. #2ECC71  RGB(46, 204, 113)   ████
                4. #F39C12  RGB(243, 156, 18)   ████
                5. #9B59B6  RGB(155, 89, 182)   ████

            OUTPUT FORMAT (json):
              {
                "colors": [
                  {"hex": "#FF6B35", "rgb": [255, 107, 53]},
                  ...
                ]
              }

            ALGORITHM:
              Uses K-means clustering (CIKMeans) for perceptually accurate
              color extraction. The algorithm groups similar pixels and
              returns cluster centroids as dominant colors.

            NOTES:
              - Colors are sorted by dominance/frequency
              - Count range: 1-16 (more colors = longer processing)
              - All processing is done locally using CoreImage
            """
    )

    @Argument(help: "Path to the image file")
    var imagePath: String

    @Option(name: .shortAndLong, help: "Number of colors to extract (1-16, default: 5)")
    var count: Int = 5

    @Option(name: .long, help: "Output format: table (default), json")
    var format: String = "table"

    @Flag(name: .long, help: "Include average color in output")
    var includeAverage: Bool = false

    func run() async throws {
        let url = try FileUtils.validateImageFile(at: imagePath)

        // 验证颜色数量
        let colorCount = max(1, min(16, count))

        // 显示参数总览
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🎨 色彩提取")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 文件: \(url.lastPathComponent)")
        print("🔢 提取数量: \(colorCount)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")

        // 加载图像
        guard let ciImage = CIImage(contentsOf: url) else {
            throw AirisError.imageDecodeFailed
        }

        // 提取颜色
        var result = PaletteResult(colors: [])

        // 提取主色调（使用 K-means）
        let dominantColors = extractDominantColors(from: ciImage, count: colorCount)
        result.colors = dominantColors

        // 可选：提取平均颜色
        if includeAverage {
            if let avgColor = extractAverageColor(from: ciImage) {
                result.averageColor = avgColor
            }
        }

        // 输出结果
        if format.lowercased() == "json" {
            printJSON(result: result)
        } else {
            printTable(result: result)
        }
    }

    // MARK: - 色彩提取

    /// 使用 K-means 提取主色调
    private func extractDominantColors(from ciImage: CIImage, count: Int) -> [ColorInfo] {
        // 为了性能，先缩小图像
        let scaledImage = scaleImageForProcessing(ciImage, maxDimension: 300)

        let filter = CIFilter.kMeans()
        filter.inputImage = scaledImage
        filter.extent = scaledImage.extent
        filter.count = count
        filter.passes = 5
        filter.perceptual = true

        let forceNil = ProcessInfo.processInfo.environment["AIRIS_FORCE_PALETTE_OUTPUT_NIL"] == "1"
        let paletteImage = forceNil ? nil : filter.outputImage

        guard let paletteImage else {
            return []
        }

        // 提取颜色数据
        return extractColorsFromPaletteImage(paletteImage, count: count)
    }

    /// 提取平均颜色
    private func extractAverageColor(from ciImage: CIImage) -> ColorInfo? {
        let scaledImage = scaleImageForProcessing(ciImage, maxDimension: 300)

        let filter = CIFilter.areaAverage()
        filter.inputImage = scaledImage
        filter.extent = scaledImage.extent

        let forceNil = ProcessInfo.processInfo.environment["AIRIS_FORCE_PALETTE_AVG_NIL"] == "1"
        let outputImage = forceNil ? nil : filter.outputImage

        guard let outputImage else {
            return nil
        }

        let colors = extractColorsFromPaletteImage(outputImage, count: 1)
        return colors.first
    }

    /// 缩放图像以提高处理性能
    private func scaleImageForProcessing(_ ciImage: CIImage, maxDimension: CGFloat) -> CIImage {
        let extent = ciImage.extent
        let scale = min(maxDimension / extent.width, maxDimension / extent.height, 1.0)

        if scale < 1.0 {
            let filter = CIFilter.lanczosScaleTransform()
            filter.inputImage = ciImage
            filter.scale = Float(scale)
            filter.aspectRatio = 1.0
            let forceNil = ProcessInfo.processInfo.environment["AIRIS_FORCE_PALETTE_SCALE_NIL"] == "1"
            let output = forceNil ? nil : filter.outputImage
            return output ?? ciImage
        }

        return ciImage
    }

    /// 从调色板图像提取颜色
    private func extractColorsFromPaletteImage(_ paletteImage: CIImage, count: Int) -> [ColorInfo] {
        let context = CIContext(options: [.workingColorSpace: NSNull()])

        // 分配位图缓冲区
        var bitmap = [UInt8](repeating: 0, count: count * 4)
        let bounds = CGRect(x: 0, y: 0, width: count, height: 1)

        context.render(
            paletteImage,
            toBitmap: &bitmap,
            rowBytes: count * 4,
            bounds: bounds,
            format: .RGBA8,
            colorSpace: CGColorSpace(name: CGColorSpace.sRGB)
        )

        // 解析颜色
        var colors: [ColorInfo] = []
        for i in 0..<count {
            let offset = i * 4
            let r = Int(bitmap[offset])
            let g = Int(bitmap[offset + 1])
            let b = Int(bitmap[offset + 2])

            // 跳过无效颜色（全黑或全透明）
            if r == 0 && g == 0 && b == 0 && i > 0 {
                continue
            }

            let hex = String(format: "#%02X%02X%02X", r, g, b)
            colors.append(ColorInfo(hex: hex, r: r, g: g, b: b))
        }

        return colors
    }

    // MARK: - 输出

    private func printTable(result: PaletteResult) {
        if let avgColor = result.averageColor {
            print("平均颜色:")
            printColorRow(color: avgColor, index: nil)
            print("")
        }

        if !result.colors.isEmpty {
            print("主色调:")
            for (index, color) in result.colors.enumerated() {
                printColorRow(color: color, index: index + 1)
            }
        } else {
            print("⚠️ 未能提取到颜色")
        }
    }

    private func printColorRow(color: ColorInfo, index: Int?) {
        let indexStr = index.map { "\($0). " } ?? "   "
        let rgbStr = "RGB(\(color.r), \(color.g), \(color.b))"
        let colorBlock = generateColorBlock(r: color.r, g: color.g, b: color.b)
        print("  \(indexStr)\(color.hex)  \(rgbStr.padding(toLength: 18, withPad: " ", startingAt: 0)) \(colorBlock)")
    }

    /// 生成 ANSI 颜色方块
    private func generateColorBlock(r: Int, g: Int, b: Int) -> String {
        // 使用 ANSI 24-bit 真彩色
        return "\u{001B}[48;2;\(r);\(g);\(b)m    \u{001B}[0m"
    }

    private func printJSON(result: PaletteResult) {
        var dict: [String: Any] = [:]

        if let avgColor = result.averageColor {
            dict["average_color"] = [
                "hex": avgColor.hex,
                "rgb": [avgColor.r, avgColor.g, avgColor.b]
            ]
        }

        dict["colors"] = result.colors.map { color in
            [
                "hex": color.hex,
                "rgb": [color.r, color.g, color.b]
            ] as [String: Any]
        }

        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    }

    // MARK: - 数据结构

    struct PaletteResult {
        var colors: [ColorInfo]
        var averageColor: ColorInfo?
    }

    struct ColorInfo {
        let hex: String
        let r: Int
        let g: Int
        let b: Int
    }
}
