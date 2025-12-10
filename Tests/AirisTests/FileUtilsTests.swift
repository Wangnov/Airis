import XCTest
@testable import Airis

final class FileUtilsTests: XCTestCase {

    var tempDirectory: URL!

    // 内置测试资源路径
    static let resourcePath = "Tests/Resources/images"

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("airis_fileutils_test_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    // MARK: - Extension Tests

    func testGetExtension() throws {
        XCTAssertEqual(FileUtils.getExtension(from: "/path/to/image.jpg"), "jpg")
        XCTAssertEqual(FileUtils.getExtension(from: "/path/to/image.PNG"), "png")
        XCTAssertEqual(FileUtils.getExtension(from: "/path/to/image.HEIC"), "heic")
        XCTAssertEqual(FileUtils.getExtension(from: "file.txt"), "txt")
        XCTAssertEqual(FileUtils.getExtension(from: "/path/to/file"), "")
    }

    // MARK: - Format Validation Tests

    func testIsSupportedImageFormat() throws {
        XCTAssertTrue(FileUtils.isSupportedImageFormat("/path/to/image.jpg"))
        XCTAssertTrue(FileUtils.isSupportedImageFormat("/path/to/image.jpeg"))
        XCTAssertTrue(FileUtils.isSupportedImageFormat("/path/to/image.png"))
        XCTAssertTrue(FileUtils.isSupportedImageFormat("/path/to/image.heic"))
        XCTAssertTrue(FileUtils.isSupportedImageFormat("/path/to/image.webp"))
        XCTAssertTrue(FileUtils.isSupportedImageFormat("/path/to/image.TIFF"))

        XCTAssertFalse(FileUtils.isSupportedImageFormat("/path/to/file.txt"))
        XCTAssertFalse(FileUtils.isSupportedImageFormat("/path/to/file.pdf"))
        XCTAssertFalse(FileUtils.isSupportedImageFormat("/path/to/file.mp4"))
    }

    // MARK: - Output Path Generation Tests

    func testGenerateOutputPath() throws {
        let input = "/Users/test/images/photo.jpg"

        // 默认后缀
        let output1 = FileUtils.generateOutputPath(from: input)
        XCTAssertEqual(output1, "/Users/test/images/photo_output.jpg")

        // 自定义后缀
        let output2 = FileUtils.generateOutputPath(from: input, suffix: "_enhanced")
        XCTAssertEqual(output2, "/Users/test/images/photo_enhanced.jpg")

        // 自定义扩展名
        let output3 = FileUtils.generateOutputPath(from: input, suffix: "_converted", extension: "png")
        XCTAssertEqual(output3, "/Users/test/images/photo_converted.png")
    }

    // MARK: - Path Expansion Tests

    func testExpandPath() throws {
        // 波浪号应被展开
        let expanded = FileUtils.expandPath("~/Documents")
        XCTAssertFalse(expanded.hasPrefix("~"))
        XCTAssertTrue(expanded.hasPrefix("/"))
    }

    func testAbsolutePath() throws {
        // 绝对路径保持不变
        let absPath = "/Users/test/file.jpg"
        XCTAssertEqual(FileUtils.absolutePath(absPath), absPath)

        // 相对路径应转为绝对路径
        let relPath = "file.jpg"
        let result = FileUtils.absolutePath(relPath)
        XCTAssertTrue(result.hasPrefix("/"))
        XCTAssertTrue(result.hasSuffix("/file.jpg"))
    }

    // MARK: - File Validation Tests

    func testValidateFileNotFound() throws {
        let nonExistentPath = "/nonexistent/path/to/file.jpg"
        XCTAssertThrowsError(try FileUtils.validateFile(at: nonExistentPath)) { error in
            guard case AirisError.fileNotFound = error else {
                XCTFail("Expected fileNotFound error")
                return
            }
        }
    }

    func testValidateImageFileUnsupportedFormat() throws {
        // 创建临时文件
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("test.txt")
        try? "test".write(to: tempFile, atomically: true, encoding: .utf8)

        defer {
            try? FileManager.default.removeItem(at: tempFile)
        }

        XCTAssertThrowsError(try FileUtils.validateImageFile(at: tempFile.path)) { error in
            guard case AirisError.unsupportedFormat = error else {
                XCTFail("Expected unsupportedFormat error")
                return
            }
        }
    }

    // MARK: - ensureDirectory Tests

    /// 测试确保目录存在 - 已存在的目录
    func testEnsureExistingDirectory() throws {
        let filePath = tempDirectory.appendingPathComponent("test.png").path
        try FileUtils.ensureDirectory(for: filePath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDirectory.path))
    }

    /// 测试确保目录存在 - 创建新目录
    func testEnsureNewDirectory() throws {
        let newDir = tempDirectory.appendingPathComponent("new/nested/dir")
        let filePath = newDir.appendingPathComponent("test.png").path

        try FileUtils.ensureDirectory(for: filePath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: newDir.path))
    }

    // MARK: - getFormattedFileSize Tests

    /// 测试获取格式化文件大小
    func testGetFormattedFileSize() throws {
        let testImagePath = Self.resourcePath + "/assets/medium_512x512.jpg"
        guard FileManager.default.fileExists(atPath: testImagePath) else {
            throw XCTSkip("测试资产不存在: \(testImagePath)")
        }

        let formattedSize = FileUtils.getFormattedFileSize(at: testImagePath)
        XCTAssertNotNil(formattedSize, "应返回格式化的文件大小")
    }

    /// 测试获取不存在文件的大小
    func testGetFormattedFileSizeNonExistent() throws {
        let size = FileUtils.getFormattedFileSize(at: "/nonexistent/file.png")
        XCTAssertNil(size)
    }

    // MARK: - getFileSize Tests

    /// 测试获取文件大小（字节）
    func testGetFileSize() throws {
        let testImagePath = Self.resourcePath + "/assets/medium_512x512.jpg"
        guard FileManager.default.fileExists(atPath: testImagePath) else {
            throw XCTSkip("测试资产不存在: \(testImagePath)")
        }

        let size = FileUtils.getFileSize(at: testImagePath)
        XCTAssertNotNil(size)
        XCTAssertGreaterThan(try XCTUnwrap(size), 0, "文件大小应大于 0")
    }

    /// 测试获取不存在文件的大小
    func testGetFileSizeNonExistent() throws {
        let size = FileUtils.getFileSize(at: "/nonexistent/file.png")
        XCTAssertNil(size)
    }

    // MARK: - validateFile Tests

    /// 测试验证存在的文件
    func testValidateExistingFile() throws {
        let testImagePath = Self.resourcePath + "/assets/medium_512x512.jpg"
        guard FileManager.default.fileExists(atPath: testImagePath) else {
            throw XCTSkip("测试资产不存在: \(testImagePath)")
        }

        let url = try FileUtils.validateFile(at: testImagePath)
        XCTAssertTrue(url.path.hasSuffix(testImagePath), "应返回正确的文件路径")
    }

    // MARK: - validateImageFile Tests

    /// 测试验证存在的图像文件
    func testValidateExistingImageFile() throws {
        let testImagePath = Self.resourcePath + "/assets/medium_512x512.jpg"
        guard FileManager.default.fileExists(atPath: testImagePath) else {
            throw XCTSkip("测试资产不存在: \(testImagePath)")
        }

        let url = try FileUtils.validateImageFile(at: testImagePath)
        XCTAssertTrue(url.path.hasSuffix(testImagePath), "应返回正确的文件路径")
    }

    // MARK: - supportedImageFormats Tests

    /// 测试支持的格式列表
    func testSupportedImageFormats() throws {
        let formats = FileUtils.supportedImageFormats

        XCTAssertTrue(formats.contains("jpg"))
        XCTAssertTrue(formats.contains("jpeg"))
        XCTAssertTrue(formats.contains("png"))
        XCTAssertTrue(formats.contains("heic"))
        XCTAssertTrue(formats.contains("gif"))
        XCTAssertTrue(formats.contains("bmp"))
        XCTAssertFalse(formats.contains("txt"))
    }
}
