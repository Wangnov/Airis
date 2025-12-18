import CoreImage
import XCTest
#if !XCODE_BUILD
    @testable import AirisCore
#endif

/// Task 8.1 Adjust Commands Tests
/// 测试 CoreImageService 中新增的调整方法
final class AdjustCommandTests: XCTestCase {
    var service: CoreImageService!
    var testCIImage: CIImage!

    override func setUp() {
        super.setUp()
        service = CoreImageService()

        // 创建测试用 CIImage（100x100 彩色渐变）
        testCIImage = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
    }

    override func tearDown() {
        service = nil
        testCIImage = nil
        super.tearDown()
    }

    // MARK: - Exposure Tests

    func testAdjustExposure_Positive() throws {
        let adjusted = service.adjustExposure(ciImage: testCIImage, ev: 1.0)

        XCTAssertNotNil(adjusted)
        XCTAssertEqual(adjusted.extent.width, testCIImage.extent.width)
        XCTAssertEqual(adjusted.extent.height, testCIImage.extent.height)
    }

    func testAdjustExposure_Negative() throws {
        let adjusted = service.adjustExposure(ciImage: testCIImage, ev: -1.0)

        XCTAssertNotNil(adjusted)
        XCTAssertEqual(adjusted.extent.width, testCIImage.extent.width)
    }

    func testAdjustExposure_Zero() throws {
        let adjusted = service.adjustExposure(ciImage: testCIImage, ev: 0)

        XCTAssertNotNil(adjusted)
        XCTAssertEqual(adjusted.extent.width, testCIImage.extent.width)
    }

    func testAdjustExposure_ExtremePositive() throws {
        // 极端正值应该被裁剪到 10
        let adjusted = service.adjustExposure(ciImage: testCIImage, ev: 20)

        XCTAssertNotNil(adjusted)
    }

    func testAdjustExposure_ExtremeNegative() throws {
        // 极端负值应该被裁剪到 -10
        let adjusted = service.adjustExposure(ciImage: testCIImage, ev: -20)

        XCTAssertNotNil(adjusted)
    }

    // MARK: - Temperature and Tint Tests

    func testAdjustTemperatureAndTint_Warm() throws {
        let adjusted = service.adjustTemperatureAndTint(ciImage: testCIImage, temperature: 2000, tint: 0)

        XCTAssertNotNil(adjusted)
        XCTAssertEqual(adjusted.extent.width, testCIImage.extent.width)
    }

    func testAdjustTemperatureAndTint_Cool() throws {
        let adjusted = service.adjustTemperatureAndTint(ciImage: testCIImage, temperature: -2000, tint: 0)

        XCTAssertNotNil(adjusted)
        XCTAssertEqual(adjusted.extent.width, testCIImage.extent.width)
    }

    func testAdjustTemperatureAndTint_TintOnly() throws {
        let adjusted = service.adjustTemperatureAndTint(ciImage: testCIImage, temperature: 0, tint: 50)

        XCTAssertNotNil(adjusted)
        XCTAssertEqual(adjusted.extent.width, testCIImage.extent.width)
    }

    func testAdjustTemperatureAndTint_Combined() throws {
        let adjusted = service.adjustTemperatureAndTint(ciImage: testCIImage, temperature: 1500, tint: -30)

        XCTAssertNotNil(adjusted)
        XCTAssertEqual(adjusted.extent.width, testCIImage.extent.width)
    }

    func testAdjustTemperatureAndTint_NoChange() throws {
        let adjusted = service.adjustTemperatureAndTint(ciImage: testCIImage, temperature: 0, tint: 0)

        XCTAssertNotNil(adjusted)
        XCTAssertEqual(adjusted.extent.width, testCIImage.extent.width)
    }

    // MARK: - Vignette Tests

    func testVignette_Default() throws {
        let vignetted = service.vignette(ciImage: testCIImage)

        XCTAssertNotNil(vignetted)
        XCTAssertEqual(vignetted.extent.width, testCIImage.extent.width)
    }

    func testVignette_HighIntensity() throws {
        let vignetted = service.vignette(ciImage: testCIImage, intensity: 2.0, radius: 1.0)

        XCTAssertNotNil(vignetted)
        XCTAssertEqual(vignetted.extent.width, testCIImage.extent.width)
    }

    func testVignette_LowRadius() throws {
        let vignetted = service.vignette(ciImage: testCIImage, intensity: 1.0, radius: 0.5)

        XCTAssertNotNil(vignetted)
        XCTAssertEqual(vignetted.extent.width, testCIImage.extent.width)
    }

    func testVignette_NoEffect() throws {
        let vignetted = service.vignette(ciImage: testCIImage, intensity: 0, radius: 1.0)

        XCTAssertNotNil(vignetted)
        XCTAssertEqual(vignetted.extent.width, testCIImage.extent.width)
    }

    func testVignette_ExtremeValues() throws {
        // 超出范围的值应该被裁剪
        let vignetted = service.vignette(ciImage: testCIImage, intensity: 5.0, radius: 5.0)

        XCTAssertNotNil(vignetted)
    }

    // MARK: - Posterize Tests

    func testPosterize_Default() throws {
        let posterized = service.posterize(ciImage: testCIImage)

        XCTAssertNotNil(posterized)
        XCTAssertEqual(posterized.extent.width, testCIImage.extent.width)
    }

    func testPosterize_MinLevels() throws {
        let posterized = service.posterize(ciImage: testCIImage, levels: 2)

        XCTAssertNotNil(posterized)
        XCTAssertEqual(posterized.extent.width, testCIImage.extent.width)
    }

    func testPosterize_MaxLevels() throws {
        let posterized = service.posterize(ciImage: testCIImage, levels: 30)

        XCTAssertNotNil(posterized)
        XCTAssertEqual(posterized.extent.width, testCIImage.extent.width)
    }

    func testPosterize_MediumLevels() throws {
        let posterized = service.posterize(ciImage: testCIImage, levels: 8)

        XCTAssertNotNil(posterized)
        XCTAssertEqual(posterized.extent.width, testCIImage.extent.width)
    }

    func testPosterize_ExtremeValues() throws {
        // 超出范围的值应该被裁剪
        let posterized = service.posterize(ciImage: testCIImage, levels: 100)

        XCTAssertNotNil(posterized)
    }

    // MARK: - Threshold Tests

    func testThreshold_Default() throws {
        let thresholded = service.threshold(ciImage: testCIImage)

        XCTAssertNotNil(thresholded)
        XCTAssertEqual(thresholded.extent.width, testCIImage.extent.width)
    }

    func testThreshold_Low() throws {
        let thresholded = service.threshold(ciImage: testCIImage, threshold: 0.2)

        XCTAssertNotNil(thresholded)
        XCTAssertEqual(thresholded.extent.width, testCIImage.extent.width)
    }

    func testThreshold_High() throws {
        let thresholded = service.threshold(ciImage: testCIImage, threshold: 0.8)

        XCTAssertNotNil(thresholded)
        XCTAssertEqual(thresholded.extent.width, testCIImage.extent.width)
    }

    func testThreshold_Min() throws {
        let thresholded = service.threshold(ciImage: testCIImage, threshold: 0)

        XCTAssertNotNil(thresholded)
    }

    func testThreshold_Max() throws {
        let thresholded = service.threshold(ciImage: testCIImage, threshold: 1.0)

        XCTAssertNotNil(thresholded)
    }

    func testThreshold_ExtremeValues() throws {
        // 超出范围的值应该被裁剪
        let thresholded1 = service.threshold(ciImage: testCIImage, threshold: -0.5)
        let thresholded2 = service.threshold(ciImage: testCIImage, threshold: 1.5)

        XCTAssertNotNil(thresholded1)
        XCTAssertNotNil(thresholded2)
    }

    // MARK: - Invert Tests (inherited from existing tests but added for completeness)

    func testInvert_PreservesSize() throws {
        let inverted = service.invert(ciImage: testCIImage)

        XCTAssertNotNil(inverted)
        XCTAssertEqual(inverted.extent.width, testCIImage.extent.width)
        XCTAssertEqual(inverted.extent.height, testCIImage.extent.height)
    }

    func testInvert_DoubleInvert() throws {
        // 双重反色应该产生可渲染的图像
        let inverted1 = service.invert(ciImage: testCIImage)
        let inverted2 = service.invert(ciImage: inverted1)

        XCTAssertNotNil(inverted2)
        XCTAssertEqual(inverted2.extent.width, testCIImage.extent.width)
    }

    // MARK: - Flip Tests (enhanced from existing tests)

    func testFlip_HorizontalPreservesSize() throws {
        let flipped = service.flip(ciImage: testCIImage, horizontal: true)

        XCTAssertNotNil(flipped)
        XCTAssertEqual(flipped.extent.width, testCIImage.extent.width)
        XCTAssertEqual(flipped.extent.height, testCIImage.extent.height)
    }

    func testFlip_VerticalPreservesSize() throws {
        let flipped = service.flip(ciImage: testCIImage, vertical: true)

        XCTAssertNotNil(flipped)
        XCTAssertEqual(flipped.extent.width, testCIImage.extent.width)
        XCTAssertEqual(flipped.extent.height, testCIImage.extent.height)
    }

    func testFlip_BothPreservesSize() throws {
        let flipped = service.flip(ciImage: testCIImage, horizontal: true, vertical: true)

        XCTAssertNotNil(flipped)
        XCTAssertEqual(flipped.extent.width, testCIImage.extent.width)
        XCTAssertEqual(flipped.extent.height, testCIImage.extent.height)
    }

    func testFlip_DoubleHorizontal() throws {
        // 双重水平翻转应该回到原始状态（可渲染）
        let flipped1 = service.flip(ciImage: testCIImage, horizontal: true)
        let flipped2 = service.flip(ciImage: flipped1, horizontal: true)

        XCTAssertNotNil(flipped2)
        XCTAssertEqual(flipped2.extent.width, testCIImage.extent.width)
    }

    // MARK: - Rotate Tests (enhanced from existing tests)

    func testRotate_90Degrees() throws {
        let rotated = service.rotateAroundCenter(ciImage: testCIImage, degrees: 90)

        XCTAssertNotNil(rotated)
        // 方形图像旋转后仍是方形
        XCTAssertEqual(rotated.extent.width, 100, accuracy: 2)
        XCTAssertEqual(rotated.extent.height, 100, accuracy: 2)
    }

    func testRotate_180Degrees() throws {
        let rotated = service.rotateAroundCenter(ciImage: testCIImage, degrees: 180)

        XCTAssertNotNil(rotated)
        XCTAssertEqual(rotated.extent.width, 100, accuracy: 2)
    }

    func testRotate_270Degrees() throws {
        let rotated = service.rotateAroundCenter(ciImage: testCIImage, degrees: 270)

        XCTAssertNotNil(rotated)
        XCTAssertEqual(rotated.extent.width, 100, accuracy: 2)
    }

    func testRotate_45Degrees() throws {
        let rotated = service.rotateAroundCenter(ciImage: testCIImage, degrees: 45)

        XCTAssertNotNil(rotated)
        // 45度旋转后图像会扩展
        XCTAssertGreaterThan(rotated.extent.width, 100)
    }

    func testRotate_Negative90Degrees() throws {
        let rotated = service.rotateAroundCenter(ciImage: testCIImage, degrees: -90)

        XCTAssertNotNil(rotated)
        XCTAssertEqual(rotated.extent.width, 100, accuracy: 2)
    }

    func testRotate_SmallAngle() throws {
        // 小角度旋转（校正倾斜）
        let rotated = service.rotateAroundCenter(ciImage: testCIImage, degrees: 2.5)

        XCTAssertNotNil(rotated)
        XCTAssertGreaterThan(rotated.extent.width, 0)
    }

    // MARK: - Combined Filter Chain Tests

    func testCombinedAdjustments() throws {
        // 测试多个调整组合
        var image = try XCTUnwrap(testCIImage)
        image = service.adjustExposure(ciImage: image, ev: 0.5)
        image = service.adjustColors(ciImage: image, brightness: 0.1, contrast: 1.1, saturation: 1.2)
        image = service.vignette(ciImage: image, intensity: 0.8, radius: 1.0)

        XCTAssertNotNil(image)
        XCTAssertEqual(image.extent.width, testCIImage.extent.width)
    }

    func testCombinedGeometricTransforms() throws {
        // 测试翻转 + 旋转组合
        var image = try XCTUnwrap(testCIImage)
        image = service.flip(ciImage: image, horizontal: true)
        image = service.rotateAroundCenter(ciImage: image, degrees: 90)

        XCTAssertNotNil(image)
        XCTAssertGreaterThan(image.extent.width, 0)
    }

    func testCombinedToneEffects() throws {
        // 测试色调效果组合
        var image = try XCTUnwrap(testCIImage)
        image = service.posterize(ciImage: image, levels: 6)
        image = service.adjustColors(ciImage: image, saturation: 1.5)

        XCTAssertNotNil(image)
        XCTAssertEqual(image.extent.width, testCIImage.extent.width)
    }

    // MARK: - Render After Adjustment Tests

    func testRenderAfterExposure() throws {
        let adjusted = service.adjustExposure(ciImage: testCIImage, ev: 1.0)
        let cgImage = service.render(ciImage: adjusted)

        XCTAssertNotNil(cgImage)
        XCTAssertEqual(cgImage?.width, Int(testCIImage.extent.width))
    }

    func testRenderAfterTemperature() throws {
        let adjusted = service.adjustTemperatureAndTint(ciImage: testCIImage, temperature: 1500, tint: 20)
        let cgImage = service.render(ciImage: adjusted)

        XCTAssertNotNil(cgImage)
        XCTAssertEqual(cgImage?.width, Int(testCIImage.extent.width))
    }

    func testRenderAfterVignette() throws {
        let vignetted = service.vignette(ciImage: testCIImage, intensity: 1.5, radius: 1.0)
        let cgImage = service.render(ciImage: vignetted)

        XCTAssertNotNil(cgImage)
        XCTAssertEqual(cgImage?.width, Int(testCIImage.extent.width))
    }

    func testRenderAfterPosterize() throws {
        let posterized = service.posterize(ciImage: testCIImage, levels: 4)
        let cgImage = service.render(ciImage: posterized)

        XCTAssertNotNil(cgImage)
        XCTAssertEqual(cgImage?.width, Int(testCIImage.extent.width))
    }

    func testRenderAfterThreshold() throws {
        let thresholded = service.threshold(ciImage: testCIImage, threshold: 0.5)
        let cgImage = service.render(ciImage: thresholded)

        XCTAssertNotNil(cgImage)
        XCTAssertEqual(cgImage?.width, Int(testCIImage.extent.width))
    }

    func testRenderAfterRotation() throws {
        let rotated = service.rotateAroundCenter(ciImage: testCIImage, degrees: 45)
        let cgImage = service.render(ciImage: rotated)

        XCTAssertNotNil(cgImage)
        XCTAssertGreaterThan(cgImage?.width ?? 0, 0)
    }
}
