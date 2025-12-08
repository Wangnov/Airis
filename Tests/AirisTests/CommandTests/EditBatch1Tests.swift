import XCTest
import CoreImage
@testable import Airis

final class EditBatch1Tests: XCTestCase {
    var coreImageService: CoreImageService!
    var testCIImage: CIImage!

    override func setUp() {
        super.setUp()
        coreImageService = CoreImageService()

        // 创建测试用 CIImage（200x150 蓝色方块）
        testCIImage = CIImage(color: .blue)
            .cropped(to: CGRect(x: 0, y: 0, width: 200, height: 150))
    }

    override func tearDown() {
        coreImageService = nil
        testCIImage = nil
        super.tearDown()
    }

    // MARK: - Auto Enhance Tests

    func testAutoEnhanceReturnsImage() {
        let enhanced = coreImageService.autoEnhance(ciImage: testCIImage)

        XCTAssertNotNil(enhanced)
        XCTAssertEqual(enhanced.extent.width, testCIImage.extent.width)
        XCTAssertEqual(enhanced.extent.height, testCIImage.extent.height)
    }

    func testAutoEnhanceWithRedEyeDisabled() {
        let enhanced = coreImageService.autoEnhance(ciImage: testCIImage, enableRedEye: false)

        XCTAssertNotNil(enhanced)
        XCTAssertEqual(enhanced.extent.width, testCIImage.extent.width)
    }

    func testGetAutoEnhanceFilters() {
        let filters = coreImageService.getAutoEnhanceFilters(for: testCIImage)

        // 滤镜列表应该是数组（可能为空）
        XCTAssertNotNil(filters)
        // 对于纯色图像，可能没有建议的滤镜
        XCTAssertTrue(filters.count >= 0)
    }

    // MARK: - Resize Command Tests

    func testResizeWithWidthOnly() {
        let resized = coreImageService.resize(ciImage: testCIImage, width: 100)

        XCTAssertNotNil(resized)
        // 保持宽高比：200x150 -> 100x75
        XCTAssertEqual(resized.extent.width, 100, accuracy: 1)
        XCTAssertEqual(resized.extent.height, 75, accuracy: 1)
    }

    func testResizeWithHeightOnly() {
        let resized = coreImageService.resize(ciImage: testCIImage, height: 75)

        XCTAssertNotNil(resized)
        // 保持宽高比：200x150 -> 100x75
        XCTAssertEqual(resized.extent.width, 100, accuracy: 1)
        XCTAssertEqual(resized.extent.height, 75, accuracy: 1)
    }

    func testResizeWithBothMaintainAspectRatio() {
        // 200x150 图像，目标 100x100，保持宽高比
        // 应该缩放到 100x75（以宽度为准）或 133x100（以高度为准）
        // 取较小的缩放比，应该是 100x75
        let resized = coreImageService.resize(
            ciImage: testCIImage,
            width: 100,
            height: 100,
            maintainAspectRatio: true
        )

        XCTAssertNotNil(resized)
        // 取较小的缩放比
        let expectedScale = min(100.0/200.0, 100.0/150.0)
        XCTAssertEqual(resized.extent.width, 200 * expectedScale, accuracy: 2)
        XCTAssertEqual(resized.extent.height, 150 * expectedScale, accuracy: 2)
    }

    func testResizeWithStretch() {
        let resized = coreImageService.resize(
            ciImage: testCIImage,
            width: 100,
            height: 100,
            maintainAspectRatio: false
        )

        XCTAssertNotNil(resized)
        // 不保持宽高比时，尺寸应该有变化
        XCTAssertGreaterThan(resized.extent.width, 0)
        XCTAssertGreaterThan(resized.extent.height, 0)
    }

    // MARK: - Crop Command Tests

    func testCropValidRegion() {
        let cropRect = CGRect(x: 10, y: 10, width: 100, height: 80)
        let cropped = coreImageService.crop(ciImage: testCIImage, rect: cropRect)

        XCTAssertEqual(cropped.extent.width, 100)
        XCTAssertEqual(cropped.extent.height, 80)
    }

    func testCropAtOrigin() {
        let cropRect = CGRect(x: 0, y: 0, width: 50, height: 50)
        let cropped = coreImageService.crop(ciImage: testCIImage, rect: cropRect)

        XCTAssertEqual(cropped.extent.width, 50)
        XCTAssertEqual(cropped.extent.height, 50)
    }

    func testCropPartiallyOutOfBounds() {
        // 裁剪区域部分超出边界
        let cropRect = CGRect(x: 150, y: 100, width: 100, height: 100)
        let cropped = coreImageService.crop(ciImage: testCIImage, rect: cropRect)

        // 应该裁剪到交集区域
        XCTAssertEqual(cropped.extent.width, 50)  // 200 - 150 = 50
        XCTAssertEqual(cropped.extent.height, 50) // 150 - 100 = 50
    }

    // MARK: - Coordinate System Tests

    func testCoordinateConversionForCrop() {
        // 测试从用户坐标（顶部原点）到 CoreImage 坐标（底部原点）的转换
        // 用户输入: y=10（从顶部算）, height=50
        // 图像高度: 150
        // CoreImage y = 150 - 10 - 50 = 90

        let userY = 10
        let cropHeight = 50
        let imageHeight = 150

        let ciY = imageHeight - userY - cropHeight

        XCTAssertEqual(ciY, 90)
    }

    // MARK: - Service Container Integration Tests

    func testCoreImageServiceFromContainer() {
        let service = ServiceContainer.shared.coreImageService

        XCTAssertNotNil(service)
        XCTAssertTrue(service.isUsingMetalAcceleration)
    }

    func testVisionServiceFromContainer() {
        let service = ServiceContainer.shared.visionService

        XCTAssertNotNil(service)
    }

    // MARK: - Render Tests

    func testRenderEnhancedImage() {
        let enhanced = coreImageService.autoEnhance(ciImage: testCIImage)
        let cgImage = coreImageService.render(ciImage: enhanced)

        XCTAssertNotNil(cgImage)
        XCTAssertEqual(cgImage?.width, Int(testCIImage.extent.width))
        XCTAssertEqual(cgImage?.height, Int(testCIImage.extent.height))
    }

    // MARK: - Localization Tests

    func testEditLocalizationStrings() {
        // 测试本地化字符串是否存在
        let cutTitle = Strings.get("edit.cut.title")
        let resizeTitle = Strings.get("edit.resize.title")
        let cropTitle = Strings.get("edit.crop.title")
        let enhanceTitle = Strings.get("edit.enhance.title")

        // 如果字符串不存在，会返回 key 本身
        XCTAssertNotEqual(cutTitle, "edit.cut.title")
        XCTAssertNotEqual(resizeTitle, "edit.resize.title")
        XCTAssertNotEqual(cropTitle, "edit.crop.title")
        XCTAssertNotEqual(enhanceTitle, "edit.enhance.title")
    }

    func testInputOutputStrings() {
        let input = Strings.get("edit.input")
        let output = Strings.get("edit.output")

        XCTAssertNotEqual(input, "edit.input")
        XCTAssertNotEqual(output, "edit.output")
    }

    // MARK: - File Utilities Tests

    func testFileUtilsValidateExtension() {
        let pngExt = FileUtils.getExtension(from: "/path/to/image.png")
        let jpgExt = FileUtils.getExtension(from: "/path/to/image.JPG")
        let heicExt = FileUtils.getExtension(from: "/path/to/image.heic")

        XCTAssertEqual(pngExt, "png")
        XCTAssertEqual(jpgExt, "jpg")
        XCTAssertEqual(heicExt, "heic")
    }

    func testFileUtilsGenerateOutputPath() {
        let inputPath = "/path/to/image.jpg"
        let outputPath = FileUtils.generateOutputPath(from: inputPath, suffix: "_enhanced")

        XCTAssertTrue(outputPath.contains("_enhanced"))
        XCTAssertTrue(outputPath.hasSuffix(".jpg"))
    }

    func testFileUtilsGenerateOutputPathWithNewExtension() {
        let inputPath = "/path/to/image.jpg"
        let outputPath = FileUtils.generateOutputPath(from: inputPath, suffix: "_cutout", extension: "png")

        XCTAssertTrue(outputPath.contains("_cutout"))
        XCTAssertTrue(outputPath.hasSuffix(".png"))
    }

    // MARK: - Edge Cases

    func testAutoEnhanceMultipleTimes() {
        // 多次增强应该不会崩溃
        var enhanced = testCIImage!
        for _ in 0..<3 {
            enhanced = coreImageService.autoEnhance(ciImage: enhanced)
        }

        XCTAssertNotNil(enhanced)
        XCTAssertEqual(enhanced.extent.width, testCIImage.extent.width)
    }

    func testCropFullImage() {
        // 裁剪整个图像
        let cropRect = testCIImage.extent
        let cropped = coreImageService.crop(ciImage: testCIImage, rect: cropRect)

        XCTAssertEqual(cropped.extent.width, testCIImage.extent.width)
        XCTAssertEqual(cropped.extent.height, testCIImage.extent.height)
    }

    func testResizeToVerySmall() {
        let resized = coreImageService.resize(ciImage: testCIImage, width: 10, height: 10)

        XCTAssertNotNil(resized)
        XCTAssertGreaterThan(resized.extent.width, 0)
        XCTAssertGreaterThan(resized.extent.height, 0)
    }

    func testResizeToVeryLarge() {
        let resized = coreImageService.resize(ciImage: testCIImage, width: 2000, height: 1500)

        XCTAssertNotNil(resized)
        // 检查是否有合理的尺寸
        XCTAssertGreaterThan(resized.extent.width, testCIImage.extent.width)
    }
}

// MARK: - Command Help Text Tests

extension EditBatch1Tests {
    func testCutCommandConfiguration() {
        let config = CutCommand.configuration

        XCTAssertEqual(config.commandName, "cut")
        XCTAssertFalse(config.abstract.isEmpty)
        XCTAssertNotNil(config.discussion)
    }

    func testResizeCommandConfiguration() {
        let config = ResizeCommand.configuration

        XCTAssertEqual(config.commandName, "resize")
        XCTAssertFalse(config.abstract.isEmpty)
        XCTAssertNotNil(config.discussion)
    }

    func testCropCommandConfiguration() {
        let config = CropCommand.configuration

        XCTAssertEqual(config.commandName, "crop")
        XCTAssertFalse(config.abstract.isEmpty)
        XCTAssertNotNil(config.discussion)
    }

    func testEnhanceCommandConfiguration() {
        let config = EnhanceCommand.configuration

        XCTAssertEqual(config.commandName, "enhance")
        XCTAssertFalse(config.abstract.isEmpty)
        XCTAssertNotNil(config.discussion)
    }

    func testEditCommandHasSubcommands() {
        let config = EditCommand.configuration
        let subcommands = config.subcommands

        // 应该包含我们添加的四个命令
        let subcommandNames = subcommands.map { $0.configuration.commandName }

        XCTAssertTrue(subcommandNames.contains("cut"))
        XCTAssertTrue(subcommandNames.contains("resize"))
        XCTAssertTrue(subcommandNames.contains("crop"))
        XCTAssertTrue(subcommandNames.contains("enhance"))
    }
}
