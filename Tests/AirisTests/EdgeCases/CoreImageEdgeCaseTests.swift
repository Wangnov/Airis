import XCTest
import CoreImage
@testable import Airis

/// 边界测试 - CoreImage 服务
///
/// 测试目标:
/// - 测试极端参数值
/// - 测试大图像处理
/// - 测试空/无效输入
/// - 测试边界条件
final class CoreImageEdgeCaseTests: XCTestCase {

    // ✅ Apple 最佳实践：类级别共享服务
    nonisolated(unsafe) static let sharedCoreImageService = CoreImageService()

    var service: CoreImageService!

    override func setUp() {
        super.setUp()
        service = CoreImageService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // MARK: - 极大图像测试

    /// 测试 8K 图像处理
    func testHugeImageProcessing_8K() throws {
        // 创建 8K 图像 (7680 x 4320)
        let hugeImage = CIImage(color: .white)
            .cropped(to: CGRect(x: 0, y: 0, width: 7680, height: 4320))

        let resized = service.resize(ciImage: hugeImage, width: 1920, height: 1080)
        XCTAssertNotNil(resized)
        XCTAssertEqual(resized.extent.width, 1920, accuracy: 1)
    }

    /// 测试极大模糊半径
    func testExtremeBlurRadius() throws {
        let image = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        // 极大模糊半径
        let blurred = service.gaussianBlur(ciImage: image, radius: 100)
        XCTAssertNotNil(blurred)
        XCTAssertEqual(blurred.extent.width, 100)
    }

    /// 测试零模糊半径
    func testZeroBlurRadius() throws {
        let image = CIImage(color: .blue)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        let blurred = service.gaussianBlur(ciImage: image, radius: 0)
        XCTAssertNotNil(blurred)
    }

    /// 测试负模糊半径（应该被处理为 0）
    func testNegativeBlurRadius() throws {
        let image = CIImage(color: .green)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        // 负值应该被 max(0, radius) 处理
        let blurred = service.gaussianBlur(ciImage: image, radius: -10)
        XCTAssertNotNil(blurred)
    }

    // MARK: - 极端参数测试

    /// 测试极大锐化值
    func testExtremeSharpen() throws {
        let image = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        let sharpened = service.sharpen(ciImage: image, sharpness: 10.0)
        XCTAssertNotNil(sharpened)
    }

    /// 测试极端亮度调整
    func testExtremeBrightness() throws {
        let image = CIImage(color: .gray)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        // 最大亮度
        let bright = service.adjustBrightness(ciImage: image, brightness: 1.0)
        XCTAssertNotNil(bright)

        // 最小亮度
        let dark = service.adjustBrightness(ciImage: image, brightness: -1.0)
        XCTAssertNotNil(dark)
    }

    /// 测试极端对比度调整
    func testExtremeContrast() throws {
        let image = CIImage(color: .gray)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        // 最大对比度
        let highContrast = service.adjustContrast(ciImage: image, contrast: 4.0)
        XCTAssertNotNil(highContrast)

        // 最小对比度
        let lowContrast = service.adjustContrast(ciImage: image, contrast: 0.25)
        XCTAssertNotNil(lowContrast)
    }

    /// 测试零饱和度（灰度）
    func testZeroSaturation() throws {
        let image = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        let grayscale = service.adjustSaturation(ciImage: image, saturation: 0)
        XCTAssertNotNil(grayscale)
    }

    /// 测试极大饱和度
    func testExtremeSaturation() throws {
        let image = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        let saturated = service.adjustSaturation(ciImage: image, saturation: 2.0)
        XCTAssertNotNil(saturated)
    }

    // MARK: - 裁剪边界测试

    /// 测试完全超出边界的裁剪
    func testCropCompletelyOutOfBounds() throws {
        let image = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        // 完全超出边界的裁剪区域
        let cropRect = CGRect(x: 200, y: 200, width: 50, height: 50)
        let cropped = service.crop(ciImage: image, rect: cropRect)

        // 应该返回原图（因为交集为空）
        XCTAssertEqual(cropped.extent.width, image.extent.width)
    }

    /// 测试部分超出边界的裁剪
    func testCropPartiallyOutOfBounds() throws {
        let image = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        // 部分超出边界
        let cropRect = CGRect(x: 80, y: 80, width: 50, height: 50)
        let cropped = service.crop(ciImage: image, rect: cropRect)

        // 应该裁剪到有效区域 (20 x 20)
        XCTAssertEqual(cropped.extent.width, 20)
        XCTAssertEqual(cropped.extent.height, 20)
    }

    /// 测试零尺寸裁剪
    func testCropZeroSize() throws {
        let image = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        let cropRect = CGRect(x: 50, y: 50, width: 0, height: 0)
        let cropped = service.crop(ciImage: image, rect: cropRect)

        // 零尺寸裁剪应返回原图
        XCTAssertEqual(cropped.extent.width, image.extent.width)
    }

    // MARK: - 缩放边界测试

    /// 测试缩放到极小尺寸
    func testResizeToTinySize() throws {
        let image = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 1000, height: 1000))

        let resized = service.resize(ciImage: image, width: 1, height: 1)
        XCTAssertNotNil(resized)
        XCTAssertGreaterThan(resized.extent.width, 0)
    }

    /// 测试不指定尺寸的缩放
    func testResizeNoSize() throws {
        let image = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        let resized = service.resize(ciImage: image)
        XCTAssertEqual(resized.extent.width, image.extent.width)
        XCTAssertEqual(resized.extent.height, image.extent.height)
    }

    // MARK: - 旋转边界测试

    /// 测试 360 度旋转
    func testRotate360Degrees() throws {
        let image = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        let rotated = service.rotateAroundCenter(ciImage: image, degrees: 360)
        XCTAssertNotNil(rotated)
    }

    /// 测试负角度旋转
    func testRotateNegativeAngle() throws {
        let image = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        let rotated = service.rotateAroundCenter(ciImage: image, degrees: -45)
        XCTAssertNotNil(rotated)
    }

    /// 测试极大角度旋转
    func testRotateLargeAngle() throws {
        let image = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        let rotated = service.rotateAroundCenter(ciImage: image, degrees: 7200) // 20 圈
        XCTAssertNotNil(rotated)
    }

    // MARK: - 翻转边界测试

    /// 测试不翻转
    func testFlipNone() throws {
        let image = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        let flipped = service.flip(ciImage: image, horizontal: false, vertical: false)
        XCTAssertEqual(flipped.extent, image.extent)
    }

    /// 测试双向翻转
    func testFlipBoth() throws {
        let image = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        let flipped = service.flip(ciImage: image, horizontal: true, vertical: true)
        XCTAssertNotNil(flipped)
    }

    // MARK: - 像素化边界测试

    /// 测试最小像素化比例
    func testPixellateMinScale() throws {
        let image = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        let pixellated = service.pixellate(ciImage: image, scale: 1)
        XCTAssertNotNil(pixellated)
    }

    /// 测试极大像素化比例
    func testPixellateLargeScale() throws {
        let image = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        let pixellated = service.pixellate(ciImage: image, scale: 100)
        XCTAssertNotNil(pixellated)
    }

    // MARK: - 暗角边界测试

    /// 测试零暗角强度
    func testVignetteZeroIntensity() throws {
        let image = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        let vignetted = service.vignette(ciImage: image, intensity: 0)
        XCTAssertNotNil(vignetted)
    }

    /// 测试极大暗角强度
    func testVignetteHighIntensity() throws {
        let image = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        let vignetted = service.vignette(ciImage: image, intensity: 2.0)
        XCTAssertNotNil(vignetted)
    }

    // MARK: - 色调分离边界测试

    /// 测试最小色阶
    func testPosterizeMinLevels() throws {
        let image = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        let posterized = service.posterize(ciImage: image, levels: 2)
        XCTAssertNotNil(posterized)
    }

    /// 测试最大色阶
    func testPosterizeMaxLevels() throws {
        let image = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        let posterized = service.posterize(ciImage: image, levels: 30)
        XCTAssertNotNil(posterized)
    }

    // MARK: - 阈值边界测试

    /// 测试最小阈值
    func testThresholdMin() throws {
        let image = CIImage(color: .gray)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        let thresholded = service.threshold(ciImage: image, threshold: 0)
        XCTAssertNotNil(thresholded)
    }

    /// 测试最大阈值
    func testThresholdMax() throws {
        let image = CIImage(color: .gray)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        let thresholded = service.threshold(ciImage: image, threshold: 1.0)
        XCTAssertNotNil(thresholded)
    }

    // MARK: - 曝光边界测试

    /// 测试极端曝光值
    func testExtremeExposure() throws {
        let image = CIImage(color: .gray)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        // 最大曝光
        let overexposed = service.adjustExposure(ciImage: image, ev: 10)
        XCTAssertNotNil(overexposed)

        // 最小曝光
        let underexposed = service.adjustExposure(ciImage: image, ev: -10)
        XCTAssertNotNil(underexposed)
    }

    // MARK: - 色温边界测试

    /// 测试极端色温
    func testExtremeTemperature() throws {
        let image = CIImage(color: .white)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        // 极冷色温
        let cold = service.adjustTemperatureAndTint(ciImage: image, temperature: -1000, tint: 0)
        XCTAssertNotNil(cold)

        // 极暖色温
        let warm = service.adjustTemperatureAndTint(ciImage: image, temperature: 1000, tint: 0)
        XCTAssertNotNil(warm)
    }

    // MARK: - 透视校正边界测试

    /// 测试透视校正 - 极端点位
    func testPerspectiveCorrectionExtremePoints() throws {
        let image = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        // 非常接近的点
        let result = service.perspectiveCorrection(
            ciImage: image,
            topLeft: CGPoint(x: 10, y: 90),
            topRight: CGPoint(x: 90, y: 90),
            bottomLeft: CGPoint(x: 10, y: 10),
            bottomRight: CGPoint(x: 90, y: 10)
        )
        XCTAssertNotNil(result)
    }
}
