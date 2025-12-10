import ImageIO
import Foundation
import CoreGraphics
import UniformTypeIdentifiers

/// ImageIO 服务层（图像元数据和加载）
final class ImageIOService: Sendable {
    /// 底层操作实现（支持依赖注入，用于测试 Mock）
    private let operations: ImageIOOperations

    init(operations: ImageIOOperations = RealImageIOOperations()) {
        self.operations = operations
    }

    // MARK: - 元数据读取

    /// 读取图像元数据（零拷贝）
    func loadImageMetadata(at url: URL) throws -> [CFString: Any] {
        guard let source = operations.createImageSource(at: url) else {
            throw AirisError.fileNotFound(url.path)
        }

        guard let properties = operations.getProperties(from: source, at: 0) else {
            throw AirisError.unsupportedFormat(url.pathExtension)
        }

        return properties
    }

    // MARK: - 图像加载

    /// 加载图像（支持缩略图优化）
    func loadImage(at url: URL, maxDimension: Int? = nil) throws -> CGImage {
        guard let source = operations.createImageSource(at: url) else {
            throw AirisError.fileNotFound(url.path)
        }

        var options: [CFString: Any] = [
            kCGImageSourceShouldCache: false  // 延迟解码，节省内存
        ]

        if let maxDim = maxDimension {
            // 创建缩略图（性能优化）
            options[kCGImageSourceCreateThumbnailFromImageAlways] = true
            options[kCGImageSourceThumbnailMaxPixelSize] = maxDim
            options[kCGImageSourceCreateThumbnailWithTransform] = true
        }

        guard let image = operations.createImage(from: source, at: 0, options: options as CFDictionary) else {
            throw AirisError.imageDecodeFailed
        }

        return image
    }

    // MARK: - 图像信息

    /// 图像基本信息
    struct ImageInfo {
        let width: Int
        let height: Int
        let dpiWidth: Int
        let dpiHeight: Int
        let colorModel: String?
        let depth: Int?
        let hasAlpha: Bool
        let orientation: CGImagePropertyOrientation
    }

    /// 获取图像基本信息
    func getImageInfo(at url: URL) throws -> ImageInfo {
        let properties = try loadImageMetadata(at: url)

        let width = (properties[kCGImagePropertyPixelWidth] as? Int) ?? 0
        let height = (properties[kCGImagePropertyPixelHeight] as? Int) ?? 0
        let dpiWidth = (properties[kCGImagePropertyDPIWidth] as? Int) ?? 72
        let dpiHeight = (properties[kCGImagePropertyDPIHeight] as? Int) ?? 72
        let colorModel = properties[kCGImagePropertyColorModel] as? String
        let depth = properties[kCGImagePropertyDepth] as? Int
        let hasAlpha = (properties[kCGImagePropertyHasAlpha] as? Bool) ?? false

        // 读取 EXIF 方向（有效值范围 1-8）
        var orientation: CGImagePropertyOrientation = .up
        if let orientationNum = properties[kCGImagePropertyOrientation] as? UInt32,
           (1...8).contains(orientationNum),
           let validOrientation = CGImagePropertyOrientation(rawValue: orientationNum) {
            orientation = validOrientation
        }

        return ImageInfo(
            width: width,
            height: height,
            dpiWidth: dpiWidth,
            dpiHeight: dpiHeight,
            colorModel: colorModel,
            depth: depth,
            hasAlpha: hasAlpha,
            orientation: orientation
        )
    }

    // MARK: - 图像保存

    /// 保存图像到文件
    func saveImage(
        _ cgImage: CGImage,
        to url: URL,
        format: String = "png",
        quality: Float = 1.0
    ) throws {
        let utType: UTType
        switch format.lowercased() {
        case "jpg", "jpeg":
            utType = .jpeg
        case "png":
            utType = .png
        case "heic":
            utType = .heic
        case "tiff", "tif":
            utType = .tiff
        default:
            utType = .png
        }

        guard let destination = operations.createImageDestination(at: url, type: utType) else {
            throw AirisError.fileWriteError(url.path, NSError(domain: "ImageIO", code: -1))
        }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]

        operations.addImage(to: destination, image: cgImage, properties: options as CFDictionary)

        guard operations.finalize(destination: destination) else {
            throw AirisError.imageEncodeFailed
        }
    }

    // MARK: - 辅助方法

    /// 获取图像格式
    func getImageFormat(at url: URL) throws -> String {
        guard let source = operations.createImageSource(at: url) else {
            throw AirisError.fileNotFound(url.path)
        }

        guard let type = operations.getType(from: source) else {
            throw AirisError.unsupportedFormat(url.pathExtension)
        }

        return type
    }

    /// 获取图像帧数（用于 GIF 等多帧格式）
    func getImageFrameCount(at url: URL) throws -> Int {
        guard let source = operations.createImageSource(at: url) else {
            throw AirisError.fileNotFound(url.path)
        }

        return operations.getCount(from: source)
    }
}
