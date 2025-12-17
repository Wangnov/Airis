import XCTest
#if !XCODE_BUILD
@testable import AirisCore
#endif

/// ImageUtils 测试
final class ImageUtilsTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("airis_imageutils_test_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    // MARK: - encodeImageToBase64 Tests

    /// 测试编码图片为 Base64
    func testEncodeImageToBase64() throws {
        let url = TestResources.image("assets/small_100x100.png")
        let result = try ImageUtils.encodeImageToBase64(at: url)

        XCTAssertFalse(result.data.isEmpty)
        XCTAssertEqual(result.mimeType, "image/png")
    }

    /// 测试编码不存在的文件
    func testEncodeImageToBase64NonExistent() throws {
        let url = URL(fileURLWithPath: "/nonexistent/image.png")

        XCTAssertThrowsError(try ImageUtils.encodeImageToBase64(at: url))
    }

    // MARK: - mimeTypeForImageFile Tests

    /// 测试 MIME 类型检测 - JPEG
    func testMimeTypeJPEG() throws {
        let urlJpg = URL(fileURLWithPath: "/path/to/image.jpg")
        let urlJpeg = URL(fileURLWithPath: "/path/to/image.jpeg")

        XCTAssertEqual(ImageUtils.mimeTypeForImageFile(at: urlJpg), "image/jpeg")
        XCTAssertEqual(ImageUtils.mimeTypeForImageFile(at: urlJpeg), "image/jpeg")
    }

    /// 测试 MIME 类型检测 - PNG
    func testMimeTypePNG() throws {
        let url = URL(fileURLWithPath: "/path/to/image.png")
        XCTAssertEqual(ImageUtils.mimeTypeForImageFile(at: url), "image/png")
    }

    /// 测试 MIME 类型检测 - HEIC
    func testMimeTypeHEIC() throws {
        let url = URL(fileURLWithPath: "/path/to/image.heic")
        XCTAssertEqual(ImageUtils.mimeTypeForImageFile(at: url), "image/heic")
    }

    /// 测试 MIME 类型检测 - HEIF
    func testMimeTypeHEIF() throws {
        let url = URL(fileURLWithPath: "/path/to/image.heif")
        XCTAssertEqual(ImageUtils.mimeTypeForImageFile(at: url), "image/heif")
    }

    /// 测试 MIME 类型检测 - WebP
    func testMimeTypeWebP() throws {
        let url = URL(fileURLWithPath: "/path/to/image.webp")
        XCTAssertEqual(ImageUtils.mimeTypeForImageFile(at: url), "image/webp")
    }

    /// 测试 MIME 类型检测 - GIF
    func testMimeTypeGIF() throws {
        let url = URL(fileURLWithPath: "/path/to/image.gif")
        XCTAssertEqual(ImageUtils.mimeTypeForImageFile(at: url), "image/gif")
    }

    /// 测试 MIME 类型检测 - 未知格式（默认 JPEG）
    func testMimeTypeUnknown() throws {
        let url = URL(fileURLWithPath: "/path/to/file.xyz")
        XCTAssertEqual(ImageUtils.mimeTypeForImageFile(at: url), "image/jpeg")
    }

    /// 测试大写扩展名
    func testMimeTypeUppercase() throws {
        let url = URL(fileURLWithPath: "/path/to/image.PNG")
        XCTAssertEqual(ImageUtils.mimeTypeForImageFile(at: url), "image/png")
    }

    // MARK: - decodeAndSaveImage Tests

    /// 测试解码并保存 Base64 图片
    func testDecodeAndSaveImage() throws {
        // 创建一个简单的 1x1 像素 PNG 图片的 Base64
        // 这是一个有效的 1x1 红色 PNG
        let pngBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg=="

        let outputPath = tempDirectory.appendingPathComponent("output.png").path

        try ImageUtils.decodeAndSaveImage(base64String: pngBase64, to: outputPath, format: "png")

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputPath))
    }

    /// 测试解码无效 Base64
    func testDecodeAndSaveImageInvalidBase64() throws {
        let invalidBase64 = "not-valid-base64!!!"
        let outputPath = tempDirectory.appendingPathComponent("output.png").path

        XCTAssertThrowsError(try ImageUtils.decodeAndSaveImage(base64String: invalidBase64, to: outputPath)) { error in
            guard case AirisError.imageDecodeFailed = error else {
                XCTFail("应该抛出 imageDecodeFailed 错误")
                return
            }
        }
    }

    /// 测试保存到需要创建的目录
    func testDecodeAndSaveImageNewDirectory() throws {
        let pngBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg=="
        let outputPath = tempDirectory.appendingPathComponent("new/nested/dir/output.png").path

        try ImageUtils.decodeAndSaveImage(base64String: pngBase64, to: outputPath, format: "png")

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputPath))
    }

    // MARK: - getImageDimensions Tests

    /// 测试获取图片尺寸
    func testGetImageDimensions() throws {
        let url = TestResources.image("assets/medium_512x512.jpg")
        let dimensions = try ImageUtils.getImageDimensions(at: url)

        XCTAssertEqual(dimensions.width, 512, "应读取到正确的宽度")
        XCTAssertEqual(dimensions.height, 512, "应读取到正确的高度")
    }

    /// 测试获取不存在图片的尺寸
    func testGetImageDimensionsNonExistent() throws {
        let url = URL(fileURLWithPath: "/nonexistent/image.png")

        XCTAssertThrowsError(try ImageUtils.getImageDimensions(at: url)) { error in
            guard case AirisError.imageDecodeFailed = error else {
                XCTFail("应该抛出 imageDecodeFailed 错误")
                return
            }
        }
    }

    /// 测试获取非图片文件的尺寸
    func testGetImageDimensionsNonImage() throws {
        // 创建一个文本文件
        let txtPath = tempDirectory.appendingPathComponent("test.txt")
        try "this is not an image".write(to: txtPath, atomically: true, encoding: .utf8)

        XCTAssertThrowsError(try ImageUtils.getImageDimensions(at: txtPath)) { error in
            guard case AirisError.imageDecodeFailed = error else {
                XCTFail("应该抛出 imageDecodeFailed 错误")
                return
            }
        }
    }
}
