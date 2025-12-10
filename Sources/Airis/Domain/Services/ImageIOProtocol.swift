import ImageIO
import Foundation
import CoreGraphics
import UniformTypeIdentifiers

/// ImageIO 底层操作协议（用于依赖注入和测试 Mock）
protocol ImageIOOperations: Sendable {
    /// 创建图像源
    func createImageSource(at url: URL) -> CGImageSource?

    /// 从图像源获取属性
    func getProperties(from source: CGImageSource, at index: Int) -> [CFString: Any]?

    /// 从图像源创建图像
    func createImage(from source: CGImageSource, at index: Int, options: CFDictionary?) -> CGImage?

    /// 获取图像源类型
    func getType(from source: CGImageSource) -> String?

    /// 获取图像源帧数
    func getCount(from source: CGImageSource) -> Int

    /// 创建图像目标
    func createImageDestination(at url: URL, type: UTType) -> CGImageDestination?

    /// 添加图像到目标
    func addImage(to destination: CGImageDestination, image: CGImage, properties: CFDictionary?)

    /// 完成图像写入
    func finalize(destination: CGImageDestination) -> Bool
}

/// 真实的 ImageIO 操作实现
final class RealImageIOOperations: ImageIOOperations, @unchecked Sendable {

    func createImageSource(at url: URL) -> CGImageSource? {
        CGImageSourceCreateWithURL(url as CFURL, nil)
    }

    func getProperties(from source: CGImageSource, at index: Int) -> [CFString: Any]? {
        CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any]
    }

    func createImage(from source: CGImageSource, at index: Int, options: CFDictionary?) -> CGImage? {
        CGImageSourceCreateImageAtIndex(source, index, options)
    }

    func getType(from source: CGImageSource) -> String? {
        CGImageSourceGetType(source) as String?
    }

    func getCount(from source: CGImageSource) -> Int {
        CGImageSourceGetCount(source)
    }

    func createImageDestination(at url: URL, type: UTType) -> CGImageDestination? {
        CGImageDestinationCreateWithURL(url as CFURL, type.identifier as CFString, 1, nil)
    }

    func addImage(to destination: CGImageDestination, image: CGImage, properties: CFDictionary?) {
        CGImageDestinationAddImage(destination, image, properties)
    }

    func finalize(destination: CGImageDestination) -> Bool {
        CGImageDestinationFinalize(destination)
    }
}
