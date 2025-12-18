import Foundation
import ImageIO
import UniformTypeIdentifiers

/// 图像工具类
enum ImageUtils {
    /// 将图片文件编码为 Base64
    static func encodeImageToBase64(at url: URL) throws -> (data: String, mimeType: String) {
        // 读取图片数据
        let imageData = try Data(contentsOf: url)

        // 确定 MIME 类型
        let mimeType = mimeTypeForImageFile(at: url)

        // Base64 编码
        let base64String = imageData.base64EncodedString()

        return (base64String, mimeType)
    }

    /// 根据文件扩展名确定 MIME 类型
    static func mimeTypeForImageFile(at url: URL) -> String {
        let ext = url.pathExtension.lowercased()

        switch ext {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "heic":
            return "image/heic"
        case "heif":
            return "image/heif"
        case "webp":
            return "image/webp"
        case "gif":
            return "image/gif"
        default:
            return "image/jpeg" // 默认
        }
    }

    /// 从 Base64 字符串解码并保存图片
    static func decodeAndSaveImage(
        base64String: String,
        to outputPath: String,
        format _: String = "png"
    ) throws {
        // Base64 解码
        guard let imageData = Data(base64Encoded: base64String) else {
            throw AirisError.imageDecodeFailed
        }

        // 创建输出目录
        try FileUtils.ensureDirectory(for: outputPath)

        // 保存文件
        let outputURL = URL(fileURLWithPath: outputPath)
        try imageData.write(to: outputURL)
    }

    /// 获取图片尺寸（不加载完整图片）
    static func getImageDimensions(at url: URL) throws -> (width: Int, height: Int) {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any],
              let width = properties[kCGImagePropertyPixelWidth as String] as? Int,
              let height = properties[kCGImagePropertyPixelHeight as String] as? Int
        else {
            throw AirisError.imageDecodeFailed
        }

        return (width, height)
    }
}
