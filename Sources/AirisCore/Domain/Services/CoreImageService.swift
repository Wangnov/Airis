import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins
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
    // MARK: - Factories

    /// 滤镜工厂（可注入，便于测试异常分支）
    private nonisolated(unsafe) let filterFactory: any CoreImageFilterFactory
    /// 可选的渲染覆盖（测试注入，用于模拟渲染失败）
    private nonisolated(unsafe) let rendererOverride: ((CIImage) -> CGImage?)?
    /// 可选的滤镜输出覆盖（测试注入，用于强制返回特定输出或触发回退分支）
    private nonisolated(unsafe) let outputOverride: ((CIFilter, CIImage) -> CIImage?)?

    // MARK: - Properties

    /// 共享的 CIContext（使用 Metal 硬件加速）
    private let context: CIContext

    /// Metal 设备（可选，用于高级渲染）
    private let metalDevice: MTLDevice?

    /// 底层操作（用于依赖注入）
    private nonisolated(unsafe) let operations: any CoreImageOperations

    // MARK: - Initialization

    init(
        operations: any CoreImageOperations = DefaultCoreImageOperations(),
        filterFactory: any CoreImageFilterFactory = DefaultCoreImageFilterFactory(),
        rendererOverride: ((CIImage) -> CGImage?)? = nil,
        outputOverride: ((CIFilter, CIImage) -> CIImage?)? = nil
    ) {
        self.operations = operations
        self.filterFactory = filterFactory
        self.rendererOverride = rendererOverride
        self.outputOverride = outputOverride

        // 尝试获取 Metal 设备进行 GPU 加速
        metalDevice = operations.getDefaultMetalDevice()

        if let device = metalDevice {
            context = operations.createContext(with: device, options: [
                .workingColorSpace: CGColorSpaceCreateDeviceRGB(),
                .cacheIntermediates: true,
                .highQualityDownsample: true,
                .name: "Airis.CoreImage" as NSString,
            ])
        } else {
            // 回退到软件渲染（虚拟机或不支持 Metal 的情况）
            context = operations.createContext(with: nil, options: [
                .useSoftwareRenderer: true,
                .workingColorSpace: CGColorSpaceCreateDeviceRGB(),
                .name: "Airis.CoreImage.Software" as NSString,
            ])
        }

        if let device = metalDevice {
            AirisLog.debug("CoreImageService using Metal device: \(device.name)")
        } else {
            AirisLog.debug("CoreImageService using software renderer")
        }
    }

    /// 统一处理滤镜输出，支持测试时覆盖结果或触发回退路径
    private func output(from filter: CIFilter, input: CIImage) -> CIImage {
        if let override = outputOverride {
            return override(filter, input) ?? input
        }
        guard let outputImage = filter.outputImage else {
            return input
        }
        return outputImage
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
        filter.scale = Float(scaleY) // Lanczos 使用 Y 轴缩放作为主缩放
        filter.aspectRatio = Float(scaleX / scaleY) // 宽高比调整

        return output(from: filter, input: ciImage)
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
            let offsetX = max(0, -newExtent.origin.x)
            let offsetY = max(0, -newExtent.origin.y)
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
        guard let filter = filterFactory.gaussianBlur() else {
            return ciImage
        }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(Float(max(0, radius)), forKey: kCIInputRadiusKey)

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
        return output(from: filter, input: ciImage)
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
        return output(from: filter, input: ciImage)
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
        return output(from: filter, input: ciImage)
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
        return output(from: filter, input: ciImage)
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
        return output(from: filter, input: ciImage)
    }

    /// 灰度转换
    ///
    /// - Parameter ciImage: 输入图像
    /// - Returns: 灰度图像
    func grayscale(ciImage: CIImage) -> CIImage {
        adjustSaturation(ciImage: ciImage, saturation: 0)
    }

    /// 反色（负片效果）
    ///
    /// - Parameter ciImage: 输入图像
    /// - Returns: 反色后的图像
    func invert(ciImage: CIImage) -> CIImage {
        let filter = CIFilter.colorInvert()
        filter.inputImage = ciImage
        return output(from: filter, input: ciImage)
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
        return output(from: filter, input: ciImage)
    }

    // MARK: - 模糊效果

    /// 运动模糊
    ///
    /// - Parameters:
    ///   - ciImage: 输入图像
    ///   - radius: 模糊半径（默认 10，范围建议 0-100）
    ///   - angle: 运动方向角度（默认 0，范围 0-360 度）
    /// - Returns: 运动模糊后的 CIImage
    func motionBlur(ciImage: CIImage, radius: Double = 10, angle: Double = 0) -> CIImage {
        guard let filter = filterFactory.motionBlur() else {
            return ciImage
        }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(Float(max(0, radius)), forKey: kCIInputRadiusKey)
        // CIMotionBlur 使用弧度，角度需要转换
        filter.setValue(Float(angle * .pi / 180.0), forKey: kCIInputAngleKey)

        guard let output = filter.outputImage else {
            return ciImage
        }

        // 模糊会扩展图像边界，裁剪回原始大小
        return output.cropped(to: ciImage.extent)
    }

    /// 缩放模糊（径向模糊）
    ///
    /// - Parameters:
    ///   - ciImage: 输入图像
    ///   - center: 模糊中心点（默认为图像中心）
    ///   - amount: 模糊量（默认 10，范围建议 0-100）
    /// - Returns: 缩放模糊后的 CIImage
    func zoomBlur(ciImage: CIImage, center: CGPoint? = nil, amount: Double = 10) -> CIImage {
        guard let filter = filterFactory.zoomBlur() else {
            return ciImage
        }

        // 默认使用图像中心
        let blurCenter = center ?? CGPoint(
            x: ciImage.extent.midX,
            y: ciImage.extent.midY
        )
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgPoint: blurCenter), forKey: kCIInputCenterKey)
        filter.setValue(Float(max(0, amount)), forKey: "inputAmount")

        guard let output = filter.outputImage else {
            return ciImage
        }

        // 模糊会扩展图像边界，裁剪回原始大小
        return output.cropped(to: ciImage.extent)
    }

    // MARK: - 锐化和降噪

    /// 非锐化蒙版（更精细的锐化控制）
    ///
    /// - Parameters:
    ///   - ciImage: 输入图像
    ///   - radius: 影响区域半径（默认 2.5，范围建议 0-10）
    ///   - intensity: 锐化强度（默认 0.5，范围建议 0-2）
    /// - Returns: 锐化后的 CIImage
    func unsharpMask(ciImage: CIImage, radius: Double = 2.5, intensity: Double = 0.5) -> CIImage {
        let filter = CIFilter.unsharpMask()
        filter.inputImage = ciImage
        filter.radius = Float(max(0, radius))
        filter.intensity = Float(max(0, intensity))
        return output(from: filter, input: ciImage)
    }

    /// 降噪
    ///
    /// - Parameters:
    ///   - ciImage: 输入图像
    ///   - noiseLevel: 噪声级别（默认 0.02，范围建议 0-0.1）
    ///   - sharpness: 锐度保持（默认 0.4，范围建议 0-2）
    /// - Returns: 降噪后的 CIImage
    func noiseReduction(ciImage: CIImage, noiseLevel: Double = 0.02, sharpness: Double = 0.4) -> CIImage {
        let filter = CIFilter.noiseReduction()
        filter.inputImage = ciImage
        filter.noiseLevel = Float(max(0, noiseLevel))
        filter.sharpness = Float(max(0, sharpness))
        return output(from: filter, input: ciImage)
    }

    // MARK: - 像素化效果

    /// 像素化
    ///
    /// - Parameters:
    ///   - ciImage: 输入图像
    ///   - scale: 像素块大小（默认 8，范围建议 1-100）
    /// - Returns: 像素化后的 CIImage
    func pixellate(ciImage: CIImage, scale: Double = 8) -> CIImage {
        let filter = CIFilter.pixellate()
        filter.inputImage = ciImage
        filter.scale = Float(max(1, scale))

        // 默认使用图像中心
        filter.center = CGPoint(
            x: ciImage.extent.midX,
            y: ciImage.extent.midY
        )

        return output(from: filter, input: ciImage)
    }

    // MARK: - 艺术效果

    /// 漫画效果
    ///
    /// - Parameter ciImage: 输入图像
    /// - Returns: 漫画风格的 CIImage
    func comicEffect(ciImage: CIImage) -> CIImage {
        let filter = CIFilter.comicEffect()
        filter.inputImage = ciImage
        return output(from: filter, input: ciImage)
    }

    /// 半色调效果（网点印刷风格）
    ///
    /// - Parameters:
    ///   - ciImage: 输入图像
    ///   - width: 网点间距（默认 6，范围建议 1-50）
    ///   - angle: 网点角度（默认 0 度）
    ///   - sharpness: 边缘锐度（默认 0.7，范围 0-1）
    /// - Returns: 半色调效果的 CIImage
    func halftone(ciImage: CIImage, width: Double = 6, angle: Double = 0, sharpness: Double = 0.7) -> CIImage {
        let filter = CIFilter.dotScreen()
        filter.inputImage = ciImage
        filter.width = Float(max(1, width))
        filter.angle = Float(angle * .pi / 180.0)
        filter.sharpness = Float(max(0, min(1, sharpness)))

        // 默认使用图像中心
        filter.center = CGPoint(
            x: ciImage.extent.midX,
            y: ciImage.extent.midY
        )

        return output(from: filter, input: ciImage)
    }

    // MARK: - 照片效果滤镜

    /// 黑白效果
    ///
    /// - Parameter ciImage: 输入图像
    /// - Returns: 黑白效果的 CIImage
    func photoEffectMono(ciImage: CIImage) -> CIImage {
        let filter = CIFilter.photoEffectMono()
        filter.inputImage = ciImage
        return output(from: filter, input: ciImage)
    }

    /// 铬黄效果
    ///
    /// - Parameter ciImage: 输入图像
    /// - Returns: 铬黄效果的 CIImage
    func photoEffectChrome(ciImage: CIImage) -> CIImage {
        let filter = CIFilter.photoEffectChrome()
        filter.inputImage = ciImage
        return output(from: filter, input: ciImage)
    }

    /// 黑色电影效果（高对比度黑白）
    ///
    /// - Parameter ciImage: 输入图像
    /// - Returns: 黑色电影效果的 CIImage
    func photoEffectNoir(ciImage: CIImage) -> CIImage {
        let filter = CIFilter.photoEffectNoir()
        filter.inputImage = ciImage
        return output(from: filter, input: ciImage)
    }

    /// 即时相机效果（宝丽来风格）
    ///
    /// - Parameter ciImage: 输入图像
    /// - Returns: 即时相机效果的 CIImage
    func photoEffectInstant(ciImage: CIImage) -> CIImage {
        let filter = CIFilter.photoEffectInstant()
        filter.inputImage = ciImage
        return output(from: filter, input: ciImage)
    }

    /// 褪色效果
    ///
    /// - Parameter ciImage: 输入图像
    /// - Returns: 褪色效果的 CIImage
    func photoEffectFade(ciImage: CIImage) -> CIImage {
        let filter = CIFilter.photoEffectFade()
        filter.inputImage = ciImage
        return output(from: filter, input: ciImage)
    }

    /// 复古冲印效果
    ///
    /// - Parameter ciImage: 输入图像
    /// - Returns: 复古冲印效果的 CIImage
    func photoEffectProcess(ciImage: CIImage) -> CIImage {
        let filter = CIFilter.photoEffectProcess()
        filter.inputImage = ciImage
        return output(from: filter, input: ciImage)
    }

    /// 色调转移效果
    ///
    /// - Parameter ciImage: 输入图像
    /// - Returns: 色调转移效果的 CIImage
    func photoEffectTransfer(ciImage: CIImage) -> CIImage {
        let filter = CIFilter.photoEffectTransfer()
        filter.inputImage = ciImage
        return output(from: filter, input: ciImage)
    }

    /// 暗角效果
    ///
    /// - Parameters:
    ///   - ciImage: 输入图像
    ///   - intensity: 暗角强度（默认 1，范围建议 0-2）
    ///   - radius: 暗角半径（默认为图像对角线的一半）
    /// - Returns: 带暗角效果的 CIImage
    func vignette(ciImage: CIImage, intensity: Double = 1, radius: Double? = nil) -> CIImage {
        let filter = CIFilter.vignette()
        filter.inputImage = ciImage
        filter.intensity = Float(max(0, intensity))

        // 计算默认半径（图像对角线的一半）
        let extent = ciImage.extent
        let defaultRadius = sqrt(extent.width * extent.width + extent.height * extent.height) / 2
        filter.radius = Float(radius ?? Double(defaultRadius))

        return output(from: filter, input: ciImage)
    }

    // MARK: - 渲染

    /// 渲染 CIImage 到 CGImage
    ///
    /// - Parameter ciImage: 要渲染的 CIImage
    /// - Returns: 渲染后的 CGImage，如果失败返回 nil
    func render(ciImage: CIImage) -> CGImage? {
        if let rendererOverride {
            return rendererOverride(ciImage)
        }
        return context.createCGImage(ciImage, from: ciImage.extent)
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
            // macOS 上该 API 不可用，返回合理默认值
            return CGSize(width: 16384, height: 16384)
        #endif
    }

    /// 获取 CIContext 支持的最大输出图像尺寸
    /// - Note: 在 macOS 上返回一个合理的默认值，iOS 上使用实际值
    func maxOutputImageSize() -> CGSize {
        #if os(iOS) || os(tvOS) || os(visionOS)
            return context.outputImageMaximumSize()
        #else
            // macOS 上该 API 不可用，返回合理默认值
            return CGSize(width: 16384, height: 16384)
        #endif
    }

    /// 清理缓存（处理大量图像后建议调用）
    func clearCaches() {
        context.clearCaches()
    }

    // MARK: - 从 Task 6.3 添加的方法

    /// 透视校正
    func perspectiveCorrection(
        ciImage: CIImage,
        topLeft: CGPoint,
        topRight: CGPoint,
        bottomLeft: CGPoint,
        bottomRight: CGPoint
    ) -> CIImage? {
        guard let filter = filterFactory.perspectiveCorrection() else {
            return nil
        }

        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgPoint: topLeft), forKey: "inputTopLeft")
        filter.setValue(CIVector(cgPoint: topRight), forKey: "inputTopRight")
        filter.setValue(CIVector(cgPoint: bottomLeft), forKey: "inputBottomLeft")
        filter.setValue(CIVector(cgPoint: bottomRight), forKey: "inputBottomRight")

        return filter.outputImage
    }

    /// 边缘检测（Edge Work）
    func edgeWork(ciImage: CIImage, radius: Double = 3.0) -> CIImage? {
        let filter = CIFilter.edgeWork()
        filter.inputImage = ciImage
        filter.radius = Float(radius)
        return filter.outputImage
    }

    /// 边缘检测（Edges）
    func edges(ciImage: CIImage, intensity: Double = 1.0) -> CIImage? {
        let filter = CIFilter.edges()
        filter.inputImage = ciImage
        filter.intensity = Float(intensity)
        return filter.outputImage
    }

    /// 线条叠加
    func lineOverlay(
        ciImage: CIImage,
        nrNoiseLevel: Double = 0.07,
        nrSharpness: Double = 0.71,
        edgeIntensity: Double = 1.0,
        threshold: Double = 0.1,
        contrast: Double = 50
    ) -> CIImage {
        let filter = CIFilter.lineOverlay()
        filter.inputImage = ciImage
        filter.nrNoiseLevel = Float(nrNoiseLevel)
        filter.nrSharpness = Float(nrSharpness)
        filter.edgeIntensity = Float(edgeIntensity)
        filter.threshold = Float(threshold)
        filter.contrast = Float(contrast)
        return output(from: filter, input: ciImage)
    }

    /// 去紫边
    func defringe(ciImage: CIImage, amount: Double = 0.5) -> CIImage {
        guard let filter = filterFactory.hueAdjust() else {
            return ciImage
        }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(amount * 0.1, forKey: kCIInputAngleKey)
        return output(from: filter, input: ciImage)
    }

    // MARK: - 从 Task 8.1 添加的方法

    /// 曝光调整
    func adjustExposure(ciImage: CIImage, ev: Double) -> CIImage {
        let filter = CIFilter.exposureAdjust()
        filter.inputImage = ciImage
        filter.ev = Float(max(-10, min(10, ev)))
        return output(from: filter, input: ciImage)
    }

    /// 色温和色调调整
    func adjustTemperatureAndTint(
        ciImage: CIImage,
        temperature: Double = 0,
        tint: Double = 0
    ) -> CIImage {
        let filter = CIFilter.temperatureAndTint()
        filter.inputImage = ciImage
        let neutralTemp: CGFloat = 6500
        let targetTemp = neutralTemp + CGFloat(temperature)
        filter.neutral = CIVector(x: neutralTemp, y: 0)
        filter.targetNeutral = CIVector(x: targetTemp, y: CGFloat(tint))
        return output(from: filter, input: ciImage)
    }

    /// 色调分离
    func posterize(ciImage: CIImage, levels: Double = 6.0) -> CIImage {
        let filter = CIFilter.colorPosterize()
        filter.inputImage = ciImage
        filter.levels = Float(max(2, min(30, levels)))
        return output(from: filter, input: ciImage)
    }

    /// 阈值化
    func threshold(ciImage: CIImage, threshold: Double = 0.5) -> CIImage {
        guard let filter = filterFactory.colorThreshold() else {
            let grayscale = adjustSaturation(ciImage: ciImage, saturation: 0)
            let posterized = posterize(ciImage: grayscale, levels: 2)
            return posterized
        }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(max(0, min(1, threshold)), forKey: "inputThreshold")
        return output(from: filter, input: ciImage)
    }

    /// 自动增强图像
    func autoEnhance(ciImage: CIImage, enableRedEye _: Bool = true) -> CIImage {
        let filters = ciImage.autoAdjustmentFilters()

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

    /// 获取自动增强将应用的滤镜信息
    func getAutoEnhanceFilters(for ciImage: CIImage) -> [String] {
        let filters = ciImage.autoAdjustmentFilters()
        return filters.map(\.name)
    }

    /// 检查是否使用 Metal 加速
    var isUsingMetalAcceleration: Bool {
        metalDevice != nil
    }

    // MARK: - 坐标系转换工具

    /// 将 Vision 框架坐标转换为 CoreImage 坐标
    static func convertVisionToCI(rect: CGRect, imageHeight: CGFloat) -> CGRect {
        CGRect(
            x: rect.origin.x,
            y: imageHeight - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
    }

    /// 将 CoreImage 坐标转换为 Vision 框架坐标
    static func convertCIToVision(rect: CGRect, imageHeight: CGFloat) -> CGRect {
        CGRect(
            x: rect.origin.x,
            y: imageHeight - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
    }

    /// 透视校正（归一化坐标版本）
    func perspectiveCorrectionNormalized(
        ciImage: CIImage,
        normalizedTopLeft: CGPoint,
        normalizedTopRight: CGPoint,
        normalizedBottomLeft: CGPoint,
        normalizedBottomRight: CGPoint
    ) -> CIImage? {
        let extent = ciImage.extent

        let topLeft = CGPoint(
            x: normalizedTopLeft.x * extent.width,
            y: normalizedTopLeft.y * extent.height
        )
        let topRight = CGPoint(
            x: normalizedTopRight.x * extent.width,
            y: normalizedTopRight.y * extent.height
        )
        let bottomLeft = CGPoint(
            x: normalizedBottomLeft.x * extent.width,
            y: normalizedBottomLeft.y * extent.height
        )
        let bottomRight = CGPoint(
            x: normalizedBottomRight.x * extent.width,
            y: normalizedBottomRight.y * extent.height
        )

        return perspectiveCorrection(
            ciImage: ciImage,
            topLeft: topLeft,
            topRight: topRight,
            bottomLeft: bottomLeft,
            bottomRight: bottomRight
        )
    }
}
