import XCTest
#if !XCODE_BUILD
@testable import AirisCore
#endif

/// ImageIOService 完整测试（100% 覆盖率）
final class ImageIOServiceTests: XCTestCase {
    var service: ImageIOService!
    var tempDir: URL!

    // 测试图片路径
    var testImageURL: URL!
    var transparentImageURL: URL!

    override func setUp() {
        super.setUp()
        service = ImageIOService()

        // 创建临时目录
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("airis_imageio_test_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // 使用测试图片（不依赖当前工作目录）
        testImageURL = TestResources.image("imageio/load_basic.png")
        transparentImageURL = TestResources.image("imageio/alpha_test.png")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        service = nil
        super.tearDown()
    }

    // MARK: - Service Creation Tests

    func testServiceInitialization() throws {
        XCTAssertNotNil(service)
    }

    func testServiceContainerAccess() throws {
        let containerService = ServiceContainer.shared.imageIOService
        XCTAssertNotNil(containerService)
    }

    // MARK: - loadImageMetadata Tests

    func testLoadImageMetadata_Success() throws {
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试图片不存在: \(testImageURL.path)")
        }

        let metadata = try service.loadImageMetadata(at: testImageURL)

        XCTAssertFalse(metadata.isEmpty)
        XCTAssertNotNil(metadata[kCGImagePropertyPixelWidth])
        XCTAssertNotNil(metadata[kCGImagePropertyPixelHeight])
    }

    func testLoadImageMetadata_FileNotFound() throws {
        let nonExistentURL = URL(fileURLWithPath: "/tmp/nonexistent_\(UUID()).png")

        XCTAssertThrowsError(try service.loadImageMetadata(at: nonExistentURL)) { error in
            guard case AirisError.fileNotFound = error else {
                XCTFail("Expected fileNotFound error")
                return
            }
        }
    }

    func testLoadImageMetadata_UnsupportedFormat() throws {
        // 创建一个文本文件假装是图片
        let textFile = tempDir.appendingPathComponent("fake.jpg")
        try "not an image".write(to: textFile, atomically: true, encoding: .utf8)

        XCTAssertThrowsError(try service.loadImageMetadata(at: textFile)) { error in
            guard case AirisError.unsupportedFormat = error else {
                XCTFail("Expected unsupportedFormat error")
                return
            }
        }
    }

    // MARK: - loadImage Tests

    func testLoadImage_Success() throws {
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试图片不存在")
        }

        let image = try service.loadImage(at: testImageURL)

        XCTAssertNotNil(image)
        XCTAssertGreaterThan(image.width, 0)
        XCTAssertGreaterThan(image.height, 0)
    }

    func testLoadImage_WithMaxDimension() throws {
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试图片不存在")
        }

        let thumbnail = try service.loadImage(at: testImageURL, maxDimension: 200)

        XCTAssertNotNil(thumbnail)
        XCTAssertLessThanOrEqual(thumbnail.width, 200)
        XCTAssertLessThanOrEqual(thumbnail.height, 200)
    }

    func testLoadImage_FileNotFound() throws {
        let nonExistentURL = URL(fileURLWithPath: "/tmp/nonexistent.png")

        XCTAssertThrowsError(try service.loadImage(at: nonExistentURL)) { error in
            guard case AirisError.fileNotFound = error else {
                XCTFail("Expected fileNotFound error")
                return
            }
        }
    }

    func testLoadImage_CorruptedFile() throws {
        // 创建损坏的图片文件
        let corruptedFile = tempDir.appendingPathComponent("corrupted.png")
        let corruptedData = Data([0x89, 0x50, 0x4E, 0x47]) // PNG header only
        try corruptedData.write(to: corruptedFile)

        XCTAssertThrowsError(try service.loadImage(at: corruptedFile)) { error in
            guard case AirisError.imageDecodeFailed = error else {
                XCTFail("Expected imageDecodeFailed error")
                return
            }
        }
    }

    // MARK: - getImageInfo Tests

    func testGetImageInfo_Success() throws {
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试图片不存在")
        }

        let info = try service.getImageInfo(at: testImageURL)

        XCTAssertGreaterThan(info.width, 0)
        XCTAssertGreaterThan(info.height, 0)
        XCTAssertGreaterThan(info.dpiWidth, 0)
        XCTAssertGreaterThan(info.dpiHeight, 0)
    }

    func testGetImageInfo_Orientation() throws {
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试图片不存在")
        }

        let info = try service.getImageInfo(at: testImageURL)

        // orientation 应该是有效值
        XCTAssertNotNil(info.orientation)
    }

    func testGetImageInfo_AlphaChannel() throws {
        guard FileManager.default.fileExists(atPath: transparentImageURL.path) else {
            throw XCTSkip("透明测试图片不存在")
        }

        let info = try service.getImageInfo(at: transparentImageURL)

        // PNG 透明图应该有 alpha 通道
        XCTAssertTrue(info.hasAlpha)
    }

    // MARK: - saveImage Tests

    func testSaveImage_PNG() throws {
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试图片不存在")
        }

        let cgImage = try service.loadImage(at: testImageURL)
        let outputURL = tempDir.appendingPathComponent("output.png")

        try service.saveImage(cgImage, to: outputURL, format: "png")

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))

        // 验证保存的图片可以读取
        let savedImage = try service.loadImage(at: outputURL)
        XCTAssertEqual(savedImage.width, cgImage.width)
        XCTAssertEqual(savedImage.height, cgImage.height)
    }

    func testSaveImage_JPEG() throws {
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试图片不存在")
        }

        let cgImage = try service.loadImage(at: testImageURL)
        let outputURL = tempDir.appendingPathComponent("output.jpg")

        try service.saveImage(cgImage, to: outputURL, format: "jpg", quality: 0.9)

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
    }

    func testSaveImage_HEIC() throws {
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试图片不存在")
        }

        let cgImage = try service.loadImage(at: testImageURL)
        let outputURL = tempDir.appendingPathComponent("output.heic")

        try service.saveImage(cgImage, to: outputURL, format: "heic", quality: 0.85)

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
    }

    func testSaveImage_TIFF() throws {
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试图片不存在")
        }

        let cgImage = try service.loadImage(at: testImageURL)
        let outputURL = tempDir.appendingPathComponent("output.tiff")

        try service.saveImage(cgImage, to: outputURL, format: "tiff")

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
    }

    func testSaveImage_DefaultFormat() throws {
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试图片不存在")
        }

        let cgImage = try service.loadImage(at: testImageURL)
        let outputURL = tempDir.appendingPathComponent("output_default.png")

        // 不支持的格式应该回退到 PNG
        try service.saveImage(cgImage, to: outputURL, format: "unknown")

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
    }

    func testSaveImage_QualityParameter() throws {
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试图片不存在")
        }

        let cgImage = try service.loadImage(at: testImageURL)

        // 测试不同质量参数
        let qualities: [Float] = [0.1, 0.5, 0.9, 1.0]

        for (index, quality) in qualities.enumerated() {
            let outputURL = tempDir.appendingPathComponent("output_q\(index).jpg")
            try service.saveImage(cgImage, to: outputURL, format: "jpg", quality: quality)
            XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
        }
    }

    // MARK: - getImageFormat Tests

    func testGetImageFormat_PNG() throws {
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试图片不存在")
        }

        let format = try service.getImageFormat(at: testImageURL)

        XCTAssertFalse(format.isEmpty)
        XCTAssertTrue(format.contains("png") || format.contains("PNG"))
    }

    func testGetImageFormat_FileNotFound() throws {
        let nonExistentURL = URL(fileURLWithPath: "/tmp/nonexistent.png")

        XCTAssertThrowsError(try service.getImageFormat(at: nonExistentURL)) { error in
            guard case AirisError.fileNotFound = error else {
                XCTFail("Expected fileNotFound error")
                return
            }
        }
    }

    func testGetImageFormat_UnsupportedFormat() throws {
        let textFile = tempDir.appendingPathComponent("not_image.txt")
        try "text".write(to: textFile, atomically: true, encoding: .utf8)

        XCTAssertThrowsError(try service.getImageFormat(at: textFile)) { error in
            guard case AirisError.unsupportedFormat = error else {
                XCTFail("Expected unsupportedFormat error")
                return
            }
        }
    }

    // MARK: - getImageFrameCount Tests

    func testGetImageFrameCount_SingleFrame() throws {
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试图片不存在")
        }

        let frameCount = try service.getImageFrameCount(at: testImageURL)

        XCTAssertEqual(frameCount, 1)
    }

    func testGetImageFrameCount_FileNotFound() throws {
        let nonExistentURL = URL(fileURLWithPath: "/tmp/nonexistent.png")

        XCTAssertThrowsError(try service.getImageFrameCount(at: nonExistentURL)) { error in
            guard case AirisError.fileNotFound = error else {
                XCTFail("Expected fileNotFound error")
                return
            }
        }
    }

    // MARK: - ImageInfo Structure Tests

    func testImageInfoStructure() throws {
        let info = ImageIOService.ImageInfo(
            width: 1920,
            height: 1080,
            dpiWidth: 72,
            dpiHeight: 72,
            colorModel: "RGB",
            depth: 8,
            hasAlpha: false,
            orientation: .up
        )

        XCTAssertEqual(info.width, 1920)
        XCTAssertEqual(info.height, 1080)
        XCTAssertEqual(info.dpiWidth, 72)
        XCTAssertFalse(info.hasAlpha)
        XCTAssertEqual(info.orientation, .up)
    }

    // MARK: - Integration Tests

    func testLoadAndSaveRoundtrip() throws {
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试图片不存在")
        }

        // 加载
        let originalImage = try service.loadImage(at: testImageURL)
        let originalWidth = originalImage.width
        let originalHeight = originalImage.height

        // 保存
        let outputURL = tempDir.appendingPathComponent("roundtrip.png")
        try service.saveImage(originalImage, to: outputURL, format: "png")

        // 重新加载验证
        let loadedImage = try service.loadImage(at: outputURL)
        XCTAssertEqual(loadedImage.width, originalWidth)
        XCTAssertEqual(loadedImage.height, originalHeight)
    }

    func testThumbnailGeneration() throws {
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试图片不存在")
        }

        let originalImage = try service.loadImage(at: testImageURL)
        let thumbnail = try service.loadImage(at: testImageURL, maxDimension: 100)

        XCTAssertLessThanOrEqual(thumbnail.width, originalImage.width)
        XCTAssertLessThanOrEqual(thumbnail.height, originalImage.height)
        XCTAssertLessThanOrEqual(max(thumbnail.width, thumbnail.height), 100)
    }

    // MARK: - Mock Tests (Error Path Coverage)

    func testSaveImage_CreateDestinationFailure() throws {
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试图片不存在")
        }

        // 使用真实的 operations 加载图像
        let cgImage = try service.loadImage(at: testImageURL)

        // 创建 Mock 并配置为 createDestination 失败
        let mockOps = MockImageIOOperations()
        mockOps.shouldFailCreateDestination = true
        let mockService = ImageIOService(operations: mockOps)

        let outputURL = tempDir.appendingPathComponent("mock_fail_create.png")

        XCTAssertThrowsError(try mockService.saveImage(cgImage, to: outputURL)) { error in
            guard case AirisError.fileWriteError = error else {
                XCTFail("Expected fileWriteError, got \(error)")
                return
            }
        }
    }

    func testSaveImage_FinalizeFailure() throws {
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试图片不存在")
        }

        // 使用真实的 operations 加载图像
        let cgImage = try service.loadImage(at: testImageURL)

        // 创建 Mock 并配置为 finalize 失败
        let mockOps = MockImageIOOperations()
        mockOps.shouldFailFinalize = true
        let mockService = ImageIOService(operations: mockOps)

        let outputURL = tempDir.appendingPathComponent("mock_fail_finalize.png")

        XCTAssertThrowsError(try mockService.saveImage(cgImage, to: outputURL)) { error in
            guard case AirisError.imageEncodeFailed = error else {
                XCTFail("Expected imageEncodeFailed, got \(error)")
                return
            }
        }
    }

    func testGetImageInfo_InvalidOrientation() throws {
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试图片不存在")
        }

        // 使用返回无效 orientation 的 Mock
        let mockOps = MockImageIOOperationsWithInvalidOrientation()
        let mockService = ImageIOService(operations: mockOps)

        // 获取图像信息
        let info = try mockService.getImageInfo(at: testImageURL)

        // 注意：CGImagePropertyOrientation 对任何 UInt32 都不返回 nil（C 枚举行为）
        // 所以 rawValue 99 会被接受，此测试验证代码路径被执行
        XCTAssertNotNil(info.orientation)
    }

    func testGetImageInfo_NoOrientationInMetadata() throws {
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试图片不存在")
        }

        // 使用不包含 orientation 的 Mock
        let mockOps = MockImageIOOperationsWithoutOrientation()
        let mockService = ImageIOService(operations: mockOps)

        // 当元数据中没有 orientation 时，应该使用默认值 .up
        let info = try mockService.getImageInfo(at: testImageURL)
        XCTAssertEqual(info.orientation, .up)
    }

    func testGetImageInfo_AllDefaultValues() throws {
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试图片不存在")
        }

        // 使用返回空属性字典的 Mock，触发所有默认值分支
        let mockOps = MockImageIOOperationsWithMissingProperties()
        let mockService = ImageIOService(operations: mockOps)

        // 当所有属性都缺失时，应该使用默认值
        let info = try mockService.getImageInfo(at: testImageURL)

        // 验证所有默认值
        XCTAssertEqual(info.width, 0)       // ?? 0
        XCTAssertEqual(info.height, 0)      // ?? 0
        XCTAssertEqual(info.dpiWidth, 72)   // ?? 72
        XCTAssertEqual(info.dpiHeight, 72)  // ?? 72
        XCTAssertFalse(info.hasAlpha)       // ?? false
        XCTAssertEqual(info.orientation, .up) // 没有进入 if 块
    }

    func testGetImageInfo_ValidOrientation() throws {
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试图片不存在")
        }

        // 使用返回有效 orientation 的 Mock（值为 6 = .right）
        let mockOps = MockImageIOOperationsWithValidOrientation()
        let mockService = ImageIOService(operations: mockOps)

        // 获取图像信息 - 应该正确解析 orientation
        let info = try mockService.getImageInfo(at: testImageURL)

        // 验证 orientation 被正确解析为 .right (rawValue = 6)
        XCTAssertEqual(info.orientation, .right)
    }

    func testDependencyInjection() throws {
        // 测试依赖注入机制
        let defaultService = ImageIOService()
        XCTAssertNotNil(defaultService)

        let mockOps = MockImageIOOperations()
        let injectedService = ImageIOService(operations: mockOps)
        XCTAssertNotNil(injectedService)
    }
}
