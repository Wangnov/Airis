import XCTest
import CoreImage
#if !XCODE_BUILD
@testable import AirisCore
#endif

final class EditBatch2Tests: XCTestCase {
    var coreImageService: CoreImageService!
    var visionService: VisionService!
    var testCIImage: CIImage!

    override func setUp() {
        super.setUp()
        coreImageService = CoreImageService()
        visionService = VisionService()

        // 创建测试用 CIImage（200x150 蓝色方块）
        testCIImage = CIImage(color: .blue)
            .cropped(to: CGRect(x: 0, y: 0, width: 200, height: 150))
    }

    override func tearDown() {
        coreImageService = nil
        visionService = nil
        testCIImage = nil
        super.tearDown()
    }

    // MARK: - Perspective Correction Tests

    func testPerspectiveCorrectionReturnsImage() throws {
        // 测试透视校正能返回图像
        let corrected = coreImageService.perspectiveCorrection(
            ciImage: testCIImage,
            topLeft: CGPoint(x: 10, y: 140),
            topRight: CGPoint(x: 190, y: 140),
            bottomLeft: CGPoint(x: 0, y: 0),
            bottomRight: CGPoint(x: 200, y: 0)
        )

        XCTAssertNotNil(corrected)
        XCTAssertGreaterThan(corrected?.extent.width ?? 0, 0)
        XCTAssertGreaterThan(corrected?.extent.height ?? 0, 0)
    }

    func testPerspectiveCorrectionNormalized() throws {
        // 测试归一化坐标的透视校正
        let corrected = coreImageService.perspectiveCorrectionNormalized(
            ciImage: testCIImage,
            normalizedTopLeft: CGPoint(x: 0.05, y: 0.95),
            normalizedTopRight: CGPoint(x: 0.95, y: 0.95),
            normalizedBottomLeft: CGPoint(x: 0, y: 0),
            normalizedBottomRight: CGPoint(x: 1, y: 0)
        )

        XCTAssertNotNil(corrected)
    }

    // MARK: - Edge Detection Tests

    func testEdgeWorkReturnsImage() throws {
        let edges = coreImageService.edgeWork(ciImage: testCIImage, radius: 3.0)

        XCTAssertNotNil(edges)
        // 注意：CIEdgeWork 在 macOS 上可能返回与输入尺寸相同的图像
    }

    func testEdgesReturnsImage() throws {
        let edges = coreImageService.edges(ciImage: testCIImage, intensity: 1.0)

        XCTAssertNotNil(edges)
    }

    func testLineOverlayReturnsImage() throws {
        let overlay = coreImageService.lineOverlay(
            ciImage: testCIImage,
            edgeIntensity: 1.0
        )

        XCTAssertNotNil(overlay)
    }

    // MARK: - Defringe Tests

    func testDefringeReturnsImage() throws {
        let defringed = coreImageService.defringe(ciImage: testCIImage, amount: 0.5)

        XCTAssertNotNil(defringed)
        XCTAssertEqual(defringed.extent.width, testCIImage.extent.width)
        XCTAssertEqual(defringed.extent.height, testCIImage.extent.height)
    }

    func testDefringeWithZeroAmount() throws {
        let defringed = coreImageService.defringe(ciImage: testCIImage, amount: 0)

        XCTAssertNotNil(defringed)
        // 0 强度应该基本不改变图像
    }

    func testDefringeWithFullAmount() throws {
        let defringed = coreImageService.defringe(ciImage: testCIImage, amount: 1.0)

        XCTAssertNotNil(defringed)
    }

    // MARK: - Rotation Tests

    func testRotateAroundCenter() throws {
        let rotated = coreImageService.rotateAroundCenter(ciImage: testCIImage, degrees: 45)

        XCTAssertNotNil(rotated)
        // 旋转后图像尺寸会变大（对角线方向扩展）
        XCTAssertGreaterThan(rotated.extent.width, testCIImage.extent.width * 0.9)
        XCTAssertGreaterThan(rotated.extent.height, testCIImage.extent.height * 0.9)
    }

    func testRotate90Degrees() throws {
        let rotated = coreImageService.rotateAroundCenter(ciImage: testCIImage, degrees: 90)

        XCTAssertNotNil(rotated)
        // 90度旋转后宽高互换（近似）
        XCTAssertEqual(Int(rotated.extent.width), 150, accuracy: 2)
        XCTAssertEqual(Int(rotated.extent.height), 200, accuracy: 2)
    }

    func testRotateZeroDegrees() throws {
        let rotated = coreImageService.rotateAroundCenter(ciImage: testCIImage, degrees: 0)

        XCTAssertNotNil(rotated)
        XCTAssertEqual(Int(rotated.extent.width), Int(testCIImage.extent.width))
        XCTAssertEqual(Int(rotated.extent.height), Int(testCIImage.extent.height))
    }

    // MARK: - Command Configuration Tests

    func testScanCommandConfiguration() throws {
        let config = ScanCommand.configuration

        XCTAssertEqual(config.commandName, "scan")
        XCTAssertFalse(config.abstract.isEmpty)
        XCTAssertNotNil(config.discussion)
    }

    func testStraightenCommandConfiguration() throws {
        let config = StraightenCommand.configuration

        XCTAssertEqual(config.commandName, "straighten")
        XCTAssertFalse(config.abstract.isEmpty)
        XCTAssertNotNil(config.discussion)
    }

    func testTraceCommandConfiguration() throws {
        let config = TraceCommand.configuration

        XCTAssertEqual(config.commandName, "trace")
        XCTAssertFalse(config.abstract.isEmpty)
        XCTAssertNotNil(config.discussion)
    }

    func testDefringeCommandConfiguration() throws {
        let config = DefringeCommand.configuration

        XCTAssertEqual(config.commandName, "defringe")
        XCTAssertFalse(config.abstract.isEmpty)
        XCTAssertNotNil(config.discussion)
    }

    func testFormatCommandConfiguration() throws {
        let config = FormatCommand.configuration

        XCTAssertEqual(config.commandName, "fmt")
        XCTAssertFalse(config.abstract.isEmpty)
        XCTAssertNotNil(config.discussion)
    }

    func testThumbCommandConfiguration() throws {
        let config = ThumbCommand.configuration

        XCTAssertEqual(config.commandName, "thumb")
        XCTAssertFalse(config.abstract.isEmpty)
        XCTAssertNotNil(config.discussion)
    }

    // MARK: - EditCommand Subcommands Test

    func testEditCommandHasAllBatch2Subcommands() throws {
        let config = EditCommand.configuration
        let subcommands = config.subcommands

        let subcommandNames = subcommands.map { $0.configuration.commandName }

        // Task 6.3 的新命令
        XCTAssertTrue(subcommandNames.contains("scan"))
        XCTAssertTrue(subcommandNames.contains("straighten"))
        XCTAssertTrue(subcommandNames.contains("trace"))
        XCTAssertTrue(subcommandNames.contains("defringe"))
        XCTAssertTrue(subcommandNames.contains("fmt"))
        XCTAssertTrue(subcommandNames.contains("thumb"))

        // Task 6.2 的命令应该也存在
        XCTAssertTrue(subcommandNames.contains("cut"))
        XCTAssertTrue(subcommandNames.contains("resize"))
        XCTAssertTrue(subcommandNames.contains("crop"))
        XCTAssertTrue(subcommandNames.contains("enhance"))
    }

    // MARK: - Localization Tests

    func testBatch2LocalizationStrings() throws {
        // 测试本地化字符串是否存在
        let scanTitle = Strings.get("edit.scan.title")
        let straightenTitle = Strings.get("edit.straighten.title")
        let traceTitle = Strings.get("edit.trace.title")
        let defringeTitle = Strings.get("edit.defringe.title")
        let fmtTitle = Strings.get("edit.fmt.title")
        let thumbTitle = Strings.get("edit.thumb.title")

        // 如果字符串不存在，会返回 key 本身
        XCTAssertNotEqual(scanTitle, "edit.scan.title")
        XCTAssertNotEqual(straightenTitle, "edit.straighten.title")
        XCTAssertNotEqual(traceTitle, "edit.trace.title")
        XCTAssertNotEqual(defringeTitle, "edit.defringe.title")
        XCTAssertNotEqual(fmtTitle, "edit.fmt.title")
        XCTAssertNotEqual(thumbTitle, "edit.thumb.title")
    }

    // MARK: - VisionService Rectangle Detection Tests

    func testRectangleObservationStructure() throws {
        // 测试 RectangleObservation 结构体
        let observation = VisionService.RectangleObservation(
            topLeft: CGPoint(x: 0.1, y: 0.9),
            topRight: CGPoint(x: 0.9, y: 0.9),
            bottomLeft: CGPoint(x: 0, y: 0),
            bottomRight: CGPoint(x: 1, y: 0),
            confidence: 0.95,
            boundingBox: CGRect(x: 0, y: 0, width: 1, height: 1)
        )

        XCTAssertEqual(observation.topLeft.x, 0.1, accuracy: 0.001)
        XCTAssertEqual(observation.confidence, 0.95, accuracy: 0.001)
    }

    func testHorizonObservationStructure() throws {
        // 测试 HorizonObservation 结构体
        let observation = VisionService.HorizonObservation(
            angleInRadians: 0.1,
            angleInDegrees: 5.73,
            confidence: 0.9
        )

        XCTAssertEqual(observation.angleInRadians, 0.1, accuracy: 0.001)
        XCTAssertEqual(observation.angleInDegrees, 5.73, accuracy: 0.01)
        XCTAssertEqual(observation.confidence, 0.9, accuracy: 0.001)
    }

    // MARK: - Edge Cases

    func testEdgeWorkWithSmallRadius() throws {
        let edges = coreImageService.edgeWork(ciImage: testCIImage, radius: 1.0)
        XCTAssertNotNil(edges)
    }

    func testEdgeWorkWithLargeRadius() throws {
        let edges = coreImageService.edgeWork(ciImage: testCIImage, radius: 10.0)
        XCTAssertNotNil(edges)
    }

    func testEdgesWithLowIntensity() throws {
        let edges = coreImageService.edges(ciImage: testCIImage, intensity: 0.1)
        XCTAssertNotNil(edges)
    }

    func testEdgesWithHighIntensity() throws {
        let edges = coreImageService.edges(ciImage: testCIImage, intensity: 5.0)
        XCTAssertNotNil(edges)
    }

    // MARK: - Service Container Tests

    func testServicesFromContainer() throws {
        let coreImage = ServiceContainer.shared.coreImageService
        let vision = ServiceContainer.shared.visionService
        let imageIO = ServiceContainer.shared.imageIOService

        XCTAssertNotNil(coreImage)
        XCTAssertNotNil(vision)
        XCTAssertNotNil(imageIO)
    }

    // MARK: - File Utils Tests for Format Command

    func testSupportedImageFormats() throws {
        XCTAssertTrue(FileUtils.isSupportedImageFormat("/path/to/image.jpg"))
        XCTAssertTrue(FileUtils.isSupportedImageFormat("/path/to/image.jpeg"))
        XCTAssertTrue(FileUtils.isSupportedImageFormat("/path/to/image.png"))
        XCTAssertTrue(FileUtils.isSupportedImageFormat("/path/to/image.heic"))
        XCTAssertTrue(FileUtils.isSupportedImageFormat("/path/to/image.tiff"))
        XCTAssertTrue(FileUtils.isSupportedImageFormat("/path/to/image.tif"))
    }

    func testUnsupportedImageFormat() throws {
        XCTAssertFalse(FileUtils.isSupportedImageFormat("/path/to/file.txt"))
        XCTAssertFalse(FileUtils.isSupportedImageFormat("/path/to/file.pdf"))
    }
}
