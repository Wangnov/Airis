import ArgumentParser
import ImageIO
import Foundation
import UniformTypeIdentifiers

struct MetaCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "meta",
        abstract: "Read and write image EXIF metadata",
        discussion: """
            Read, display, and modify EXIF metadata in image files.
            Supports reading all standard metadata and writing common fields.

            QUICK START:
              airis analyze meta photo.jpg

            EXAMPLES:
              # Read all metadata
              airis analyze meta photo.jpg

              # Read specific category
              airis analyze meta photo.jpg --category exif
              airis analyze meta photo.jpg --category gps

              # JSON output for scripting
              airis analyze meta image.png --format json

              # Write user comment (creates copy)
              airis analyze meta photo.jpg --set-comment "My vacation photo"

              # Write to specific output file
              airis analyze meta photo.jpg --set-comment "Note" -o photo_new.jpg

              # Clear GPS data (privacy)
              airis analyze meta photo.jpg --clear-gps -o photo_clean.jpg

            OUTPUT FORMAT (table):
              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              📋 EXIF 元数据
              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              📁 文件: photo.jpg
              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

              [EXIF]
                拍摄日期: 2024-01-15 14:30:00
                相机: iPhone 15 Pro
                光圈: f/1.8
                快门: 1/120s
                ISO: 100

              [GPS]
                纬度: 31.2304° N
                经度: 121.4737° E
                海拔: 4m

            CATEGORIES:
              all   - All metadata (default)
              exif  - EXIF data (camera, exposure, date)
              gps   - GPS location data
              tiff  - TIFF tags (make, model, software)
              iptc  - IPTC data (title, keywords, copyright)

            SUPPORTED WRITE OPERATIONS:
              --set-comment    Add/modify user comment
              --clear-gps      Remove GPS location data
              --clear-all      Remove all editable metadata

            NOTES:
              - Write operations create a new file (original unchanged)
              - Some metadata is read-only (embedded by camera)
              - JPEG supports most metadata; PNG has limited support
            """
    )

    @Argument(help: "Path to the image file")
    var imagePath: String

    @Option(name: .long, help: "Metadata category: all (default), exif, gps, tiff, iptc")
    var category: String = "all"

    @Option(name: .long, help: "Output format: table (default), json")
    var format: String = "table"

    @Option(name: .long, help: "Set user comment")
    var setComment: String?

    @Flag(name: .long, help: "Clear GPS location data")
    var clearGps: Bool = false

    @Flag(name: .long, help: "Clear all editable metadata")
    var clearAll: Bool = false

    @Option(name: .shortAndLong, help: "Output file path (for write operations)")
    var output: String?

    func run() async throws {
        let url = try FileUtils.validateImageFile(at: imagePath)

        // 显示参数总览
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📋 EXIF 元数据")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 文件: \(url.lastPathComponent)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")

        // 判断是读取还是写入操作
        if setComment != nil || clearGps || clearAll {
            try writeMetadata(url: url)
        } else {
            try readMetadata(url: url)
        }
    }

    // MARK: - 读取元数据

    private func readMetadata(url: URL) throws {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else {
            throw AirisError.invalidPath(url.path)
        }

        if format.lowercased() == "json" {
            printMetadataJSON(properties: properties)
        } else {
            printMetadataTable(properties: properties)
        }
    }

    private func printMetadataTable(properties: [String: Any]) {
        let showAll = category.lowercased() == "all"

        // EXIF 数据
        if showAll || category.lowercased() == "exif" {
            if let exifDict = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] {
                print("[EXIF]")
                printExifData(exifDict)
                print("")
            }
        }

        // GPS 数据
        if showAll || category.lowercased() == "gps" {
            if let gpsDict = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
                print("[GPS]")
                printGpsData(gpsDict)
                print("")
            }
        }

        // TIFF 数据
        if showAll || category.lowercased() == "tiff" {
            if let tiffDict = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any] {
                print("[TIFF]")
                printTiffData(tiffDict)
                print("")
            }
        }

        // IPTC 数据
        if showAll || category.lowercased() == "iptc" {
            if let iptcDict = properties[kCGImagePropertyIPTCDictionary as String] as? [String: Any] {
                print("[IPTC]")
                printIptcData(iptcDict)
                print("")
            }
        }

        // 基本属性
        if showAll {
            print("[基本信息]")
            if let width = properties[kCGImagePropertyPixelWidth as String] as? Int,
               let height = properties[kCGImagePropertyPixelHeight as String] as? Int {
                print("  尺寸: \(width) × \(height)")
            }
            if let dpiWidth = properties[kCGImagePropertyDPIWidth as String] as? Int {
                print("  DPI: \(dpiWidth)")
            }
            if let colorModel = properties[kCGImagePropertyColorModel as String] as? String {
                print("  色彩模型: \(colorModel)")
            }
            if let depth = properties[kCGImagePropertyDepth as String] as? Int {
                print("  位深度: \(depth)")
            }
            if let hasAlpha = properties[kCGImagePropertyHasAlpha as String] as? Bool {
                print("  透明通道: \(hasAlpha ? "是" : "否")")
            }
            print("")
        }

        // 检查是否有数据
        let hasData = properties.keys.contains { key in
            [kCGImagePropertyExifDictionary, kCGImagePropertyGPSDictionary,
             kCGImagePropertyTIFFDictionary, kCGImagePropertyIPTCDictionary]
                .map { $0 as String }
                .contains(key)
        }

        if !hasData && category != "all" {
            print("⚠️ 未找到 \(category.uppercased()) 元数据")
        }
    }

    private func printExifData(_ exif: [String: Any]) {
        if let dateTime = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String {
            print("  拍摄日期: \(dateTime)")
        }
        if let fNumber = exif[kCGImagePropertyExifFNumber as String] as? Double {
            print("  光圈: f/\(fNumber)")
        }
        if let exposureTime = exif[kCGImagePropertyExifExposureTime as String] as? Double {
            let shutterStr = exposureTime < 1 ? "1/\(Int(1/exposureTime))s" : "\(exposureTime)s"
            print("  快门: \(shutterStr)")
        }
        if let iso = exif[kCGImagePropertyExifISOSpeedRatings as String] as? [Int], let isoValue = iso.first {
            print("  ISO: \(isoValue)")
        }
        if let focalLength = exif[kCGImagePropertyExifFocalLength as String] as? Double {
            print("  焦距: \(focalLength)mm")
        }
        if let lens = exif[kCGImagePropertyExifLensModel as String] as? String {
            print("  镜头: \(lens)")
        }
        if let flash = exif[kCGImagePropertyExifFlash as String] as? Int {
            print("  闪光灯: \(flash > 0 ? "已触发" : "未触发")")
        }
        if let comment = exif[kCGImagePropertyExifUserComment as String] as? String {
            print("  用户注释: \(comment)")
        }
    }

    private func printGpsData(_ gps: [String: Any]) {
        if let lat = gps[kCGImagePropertyGPSLatitude as String] as? Double,
           let latRef = gps[kCGImagePropertyGPSLatitudeRef as String] as? String {
            print("  纬度: \(lat)° \(latRef)")
        }
        if let lon = gps[kCGImagePropertyGPSLongitude as String] as? Double,
           let lonRef = gps[kCGImagePropertyGPSLongitudeRef as String] as? String {
            print("  经度: \(lon)° \(lonRef)")
        }
        if let alt = gps[kCGImagePropertyGPSAltitude as String] as? Double {
            print("  海拔: \(Int(alt))m")
        }
        if let timestamp = gps[kCGImagePropertyGPSTimeStamp as String] as? String {
            print("  GPS 时间: \(timestamp)")
        }
        if let dateStamp = gps[kCGImagePropertyGPSDateStamp as String] as? String {
            print("  GPS 日期: \(dateStamp)")
        }
    }

    private func printTiffData(_ tiff: [String: Any]) {
        if let make = tiff[kCGImagePropertyTIFFMake as String] as? String {
            print("  制造商: \(make)")
        }
        if let model = tiff[kCGImagePropertyTIFFModel as String] as? String {
            print("  型号: \(model)")
        }
        if let software = tiff[kCGImagePropertyTIFFSoftware as String] as? String {
            print("  软件: \(software)")
        }
        if let dateTime = tiff[kCGImagePropertyTIFFDateTime as String] as? String {
            print("  日期: \(dateTime)")
        }
        if let orientation = tiff[kCGImagePropertyTIFFOrientation as String] as? Int {
            print("  方向: \(orientation)")
        }
    }

    private func printIptcData(_ iptc: [String: Any]) {
        if let caption = iptc[kCGImagePropertyIPTCCaptionAbstract as String] as? String {
            print("  标题: \(caption)")
        }
        if let keywords = iptc[kCGImagePropertyIPTCKeywords as String] as? [String] {
            print("  关键词: \(keywords.joined(separator: ", "))")
        }
        if let copyright = iptc[kCGImagePropertyIPTCCopyrightNotice as String] as? String {
            print("  版权: \(copyright)")
        }
        if let creator = iptc[kCGImagePropertyIPTCCreatorContactInfo as String] as? String {
            print("  创作者: \(creator)")
        }
    }

    private func printMetadataJSON(properties: [String: Any]) {
        var output: [String: Any] = [:]

        if category == "all" || category == "exif" {
            if let exif = properties[kCGImagePropertyExifDictionary as String] {
                output["exif"] = exif
            }
        }

        if category == "all" || category == "gps" {
            if let gps = properties[kCGImagePropertyGPSDictionary as String] {
                output["gps"] = gps
            }
        }

        if category == "all" || category == "tiff" {
            if let tiff = properties[kCGImagePropertyTIFFDictionary as String] {
                output["tiff"] = tiff
            }
        }

        if category == "all" || category == "iptc" {
            if let iptc = properties[kCGImagePropertyIPTCDictionary as String] {
                output["iptc"] = iptc
            }
        }

        // 添加基本信息
        if category == "all" {
            var basic: [String: Any] = [:]
            if let width = properties[kCGImagePropertyPixelWidth as String] {
                basic["width"] = width
            }
            if let height = properties[kCGImagePropertyPixelHeight as String] {
                basic["height"] = height
            }
            if let dpi = properties[kCGImagePropertyDPIWidth as String] {
                basic["dpi"] = dpi
            }
            if let colorModel = properties[kCGImagePropertyColorModel as String] {
                basic["color_model"] = colorModel
            }
            if !basic.isEmpty {
                output["basic"] = basic
            }
        }

        if let jsonData = try? JSONSerialization.data(withJSONObject: output, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    }

    // MARK: - 写入元数据

    private func writeMetadata(url: URL) throws {
        // 确定输出路径
        let outputPath = output ?? FileUtils.generateOutputPath(
            from: url.path,
            suffix: "_meta",
            extension: url.pathExtension
        )
        let outputURL = URL(fileURLWithPath: outputPath)

        // 读取原始图像和元数据
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              var properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any],
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw AirisError.invalidPath(url.path)
        }

        // 修改元数据
        if clearAll {
            // 清除所有可编辑的元数据
            properties.removeValue(forKey: kCGImagePropertyExifDictionary as String)
            properties.removeValue(forKey: kCGImagePropertyGPSDictionary as String)
            properties.removeValue(forKey: kCGImagePropertyIPTCDictionary as String)
            print("✅ 已清除所有元数据")
        } else {
            if clearGps {
                properties.removeValue(forKey: kCGImagePropertyGPSDictionary as String)
                print("✅ 已清除 GPS 数据")
            }

            if let comment = setComment {
                var exifDict = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] ?? [:]
                exifDict[kCGImagePropertyExifUserComment as String] = comment
                properties[kCGImagePropertyExifDictionary as String] = exifDict
                print("✅ 已设置用户注释: \(comment)")
            }
        }

        // 确定输出格式
        let format = getImageFormat(for: url)

        // 创建目标
        guard let destination = CGImageDestinationCreateWithURL(
            outputURL as CFURL,
            format,
            1,
            nil
        ) else {
            throw AirisError.invalidPath(outputPath)
        }

        // 添加图像和元数据
        CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)

        // 完成写入
        guard CGImageDestinationFinalize(destination) else {
            throw AirisError.imageEncodeFailed
        }

        print("")
        print(Strings.get("info.saved_to", outputPath))
    }

    /// 获取图像格式 UTI
    private func getImageFormat(for url: URL) -> CFString {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg":
            return UTType.jpeg.identifier as CFString
        case "png":
            return UTType.png.identifier as CFString
        case "heic":
            return UTType.heic.identifier as CFString
        case "tiff", "tif":
            return UTType.tiff.identifier as CFString
        default:
            return UTType.jpeg.identifier as CFString
        }
    }
}
