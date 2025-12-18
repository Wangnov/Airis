import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
#if !XCODE_BUILD
    @testable import AirisCore
#endif

/// Mock ImageIO 操作实现（用于测试错误路径）
final class MockImageIOOperations: ImageIOOperations, @unchecked Sendable {
    // MARK: - Mock 控制标志

    /// 模拟 createImageDestination 失败
    var shouldFailCreateDestination = false

    /// 模拟 finalize 失败
    var shouldFailFinalize = false

    /// 使用真实操作作为后备
    private let realOperations = RealImageIOOperations()

    /// Mock 的 CGImageDestination（用于测试）
    private var mockDestination: CGImageDestination?

    // MARK: - ImageIOOperations Protocol

    func createImageSource(at url: URL) -> CGImageSource? {
        realOperations.createImageSource(at: url)
    }

    func getProperties(from source: CGImageSource, at index: Int) -> [CFString: Any]? {
        realOperations.getProperties(from: source, at: index)
    }

    func createImage(from source: CGImageSource, at index: Int, options: CFDictionary?) -> CGImage? {
        realOperations.createImage(from: source, at: index, options: options)
    }

    func getType(from source: CGImageSource) -> String? {
        realOperations.getType(from: source)
    }

    func getCount(from source: CGImageSource) -> Int {
        realOperations.getCount(from: source)
    }

    func createImageDestination(at url: URL, type: UTType) -> CGImageDestination? {
        if shouldFailCreateDestination {
            return nil
        }
        // 创建真实的 destination 用于后续操作
        mockDestination = realOperations.createImageDestination(at: url, type: type)
        return mockDestination
    }

    func addImage(to destination: CGImageDestination, image: CGImage, properties: CFDictionary?) {
        realOperations.addImage(to: destination, image: image, properties: properties)
    }

    func finalize(destination: CGImageDestination) -> Bool {
        if shouldFailFinalize {
            return false
        }
        return realOperations.finalize(destination: destination)
    }
}

/// Mock ImageIO 操作 - 用于测试 getImageInfo 中的 orientation 默认值分支
final class MockImageIOOperationsWithInvalidOrientation: ImageIOOperations, @unchecked Sendable {
    private let realOperations = RealImageIOOperations()

    func createImageSource(at url: URL) -> CGImageSource? {
        realOperations.createImageSource(at: url)
    }

    func getProperties(from source: CGImageSource, at index: Int) -> [CFString: Any]? {
        // 返回带有无效 orientation 值的属性
        var properties = realOperations.getProperties(from: source, at: index) ?? [:]
        // 设置一个无效的 orientation 值（超出 1-8 范围）
        properties[kCGImagePropertyOrientation] = UInt32(99)
        return properties
    }

    func createImage(from source: CGImageSource, at index: Int, options: CFDictionary?) -> CGImage? {
        realOperations.createImage(from: source, at: index, options: options)
    }

    func getType(from source: CGImageSource) -> String? {
        realOperations.getType(from: source)
    }

    func getCount(from source: CGImageSource) -> Int {
        realOperations.getCount(from: source)
    }

    func createImageDestination(at url: URL, type: UTType) -> CGImageDestination? {
        realOperations.createImageDestination(at: url, type: type)
    }

    func addImage(to destination: CGImageDestination, image: CGImage, properties: CFDictionary?) {
        realOperations.addImage(to: destination, image: image, properties: properties)
    }

    func finalize(destination: CGImageDestination) -> Bool {
        realOperations.finalize(destination: destination)
    }
}

/// Mock ImageIO 操作 - 用于测试元数据中不包含 orientation 的情况
final class MockImageIOOperationsWithoutOrientation: ImageIOOperations, @unchecked Sendable {
    private let realOperations = RealImageIOOperations()

    func createImageSource(at url: URL) -> CGImageSource? {
        realOperations.createImageSource(at: url)
    }

    func getProperties(from source: CGImageSource, at index: Int) -> [CFString: Any]? {
        // 返回不包含 orientation 的属性
        var properties = realOperations.getProperties(from: source, at: index) ?? [:]
        properties.removeValue(forKey: kCGImagePropertyOrientation)
        return properties
    }

    func createImage(from source: CGImageSource, at index: Int, options: CFDictionary?) -> CGImage? {
        realOperations.createImage(from: source, at: index, options: options)
    }

    func getType(from source: CGImageSource) -> String? {
        realOperations.getType(from: source)
    }

    func getCount(from source: CGImageSource) -> Int {
        realOperations.getCount(from: source)
    }

    func createImageDestination(at url: URL, type: UTType) -> CGImageDestination? {
        realOperations.createImageDestination(at: url, type: type)
    }

    func addImage(to destination: CGImageDestination, image: CGImage, properties: CFDictionary?) {
        realOperations.addImage(to: destination, image: image, properties: properties)
    }

    func finalize(destination: CGImageDestination) -> Bool {
        realOperations.finalize(destination: destination)
    }
}

/// Mock ImageIO 操作 - 用于测试所有默认值分支（属性全部缺失）
final class MockImageIOOperationsWithMissingProperties: ImageIOOperations, @unchecked Sendable {
    private let realOperations = RealImageIOOperations()

    func createImageSource(at url: URL) -> CGImageSource? {
        realOperations.createImageSource(at: url)
    }

    func getProperties(from _: CGImageSource, at _: Int) -> [CFString: Any]? {
        // 返回只包含必要属性的字典，缺失可选属性以触发默认值
        [:] // 空字典，所有默认值分支都会被触发
    }

    func createImage(from source: CGImageSource, at index: Int, options: CFDictionary?) -> CGImage? {
        realOperations.createImage(from: source, at: index, options: options)
    }

    func getType(from source: CGImageSource) -> String? {
        realOperations.getType(from: source)
    }

    func getCount(from source: CGImageSource) -> Int {
        realOperations.getCount(from: source)
    }

    func createImageDestination(at url: URL, type: UTType) -> CGImageDestination? {
        realOperations.createImageDestination(at: url, type: type)
    }

    func addImage(to destination: CGImageDestination, image: CGImage, properties: CFDictionary?) {
        realOperations.addImage(to: destination, image: image, properties: properties)
    }

    func finalize(destination: CGImageDestination) -> Bool {
        realOperations.finalize(destination: destination)
    }
}

/// Mock ImageIO 操作 - 用于测试有效的 orientation 值（1-8 范围内）
final class MockImageIOOperationsWithValidOrientation: ImageIOOperations, @unchecked Sendable {
    private let realOperations = RealImageIOOperations()

    func createImageSource(at url: URL) -> CGImageSource? {
        realOperations.createImageSource(at: url)
    }

    func getProperties(from source: CGImageSource, at index: Int) -> [CFString: Any]? {
        // 返回带有有效 orientation 值的属性（范围 1-8）
        var properties = realOperations.getProperties(from: source, at: index) ?? [:]
        properties[kCGImagePropertyOrientation] = UInt32(6) // .right
        return properties
    }

    func createImage(from source: CGImageSource, at index: Int, options: CFDictionary?) -> CGImage? {
        realOperations.createImage(from: source, at: index, options: options)
    }

    func getType(from source: CGImageSource) -> String? {
        realOperations.getType(from: source)
    }

    func getCount(from source: CGImageSource) -> Int {
        realOperations.getCount(from: source)
    }

    func createImageDestination(at url: URL, type: UTType) -> CGImageDestination? {
        realOperations.createImageDestination(at: url, type: type)
    }

    func addImage(to destination: CGImageDestination, image: CGImage, properties: CFDictionary?) {
        realOperations.addImage(to: destination, image: image, properties: properties)
    }

    func finalize(destination: CGImageDestination) -> Bool {
        realOperations.finalize(destination: destination)
    }
}
