import XCTest
@testable import Airis

final class FileUtilsTests: XCTestCase {

    // MARK: - Extension Tests

    func testGetExtension() {
        XCTAssertEqual(FileUtils.getExtension(from: "/path/to/image.jpg"), "jpg")
        XCTAssertEqual(FileUtils.getExtension(from: "/path/to/image.PNG"), "png")
        XCTAssertEqual(FileUtils.getExtension(from: "/path/to/image.HEIC"), "heic")
        XCTAssertEqual(FileUtils.getExtension(from: "file.txt"), "txt")
    }

    // MARK: - Format Validation Tests

    func testIsSupportedImageFormat() {
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

    func testGenerateOutputPath() {
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

    func testExpandPath() {
        // 波浪号应被展开
        let expanded = FileUtils.expandPath("~/Documents")
        XCTAssertFalse(expanded.hasPrefix("~"))
        XCTAssertTrue(expanded.hasPrefix("/"))
    }

    func testAbsolutePath() {
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

    func testValidateFileNotFound() {
        let nonExistentPath = "/nonexistent/path/to/file.jpg"
        XCTAssertThrowsError(try FileUtils.validateFile(at: nonExistentPath)) { error in
            guard case AirisError.fileNotFound = error else {
                XCTFail("Expected fileNotFound error")
                return
            }
        }
    }

    func testValidateImageFileUnsupportedFormat() {
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
}
