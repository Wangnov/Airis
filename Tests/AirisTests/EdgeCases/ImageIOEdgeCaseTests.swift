import XCTest
@testable import Airis

/// 边界测试 - ImageIO 服务
///
/// 测试目标:
/// - 测试无效文件处理
/// - 测试格式边界
/// - 测试保存边界条件
final class ImageIOEdgeCaseTests: XCTestCase {

    // ✅ Apple 最佳实践：类级别共享服务
    static let sharedImageIOService = ImageIOService()

    var service: ImageIOService!
    var tempDirectory: URL!

    override func setUp() async throws {
        try await super.setUp()
        service = Self.sharedImageIOService

        // 创建临时目录
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("airis_edge_test_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDirectory)
        service = nil
        try await super.tearDown()
    }

    // MARK: - 无效文件测试

    /// 测试加载不存在的文件
    func testLoadNonExistentFile() throws {
        let nonExistentURL = URL(fileURLWithPath: "/nonexistent/path/image.png")

        XCTAssertThrowsError(try service.loadImage(at: nonExistentURL)) { error in
            guard case AirisError.fileNotFound = error else {
                XCTFail("应该抛出 fileNotFound 错误")
                return
            }
        }
    }

    /// 测试加载非图像文件
    func testLoadNonImageFile() throws {
        // 创建一个文本文件
        let textFileURL = tempDirectory.appendingPathComponent("test.txt")
        try "This is not an image".write(to: textFileURL, atomically: true, encoding: .utf8)

        // 尝试作为图像加载
        XCTAssertThrowsError(try service.loadImage(at: textFileURL)) { error in
            // 应该抛出某种错误
            XCTAssertNotNil(error)
        }
    }

    /// 测试读取不存在文件的元数据
    func testLoadMetadataNonExistent() throws {
        let nonExistentURL = URL(fileURLWithPath: "/nonexistent/path/image.png")

        XCTAssertThrowsError(try service.loadImageMetadata(at: nonExistentURL)) { error in
            guard case AirisError.fileNotFound = error else {
                XCTFail("应该抛出 fileNotFound 错误")
                return
            }
        }
    }

    // MARK: - 缩略图边界测试

    /// 测试零尺寸缩略图 - 应返回原图
    func testLoadThumbnailZeroSize() throws {
        let testImageURL = TestResources.image("assets/small_100x100.png")

        // 零尺寸应该返回原图尺寸（系统行为）
        let image = try service.loadImage(at: testImageURL, maxDimension: 0)
        XCTAssertEqual(image.width, 100, "零尺寸应返回原图尺寸")
        XCTAssertEqual(image.height, 100, "零尺寸应返回原图尺寸")
    }

    /// 测试负尺寸缩略图 - 应返回原图或被系统处理
    func testLoadThumbnailNegativeSize() throws {
        let testImageURL = TestResources.image("assets/small_100x100.png")

        // 负尺寸应该被系统 API 处理（行为由 ImageIO 决定）
        let image = try service.loadImage(at: testImageURL, maxDimension: -100)
        XCTAssertNotNil(image)
        XCTAssertGreaterThan(image.width, 0)
    }

    /// 测试极大缩略图尺寸 - 不应超过原图
    func testLoadThumbnailHugeSize() throws {
        let testImageURL = TestResources.image("assets/small_100x100.png")

        // 比原图大的尺寸 - 系统不会放大，最多返回原图
        let image = try service.loadImage(at: testImageURL, maxDimension: 100000)
        XCTAssertLessThanOrEqual(image.width, 100, "不应超过原图尺寸")
        XCTAssertLessThanOrEqual(image.height, 100, "不应超过原图尺寸")
    }

    // MARK: - 保存边界测试

    /// 测试保存到无效路径
    func testSaveToInvalidPath() throws {
        let testImageURL = TestResources.image("assets/small_100x100.png")

        let cgImage = try service.loadImage(at: testImageURL)
        let invalidPath = URL(fileURLWithPath: "/nonexistent/directory/output.png")

        XCTAssertThrowsError(try service.saveImage(cgImage, to: invalidPath)) { error in
            // 应该抛出写入错误
            XCTAssertNotNil(error)
        }
    }

    /// 测试保存使用未知格式 - 应回退到 PNG
    func testSaveUnknownFormat() throws {
        let testImageURL = TestResources.image("assets/small_100x100.png")

        let cgImage = try service.loadImage(at: testImageURL)
        let outputPath = tempDirectory.appendingPathComponent("output.xyz")

        // 未知格式应该回退到 PNG
        try service.saveImage(cgImage, to: outputPath, format: "xyz")
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputPath.path))

        // 验证实际格式为 PNG（返回 UTType identifier）
        let actualFormat = try service.getImageFormat(at: outputPath)
        XCTAssertTrue(actualFormat.contains("png"), "未知格式应回退到 PNG，实际为: \(actualFormat)")
    }

    /// 测试保存使用极端质量值 - 验证系统容错
    func testSaveExtremeQuality() throws {
        let testImageURL = TestResources.image("assets/small_100x100.png")

        let cgImage = try service.loadImage(at: testImageURL)

        // 质量为 0（最低质量，最小文件）
        let zeroQualityPath = tempDirectory.appendingPathComponent("zero_quality.jpg")
        try service.saveImage(cgImage, to: zeroQualityPath, format: "jpg", quality: 0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: zeroQualityPath.path))

        // 质量为 1.0（最高质量，最大文件）
        let highQualityPath = tempDirectory.appendingPathComponent("high_quality.jpg")
        try service.saveImage(cgImage, to: highQualityPath, format: "jpg", quality: 1.0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: highQualityPath.path))

        // 验证文件大小关系：低质量 < 高质量
        let zeroSize = try XCTUnwrap(FileUtils.getFileSize(at: zeroQualityPath.path))
        let highSize = try XCTUnwrap(FileUtils.getFileSize(at: highQualityPath.path))
        XCTAssertLessThan(zeroSize, highSize, "低质量文件应小于高质量文件")

        // 质量超过 1.0（应被限制为 1.0）
        let overQualityPath = tempDirectory.appendingPathComponent("over_quality.jpg")
        try service.saveImage(cgImage, to: overQualityPath, format: "jpg", quality: 2.0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: overQualityPath.path))

        // 负质量值（应被系统处理）
        let negativeQualityPath = tempDirectory.appendingPathComponent("negative_quality.jpg")
        try service.saveImage(cgImage, to: negativeQualityPath, format: "jpg", quality: -1.0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: negativeQualityPath.path))
    }

    // MARK: - 格式检测边界测试

    /// 测试获取不存在文件的格式
    func testGetFormatNonExistent() throws {
        let nonExistentURL = URL(fileURLWithPath: "/nonexistent/path/image.png")

        XCTAssertThrowsError(try service.getImageFormat(at: nonExistentURL)) { error in
            guard case AirisError.fileNotFound = error else {
                XCTFail("应该抛出 fileNotFound 错误")
                return
            }
        }
    }

    /// 测试获取非图像文件的格式
    func testGetFormatNonImage() throws {
        let textFileURL = tempDirectory.appendingPathComponent("test.txt")
        try "This is not an image".write(to: textFileURL, atomically: true, encoding: .utf8)

        XCTAssertThrowsError(try service.getImageFormat(at: textFileURL)) { error in
            XCTAssertNotNil(error)
        }
    }

    // MARK: - 帧数检测边界测试

    /// 测试获取不存在文件的帧数
    func testGetFrameCountNonExistent() throws {
        let nonExistentURL = URL(fileURLWithPath: "/nonexistent/path/image.gif")

        XCTAssertThrowsError(try service.getImageFrameCount(at: nonExistentURL)) { error in
            guard case AirisError.fileNotFound = error else {
                XCTFail("应该抛出 fileNotFound 错误")
                return
            }
        }
    }

    /// 测试单帧图像的帧数
    func testGetFrameCountSingleFrame() throws {
        let testImageURL = TestResources.image("assets/medium_512x512.jpg")
        let frameCount = try service.getImageFrameCount(at: testImageURL)
        XCTAssertEqual(frameCount, 1, "单帧 JPEG 应返回帧数 1")
    }

    // MARK: - 图像信息边界测试

    /// 测试获取不存在文件的信息
    func testGetImageInfoNonExistent() throws {
        let nonExistentURL = URL(fileURLWithPath: "/nonexistent/path/image.png")

        XCTAssertThrowsError(try service.getImageInfo(at: nonExistentURL)) { error in
            guard case AirisError.fileNotFound = error else {
                XCTFail("应该抛出 fileNotFound 错误")
                return
            }
        }
    }

    /// 测试获取图像信息 - 验证属性
    func testGetImageInfoValidProperties() throws {
        let testImageURL = TestResources.image("assets/medium_512x512.jpg")
        let info = try service.getImageInfo(at: testImageURL)
        XCTAssertEqual(info.width, 512, "应读取到正确的宽度")
        XCTAssertEqual(info.height, 512, "应读取到正确的高度")
        XCTAssertGreaterThan(info.dpiWidth, 0, "DPI 应为正数")
        XCTAssertGreaterThan(info.dpiHeight, 0, "DPI 应为正数")
    }
}
