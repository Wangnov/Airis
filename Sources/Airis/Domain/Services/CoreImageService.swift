import CoreImage
import CoreImage.CIFilterBuiltins
import CoreGraphics
import Foundation
import Metal

/// CoreImage 服务层封装（提供统一的图像编辑接口）
///
/// 使用方式：
/// ```swift
/// let service = ServiceContainer.shared.coreImageService
/// let ciImage = CIImage(cgImage: cgImage)
/// let blurred = service.gaussianBlur(ciImage: ciImage, radius: 10)
/// let result = service.render(ciImage: blurred)
/// ```
///
/// 性能注意事项：
/// - CIContext 创建成本很高，本服务复用同一个 context
/// - 使用 Metal 硬件加速渲染
/// - CIFilter 是可变对象，每次调用都会创建新实例
final class CoreImageService: @unchecked Sendable {

    // MARK: - Properties

    /// 共享的 CIContext（使用 Metal 硬件加速）
    private let context: CIContext

    /// Metal 设备（可选，用于高级渲染）
    private let metalDevice: MTLDevice?

    // MARK: - Initialization

    init() {
        // 尝试获取 Metal 设备进行 GPU 加速
        if let device = MTLCreateSystemDefaultDevice() {
            self.metalDevice = device
            self.context = CIContext(mtlDevice: device, options: [
                .workingColorSpace: CGColorSpaceCreateDeviceRGB(),
                .cacheIntermediates: true,
                .highQualityDownsample: true,
                .name: "Airis.CoreImage" as NSString
            ])
        } else {
            // 回退到软件渲染（虚拟机或不支持 Metal 的情况）
            self.metalDevice = nil
            self.context = CIContext(options: [
                .useSoftwareRenderer: true,
                .workingColorSpace: CGColorSpaceCreateDeviceRGB(),
                .name: "Airis.CoreImage.Software" as NSString
            ])
        }
    }

    // MARK: - 图像变换

    /// 缩放图像（使用 Lanczos 算法，高质量）
    ///
    /// - Parameters:
    ///   - ciImage: 输入图像
    ///   - width: 目标宽度（可选）
    ///   - height: 目标高度（可选）
    ///   - maintainAspectRatio: 是否保持宽高比（默认 true）
    /// - Returns: 缩放后的 CIImage
    func resize(
        ciImage: CIImage,
        width: Int? = nil,
        height: Int? = nil,
        maintainAspectRatio: Bool = true
    ) -> CIImage {
        let originalSize = ciImage.extent.size

        // 如果没有指定尺寸，返回原图
        guard width != nil || height != nil else {
            return ciImage
        }

        var scaleX: CGFloat = 1.0
        var scaleY: CGFloat = 1.0

        if let targetWidth = width {
            scaleX = CGFloat(targetWidth) / originalSize.width
        }

        if let targetHeight = height {
            scaleY = CGFloat(targetHeight) / originalSize.height
        }

        // 只指定一个维度时，保持宽高比
        if width == nil {
            scaleX = scaleY
        } else if height == nil {
            scaleY = scaleX
        } else if maintainAspectRatio {
            // 两个维度都指定但要保持宽高比，取较小的缩放比
            let scale = min(scaleX, scaleY)
            scaleX = scale
            scaleY = scale
        }

        let filter = CIFilter.lanczosScaleTransform()
        filter.inputImage = ciImage
        filter.scale = Float(scaleY)  // Lanczos 使用 Y 轴缩放作为主缩放
        filter.aspectRatio = Float(scaleX / scaleY)  // 宽高比调整

        return filter.outputImage ?? ciImage
    }

    /// 裁剪图像
    ///
    /// - Parameters:
    ///   - ciImage: 输入图像
    ///   - rect: 裁剪区域（使用 CoreImage 坐标系，原点在左下角）
    /// - Returns: 裁剪后的 CIImage
    func crop(ciImage: CIImage, rect: CGRect) -> CIImage {
        // 确保裁剪区域在图像范围内
        let clampedRect = rect.intersection(ciImage.extent)
        guard !clampedRect.isEmpty else {
            return ciImage
        }
        return ciImage.cropped(to: clampedRect)
    }

    /// 裁剪图像（使用标准化坐标，自动转换坐标系）
    ///
    /// - Parameters:
    ///   - ciImage: 输入图像
    ///   - normalizedRect: 标准化裁剪区域（0.0-1.0，原点在左上角，与 Vision 框架一致）
    /// - Returns: 裁剪后的 CIImage
    func cropNormalized(ciImage: CIImage, normalizedRect: CGRect) -> CIImage {
        let extent = ciImage.extent

        // 将标准化坐标（左上角原点）转换为 CoreImage 坐标（左下角原点）
        let actualRect = CGRect(
            x: normalizedRect.origin.x * extent.width,
            y: (1.0 - normalizedRect.origin.y - normalizedRect.height) * extent.height,
            width: normalizedRect.width * extent.width,
            height: normalizedRect.height * extent.height
        )

        return crop(ciImage: ciImage, rect: actualRect)
    }

    /// 旋转图像
    ///
    /// - Parameters:
    ///   - ciImage: 输入图像
    ///   - degrees: 旋转角度（顺时针为正）
    /// - Returns: 旋转后的 CIImage
    func rotate(ciImage: CIImage, degrees: Double) -> CIImage {
        // 将角度转换为弧度（注意 CoreImage 使用逆时针为正）
        let radians = -degrees * .pi / 180.0
        let transform = CGAffineTransform(rotationAngle: radians)
        return ciImage.transformed(by: transform)
    }

    /// 旋转图像（绕中心点旋转）
    ///
    /// - Parameters:
    ///   - ciImage: 输入图像
    ///   - degrees: 旋转角度（顺时针为正）
    /// - Returns: 旋转后的 CIImage（已移动到正坐标区域）
    func rotateAroundCenter(ciImage: CIImage, degrees: Double) -> CIImage {
        let extent = ciImage.extent
        let centerX = extent.midX
        let centerY = extent.midY

        let radians = -degrees * .pi / 180.0

        // 移动到原点 -> 旋转 -> 移回中心
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: centerX, y: centerY)
        transform = transform.rotated(by: radians)
        transform = transform.translatedBy(x: -centerX, y: -centerY)

        let rotated = ciImage.transformed(by: transform)

        // 将图像移动到正坐标区域
        let newExtent = rotated.extent
        if newExtent.origin.x < 0 || newExtent.origin.y < 0 {
            let offsetX = newExtent.origin.x < 0 ? -newExtent.origin.x : 0
            let offsetY = newExtent.origin.y < 0 ? -newExtent.origin.y : 0
            return rotated.transformed(by: CGAffineTransform(translationX: offsetX, y: offsetY))
        }

        return rotated
    }

    /// 翻转图像
    ///
    /// - Parameters:
    ///   - ciImage: 输入图像
    ///   - horizontal: 是否水平翻转
    ///   - vertical: 是否垂直翻转
    /// - Returns: 翻转后的 CIImage
    func flip(ciImage: CIImage, horizontal: Bool = false, vertical: Bool = false) -> CIImage {
        guard horizontal || vertical else {
            return ciImage
        }

        let extent = ciImage.extent
        var transform = CGAffineTransform.identity

        if horizontal {
            transform = transform.translatedBy(x: extent.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        }

        if vertical {
            transform = transform.translatedBy(x: 0, y: extent.height)
            transform = transform.scaledBy(x: 1, y: -1)
        }

        return ciImage.transformed(by: transform)
    }

    // MARK: - 滤镜效果

    /// 高斯模糊
    ///
    /// - Parameters:
    ///   - ciImage: 输入图像
    ///   - radius: 模糊半径（默认 10，范围建议 0-100）
    /// - Returns: 模糊后的 CIImage
    func gaussianBlur(ciImage: CIImage, radius: Double = 10) -> CIImage {
        let filter = CIFilter.gaussianBlur()
        filter.inputImage = ciImage
        filter.radius = Float(max(0, radius))

        guard let output = filter.outputImage else {
            return ciImage
        }

        // 模糊会扩展图像边界，裁剪回原始大小
        return output.cropped(to: ciImage.extent)
    }

    /// 锐化（亮度锐化）
    ///
    /// - Parameters:
    ///   - ciImage: 输入图像
    ///   - sharpness: 锐化强度（默认 0.5，范围建议 0-2）
    ///   - radius: 影响区域半径（默认 1.69，内部参数）
    /// - Returns: 锐化后的 CIImage
    func sharpen(ciImage: CIImage, sharpness: Double = 0.5, radius: Double = 1.69) -> CIImage {
        let filter = CIFilter.sharpenLuminance()
        filter.inputImage = ciImage
        filter.sharpness = Float(max(0, sharpness))
        filter.radius = Float(max(0, radius))
        return filter.outputImage ?? ciImage
    }

    /// 调整亮度
    ///
    /// - Parameters:
    ///   - ciImage: 输入图像
    ///   - brightness: 亮度调整（范围 -1.0 到 1.0，0 为原始）
    /// - Returns: 调整后的 CIImage
    func adjustBrightness(ciImage: CIImage, brightness: Double) -> CIImage {
        let filter = CIFilter.colorControls()
        filter.inputImage = ciImage
        filter.brightness = Float(max(-1, min(1, brightness)))
        filter.contrast = 1.0
        filter.saturation = 1.0
        return filter.outputImage ?? ciImage
    }

    /// 调整对比度
    ///
    /// - Parameters:
    ///   - ciImage: 输入图像
    ///   - contrast: 对比度调整（范围 0.25 到 4.0，1.0 为原始）
    /// - Returns: 调整后的 CIImage
    func adjustContrast(ciImage: CIImage, contrast: Double) -> CIImage {
        let filter = CIFilter.colorControls()
        filter.inputImage = ciImage
        filter.brightness = 0
        filter.contrast = Float(max(0.25, min(4, contrast)))
        filter.saturation = 1.0
        return filter.outputImage ?? ciImage
    }

    /// 调整饱和度
    ///
    /// - Parameters:
    ///   - ciImage: 输入图像
    ///   - saturation: 饱和度调整（范围 0 到 2.0，1.0 为原始，0 为灰度）
    /// - Returns: 调整后的 CIImage
    func adjustSaturation(ciImage: CIImage, saturation: Double) -> CIImage {
        let filter = CIFilter.colorControls()
        filter.inputImage = ciImage
        filter.brightness = 0
        filter.contrast = 1.0
        filter.saturation = Float(max(0, min(2, saturation)))
        return filter.outputImage ?? ciImage
    }

    /// 综合颜色调整
    ///
    /// - Parameters:
    ///   - ciImage: 输入图像
    ///   - brightness: 亮度（-1.0 到 1.0）
    ///   - contrast: 对比度（0.25 到 4.0）
    ///   - saturation: 饱和度（0 到 2.0）
    /// - Returns: 调整后的 CIImage
    func adjustColors(
        ciImage: CIImage,
        brightness: Double = 0,
        contrast: Double = 1.0,
        saturation: Double = 1.0
    ) -> CIImage {
        let filter = CIFilter.colorControls()
        filter.inputImage = ciImage
        filter.brightness = Float(max(-1, min(1, brightness)))
        filter.contrast = Float(max(0.25, min(4, contrast)))
        filter.saturation = Float(max(0, min(2, saturation)))
        return filter.outputImage ?? ciImage
    }

    /// 灰度转换
    ///
    /// - Parameter ciImage: 输入图像
    /// - Returns: 灰度图像
    func grayscale(ciImage: CIImage) -> CIImage {
        return adjustSaturation(ciImage: ciImage, saturation: 0)
    }

    /// 反色（负片效果）
    ///
    /// - Parameter ciImage: 输入图像
    /// - Returns: 反色后的图像
    func invert(ciImage: CIImage) -> CIImage {
        let filter = CIFilter.colorInvert()
        filter.inputImage = ciImage
        return filter.outputImage ?? ciImage
    }

    /// 棕褐色效果（怀旧风格）
    ///
    /// - Parameters:
    ///   - ciImage: 输入图像
    ///   - intensity: 效果强度（0-1，默认 1.0）
    /// - Returns: 棕褐色效果的图像
    func sepiaTone(ciImage: CIImage, intensity: Double = 1.0) -> CIImage {
        let filter = CIFilter.sepiaTone()
        filter.inputImage = ciImage
        filter.intensity = Float(max(0, min(1, intensity)))
        return filter.outputImage ?? ciImage
    }

    // MARK: - 调整效果（Task 8.1）

    /// 曝光调整
    ///
    /// - Parameters:
    ///   - ciImage: 输入图像
    ///   - ev: 曝光值（-10.0 到 10.0，0 为不变）
    /// - Returns: 调整后的 CIImage
    func adjustExposure(ciImage: CIImage, ev: Double) -> CIImage {
        let filter = CIFilter.exposureAdjust()
        filter.inputImage = ciImage
        filter.ev = Float(max(-10, min(10, ev)))
        return filter.outputImage ?? ciImage
    }

    /// 色温和色调调整
    ///
    /// - Parameters:
    ///   - ciImage: 输入图像
    ///   - temperature: 色温调整值（负值偏冷/蓝，正值偏暖/黄，范围建议 -2000 到 2000）
    ///   - tint: 色调调整值（负值偏绿，正值偏品红，范围建议 -150 到 150）
    /// - Returns: 调整后的 CIImage
    func adjustTemperatureAndTint(
        ciImage: CIImage,
        temperature: Double = 0,
        tint: Double = 0
    ) -> CIImage {
        let filter = CIFilter.temperatureAndTint()
        filter.inputImage = ciImage
        // 使用中性点 6500K，根据调整值计算目标色温
        let neutralTemp: CGFloat = 6500
        let targetTemp = neutralTemp + CGFloat(temperature)
        filter.neutral = CIVector(x: neutralTemp, y: 0)
        filter.targetNeutral = CIVector(x: targetTemp, y: CGFloat(tint))
        return filter.outputImage ?? ciImage
    }

    /// 暗角效果
    ///
    /// - Parameters:
    ///   - ciImage: 输入图像
    ///   - intensity: 暗角强度（0 到 2.0，0 为无效果）
    ///   - radius: 暗角半径（0 到 2.0，控制暗角开始位置）
    /// - Returns: 添加暗角效果的 CIImage
    func vignette(ciImage: CIImage, intensity: Double = 1.0, radius: Double = 1.0) -> CIImage {
        let filter = CIFilter.vignette()
        filter.inputImage = ciImage
        filter.intensity = Float(max(0, min(2, intensity)))
        filter.radius = Float(max(0, min(2, radius)))
        return filter.outputImage ?? ciImage
    }

    /// 色调分离（海报效果）
    ///
    /// - Parameters:
    ///   - ciImage: 输入图像
    ///   - levels: 每个颜色通道的级别数（2 到 30，默认 6）
    /// - Returns: 色调分离后的 CIImage
    func posterize(ciImage: CIImage, levels: Double = 6.0) -> CIImage {
        let filter = CIFilter.colorPosterize()
        filter.inputImage = ciImage
        filter.levels = Float(max(2, min(30, levels)))
        return filter.outputImage ?? ciImage
    }

    /// 阈值化（黑白二值）
    ///
    /// - Parameters:
    ///   - ciImage: 输入图像
    ///   - threshold: 阈值（0.0 到 1.0，默认 0.5）
    /// - Returns: 二值化后的 CIImage
    func threshold(ciImage: CIImage, threshold: Double = 0.5) -> CIImage {
        // 使用 CIColorThreshold 滤镜（macOS 10.13+）
        guard let filter = CIFilter(name: "CIColorThreshold") else {
            // 如果 CIColorThreshold 不可用，使用替代方案
            // 先转灰度，再用极端对比度模拟
            let grayscale = adjustSaturation(ciImage: ciImage, saturation: 0)
            let posterized = posterize(ciImage: grayscale, levels: 2)
            return posterized
        }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(max(0, min(1, threshold)), forKey: "inputThreshold")
        return filter.outputImage ?? ciImage
    }

    // MARK: - 渲染

    /// 渲染 CIImage 到 CGImage
    ///
    /// - Parameter ciImage: 要渲染的 CIImage
    /// - Returns: 渲染后的 CGImage，如果失败返回 nil
    func render(ciImage: CIImage) -> CGImage? {
        context.createCGImage(ciImage, from: ciImage.extent)
    }

    /// 渲染 CIImage 到 CGImage（指定格式）
    ///
    /// - Parameters:
    ///   - ciImage: 要渲染的 CIImage
    ///   - format: 像素格式
    ///   - colorSpace: 色彩空间
    /// - Returns: 渲染后的 CGImage
    func render(
        ciImage: CIImage,
        format: CIFormat,
        colorSpace: CGColorSpace?
    ) -> CGImage? {
        context.createCGImage(
            ciImage,
            from: ciImage.extent,
            format: format,
            colorSpace: colorSpace
        )
    }

    // MARK: - 高级操作

    /// 应用滤镜链并渲染
    ///
    /// - Parameters:
    ///   - cgImage: 输入的 CGImage
    ///   - filters: 滤镜操作闭包
    /// - Returns: 处理后的 CGImage
    func applyFilters(
        to cgImage: CGImage,
        filters: (CIImage) -> CIImage
    ) -> CGImage? {
        let ciImage = CIImage(cgImage: cgImage)
        let filtered = filters(ciImage)
        return render(ciImage: filtered)
    }

    /// 加载、处理并保存图像（完整流程）
    ///
    /// - Parameters:
    ///   - inputURL: 输入图像 URL
    ///   - outputURL: 输出图像 URL
    ///   - format: 输出格式（png, jpg, heic）
    ///   - quality: 压缩质量（0-1，仅对 jpg/heic 有效）
    ///   - filterBlock: 滤镜处理闭包
    func applyAndSave(
        inputURL: URL,
        outputURL: URL,
        format: String = "png",
        quality: Float = 1.0,
        filterBlock: (CIImage) -> CIImage
    ) throws {
        let imageIO = ServiceContainer.shared.imageIOService

        // 加载图像
        let cgImage = try imageIO.loadImage(at: inputURL)

        // 转换为 CIImage
        let ciImage = CIImage(cgImage: cgImage)

        // 应用滤镜
        let filtered = filterBlock(ciImage)

        // 渲染
        guard let outputCGImage = render(ciImage: filtered) else {
            throw AirisError.imageEncodeFailed
        }

        // 保存
        try imageIO.saveImage(outputCGImage, to: outputURL, format: format, quality: quality)
    }

    // MARK: - 工具方法

    /// 获取 CIContext 支持的最大输入图像尺寸
    /// - Note: 在 macOS 上返回一个合理的默认值，iOS 上使用实际值
    func maxInputImageSize() -> CGSize {
        #if os(iOS) || os(tvOS) || os(visionOS)
        return context.inputImageMaximumSize()
        #else
        // macOS 上这个 API 不可用，返回一个合理的默认值
        return CGSize(width: 16384, height: 16384)
        #endif
    }

    /// 获取 CIContext 支持的最大输出图像尺寸
    /// - Note: 在 macOS 上返回一个合理的默认值，iOS 上使用实际值
    func maxOutputImageSize() -> CGSize {
        #if os(iOS) || os(tvOS) || os(visionOS)
        return context.outputImageMaximumSize()
        #else
        // macOS 上这个 API 不可用，返回一个合理的默认值
        return CGSize(width: 16384, height: 16384)
        #endif
    }

    /// 清理缓存（处理大量图像后建议调用）
    func clearCaches() {
        context.clearCaches()
    }

    /// 检查是否使用 Metal 加速
    var isUsingMetalAcceleration: Bool {
        metalDevice != nil
    }

    // MARK: - 坐标系转换工具

    /// 将 Vision 框架坐标（左上角原点）转换为 CoreImage 坐标（左下角原点）
    ///
    /// - Parameters:
    ///   - rect: Vision 框架的归一化矩形
    ///   - imageHeight: 图像高度
    /// - Returns: CoreImage 坐标系的矩形
    static func convertVisionToCI(rect: CGRect, imageHeight: CGFloat) -> CGRect {
        CGRect(
            x: rect.origin.x,
            y: imageHeight - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
    }

    /// 将 CoreImage 坐标（左下角原点）转换为 Vision 框架坐标（左上角原点）
    ///
    /// - Parameters:
    ///   - rect: CoreImage 的矩形
    ///   - imageHeight: 图像高度
    /// - Returns: Vision 框架坐标系的矩形
    static func convertCIToVision(rect: CGRect, imageHeight: CGFloat) -> CGRect {
        CGRect(
            x: rect.origin.x,
            y: imageHeight - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
    }

    // MARK: - 背景移除

    /// 保存带 alpha 通道的遮罩图像（用于背景移除）
    ///
    /// - Parameters:
    ///   - maskedBuffer: Vision 框架生成的遮罩 CVPixelBuffer
    ///   - outputURL: 输出文件 URL（必须是 PNG 格式）
    func saveMaskedImage(maskedBuffer: CVPixelBuffer, to outputURL: URL) throws {
        let ciImage = CIImage(cvPixelBuffer: maskedBuffer)

        guard let cgImage = render(ciImage: ciImage) else {
            throw AirisError.imageEncodeFailed
        }

        let imageIO = ServiceContainer.shared.imageIOService
        try imageIO.saveImage(cgImage, to: outputURL, format: "png", quality: 1.0)
    }

    // MARK: - 自动增强

    /// 自动增强图像（一键优化）
    ///
    /// 使用 CoreImage 的 autoAdjustmentFilters 自动检测并应用最佳滤镜：
    /// - 红眼校正
    /// - 面部平衡
    /// - 自然饱和度
    /// - 色调曲线
    /// - 高光阴影调整
    ///
    /// - Parameters:
    ///   - ciImage: 输入图像
    ///   - enableRedEye: 是否启用红眼校正（默认 true）
    /// - Returns: 增强后的 CIImage
    func autoEnhance(ciImage: CIImage, enableRedEye: Bool = true) -> CIImage {
        var options: [CIImageAutoAdjustmentOption: Any] = [
            .enhance: true
        ]

        if !enableRedEye {
            options[.redEye] = false
        }

        let filters = ciImage.autoAdjustmentFilters(options: options)

        var enhanced = ciImage
        for filter in filters {
            filter.setValue(enhanced, forKey: kCIInputImageKey)
            if let output = filter.outputImage {
                enhanced = output
            }
        }

        return enhanced
    }

    /// 加载、自动增强并保存图像
    ///
    /// - Parameters:
    ///   - inputURL: 输入图像 URL
    ///   - outputURL: 输出图像 URL
    ///   - format: 输出格式（png, jpg, heic）
    ///   - quality: 压缩质量（0-1，仅对 jpg/heic 有效）
    ///   - enableRedEye: 是否启用红眼校正
    func autoEnhanceAndSave(
        inputURL: URL,
        outputURL: URL,
        format: String = "png",
        quality: Float = 1.0,
        enableRedEye: Bool = true
    ) throws {
        let imageIO = ServiceContainer.shared.imageIOService

        // 加载图像
        let cgImage = try imageIO.loadImage(at: inputURL)

        // 转换为 CIImage
        let ciImage = CIImage(cgImage: cgImage)

        // 自动增强
        let enhanced = autoEnhance(ciImage: ciImage, enableRedEye: enableRedEye)

        // 渲染
        guard let outputCGImage = render(ciImage: enhanced) else {
            throw AirisError.imageEncodeFailed
        }

        // 保存
        try imageIO.saveImage(outputCGImage, to: outputURL, format: format, quality: quality)
    }

    /// 获取自动增强将应用的滤镜信息（用于调试/显示）
    ///
    /// - Parameter ciImage: 输入图像
    /// - Returns: 滤镜名称列表
    func getAutoEnhanceFilters(for ciImage: CIImage) -> [String] {
        let filters = ciImage.autoAdjustmentFilters()
        return filters.map { $0.name }
    }
}
