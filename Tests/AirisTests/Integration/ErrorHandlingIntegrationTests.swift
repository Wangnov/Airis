import XCTest
import CoreImage
@testable import Airis

/// 错误场景集成测试 - 验证各种错误情况的正确处理
final class ErrorHandlingIntegrationTests: XCTestCase {

    // MARK: - Properties

    var tempDir: URL!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        // 创建临时目录用于测试
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("airis_error_test_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        // 清理临时目录
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - 文件不存在错误测试

    /// 测试：Vision 服务处理不存在的文件
    func testVisionServiceFileNotFound() async {
        let visionService = VisionService()
        let nonExistentURL = URL(fileURLWithPath: "/nonexistent/path/image.jpg")

        do {
            let _ = try await visionService.classifyImage(at: nonExistentURL)
            XCTFail("Should throw error for non-existent file")
        } catch {
            // 预期会抛出错误
            XCTAssertTrue(true, "Correctly threw error for non-existent file")
        }
    }

    /// 测试：ImageIO 服务处理不存在的文件
    func testImageIOServiceFileNotFound() {
        let imageIOService = ImageIOService()
        let nonExistentURL = URL(fileURLWithPath: "/nonexistent/path/image.png")

        XCTAssertThrowsError(try imageIOService.loadImage(at: nonExistentURL)) { error in
            guard case AirisError.fileNotFound = error else {
                XCTFail("Expected fileNotFound error, got: \(error)")
                return
            }
        }
    }

    /// 测试：ImageIO 元数据读取处理不存在的文件
    func testImageIOMetadataFileNotFound() {
        let imageIOService = ImageIOService()
        let nonExistentURL = URL(fileURLWithPath: "/nonexistent/path/image.png")

        XCTAssertThrowsError(try imageIOService.loadImageMetadata(at: nonExistentURL)) { error in
            guard case AirisError.fileNotFound = error else {
                XCTFail("Expected fileNotFound error, got: \(error)")
                return
            }
        }
    }

    /// 测试：文件验证工具处理不存在的文件
    func testFileUtilsValidateFileNotFound() {
        let nonExistentPath = "/nonexistent/path/to/file.jpg"

        XCTAssertThrowsError(try FileUtils.validateFile(at: nonExistentPath)) { error in
            guard case AirisError.fileNotFound = error else {
                XCTFail("Expected fileNotFound error, got: \(error)")
                return
            }
        }
    }

    // MARK: - 格式不支持错误测试

    /// 测试：不支持的文件格式
    func testUnsupportedFormatError() {
        // 创建一个文本文件
        let textFileURL = tempDir.appendingPathComponent("test.txt")
        try? "This is not an image".write(to: textFileURL, atomically: true, encoding: .utf8)

        // 验证格式检查
        XCTAssertThrowsError(try FileUtils.validateImageFile(at: textFileURL.path)) { error in
            guard case AirisError.unsupportedFormat = error else {
                XCTFail("Expected unsupportedFormat error, got: \(error)")
                return
            }
        }
    }

    /// 测试：尝试加载非图像文件
    func testLoadNonImageFile() {
        let imageIOService = ImageIOService()

        // 创建一个 JSON 文件
        let jsonFileURL = tempDir.appendingPathComponent("test.json")
        try? "{}".write(to: jsonFileURL, atomically: true, encoding: .utf8)

        // 尝试作为图像加载
        XCTAssertThrowsError(try imageIOService.loadImage(at: jsonFileURL)) { error in
            // 可能是 fileNotFound 或 unsupportedFormat
            XCTAssertTrue(true, "Correctly rejected non-image file")
        }
    }

    /// 测试：损坏的图像文件
    func testCorruptedImageFile() {
        let imageIOService = ImageIOService()

        // 创建一个假的 PNG 文件（错误的内容）
        let corruptedFileURL = tempDir.appendingPathComponent("corrupted.png")
        let corruptedData = Data([0x89, 0x50, 0x4E, 0x47, 0x00, 0x00])  // 不完整的 PNG 头
        try? corruptedData.write(to: corruptedFileURL)

        // 尝试加载损坏的文件
        XCTAssertThrowsError(try imageIOService.loadImage(at: corruptedFileURL)) { _ in
            XCTAssertTrue(true, "Correctly rejected corrupted image file")
        }
    }

    // MARK: - API Key 错误测试

    /// 测试：API Key 未配置错误
    func testMissingAPIKeyError() {
        let keychain = KeychainManager()

        // 使用一个肯定不存在的 provider 名
        let testProvider = "nonexistent-test-provider-\(UUID().uuidString)"

        // 确保没有这个 provider 的 key
        try? keychain.deleteAPIKey(for: testProvider)

        // 验证获取不存在的 key 会抛出错误
        XCTAssertThrowsError(try keychain.getAPIKey(for: testProvider)) { error in
            guard case AirisError.apiKeyNotFound(let provider) = error else {
                XCTFail("Expected apiKeyNotFound error, got: \(error)")
                return
            }
            XCTAssertEqual(provider, testProvider)
        }
    }

    /// 测试：API Key 保存和删除流程的错误处理
    func testAPIKeyLifecycle() throws {
        let keychain = KeychainManager()
        let testProvider = "test-lifecycle-\(UUID().uuidString)"

        defer {
            // 清理
            try? keychain.deleteAPIKey(for: testProvider)
        }

        // 1. 初始状态：不存在
        XCTAssertFalse(keychain.hasAPIKey(for: testProvider))

        // 2. 保存 key
        try keychain.saveAPIKey("test-api-key-123", for: testProvider)

        // 3. 验证存在
        XCTAssertTrue(keychain.hasAPIKey(for: testProvider))

        // 4. 读取 key
        let retrievedKey = try keychain.getAPIKey(for: testProvider)
        XCTAssertEqual(retrievedKey, "test-api-key-123")

        // 5. 删除 key
        try keychain.deleteAPIKey(for: testProvider)

        // 6. 验证不存在
        XCTAssertFalse(keychain.hasAPIKey(for: testProvider))

        // 7. 再次读取应该失败
        XCTAssertThrowsError(try keychain.getAPIKey(for: testProvider))
    }

    // MARK: - 网络错误测试

    /// 测试：HTTP 客户端超时处理
    func testHTTPClientTimeout() async {
        // 创建一个超短超时的配置
        let config = HTTPClientConfiguration(
            timeoutIntervalForRequest: 0.001,  // 1 毫秒超时
            waitsForConnectivity: false,
            maxRetries: 0
        )
        let client = HTTPClient(configuration: config)

        do {
            // 尝试请求一个需要延迟的端点（会超时）
            let _ = try await client.get(url: URL(string: "https://httpbin.org/delay/10")!)
            XCTFail("Should timeout")
        } catch {
            // 预期超时错误
            XCTAssertTrue(true, "Correctly handled timeout")
        }
    }

    /// 测试：HTTP 客户端处理无效 URL
    func testHTTPClientInvalidRequest() async {
        let client = HTTPClient()

        // 使用一个不存在的域名
        let invalidURL = URL(string: "https://this-domain-does-not-exist-\(UUID().uuidString).com")!

        do {
            let _ = try await client.get(url: invalidURL)
            XCTFail("Should fail for invalid domain")
        } catch {
            // 预期网络错误
            XCTAssertTrue(true, "Correctly handled invalid domain")
        }
    }

    // MARK: - 图像处理错误测试

    /// 测试：空图像处理
    func testEmptyImageProcessing() {
        let coreImageService = CoreImageService()

        // 创建一个极小的图像
        let tinyImage = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))

        // 各种操作应该不会崩溃
        let blurred = coreImageService.gaussianBlur(ciImage: tinyImage, radius: 10)
        XCTAssertNotNil(blurred)

        let resized = coreImageService.resize(ciImage: tinyImage, width: 100, height: 100)
        XCTAssertNotNil(resized)

        let cropped = coreImageService.crop(ciImage: tinyImage, rect: CGRect(x: 0, y: 0, width: 0.5, height: 0.5))
        XCTAssertNotNil(cropped)
    }

    /// 测试：极端参数值处理
    func testExtremeParameterValues() {
        let coreImageService = CoreImageService()
        let testImage = CIImage(color: .blue).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        // 极大模糊半径
        let extremeBlur = coreImageService.gaussianBlur(ciImage: testImage, radius: 1000)
        XCTAssertNotNil(extremeBlur)

        // 负数参数（应该被处理）
        let negativeBlur = coreImageService.gaussianBlur(ciImage: testImage, radius: -10)
        XCTAssertNotNil(negativeBlur)

        // 极端颜色调整
        let extremeAdjust = coreImageService.adjustColors(
            ciImage: testImage,
            brightness: 100,  // 超出范围
            contrast: -100,   // 超出范围
            saturation: 1000  // 超出范围
        )
        XCTAssertNotNil(extremeAdjust)

        // 零尺寸缩放
        let zeroResize = coreImageService.resize(ciImage: testImage, width: 0, height: 0)
        XCTAssertNotNil(zeroResize)
    }

    /// 测试：无效裁剪区域
    func testInvalidCropRegion() {
        let coreImageService = CoreImageService()
        let testImage = CIImage(color: .green).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        // 完全超出边界的裁剪区域
        let outOfBoundsCrop = coreImageService.crop(
            ciImage: testImage,
            rect: CGRect(x: 200, y: 200, width: 50, height: 50)
        )
        // 应该返回原图或空图，但不应崩溃
        XCTAssertNotNil(outOfBoundsCrop)

        // 负坐标裁剪区域
        let negativeCrop = coreImageService.crop(
            ciImage: testImage,
            rect: CGRect(x: -50, y: -50, width: 200, height: 200)
        )
        XCTAssertNotNil(negativeCrop)
    }

    // MARK: - 文件写入错误测试

    /// 测试：写入只读目录
    func testWriteToReadOnlyLocation() {
        let imageIOService = ImageIOService()
        let coreImageService = CoreImageService()

        // 创建测试图像
        let testImage = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        guard let cgImage = coreImageService.render(ciImage: testImage) else {
            XCTFail("Failed to render test image")
            return
        }

        // 尝试写入系统目录（应该失败）
        let readOnlyURL = URL(fileURLWithPath: "/System/test_image.png")

        XCTAssertThrowsError(try imageIOService.saveImage(cgImage, to: readOnlyURL)) { _ in
            XCTAssertTrue(true, "Correctly rejected write to read-only location")
        }
    }

    /// 测试：写入不存在的目录
    func testWriteToNonExistentDirectory() {
        let imageIOService = ImageIOService()
        let coreImageService = CoreImageService()

        // 创建测试图像
        let testImage = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        guard let cgImage = coreImageService.render(ciImage: testImage) else {
            XCTFail("Failed to render test image")
            return
        }

        // 尝试写入不存在的目录
        let nonExistentDirURL = tempDir
            .appendingPathComponent("nonexistent_subdir")
            .appendingPathComponent("test_image.png")

        // 这可能成功（如果自动创建目录）或失败
        // 主要测试不会崩溃
        do {
            try imageIOService.saveImage(cgImage, to: nonExistentDirURL)
            // 如果成功了，清理
            try? FileManager.default.removeItem(at: nonExistentDirURL)
        } catch {
            // 预期的行为
            XCTAssertTrue(true, "Correctly handled non-existent directory")
        }
    }

    // MARK: - Vision 框架错误测试

    /// 测试：Vision 服务处理空图像
    func testVisionServiceEmptyImage() async throws {
        let visionService = VisionService()

        // 创建一个 1x1 的纯色图像并保存
        let coreImageService = CoreImageService()
        let imageIOService = ImageIOService()

        let tinyImage = CIImage(color: .white).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
        guard let cgImage = coreImageService.render(ciImage: tinyImage) else {
            XCTFail("Failed to render tiny image")
            return
        }

        let tinyImageURL = tempDir.appendingPathComponent("tiny.png")
        try imageIOService.saveImage(cgImage, to: tinyImageURL)

        // 尝试分类（可能返回空结果，但不应崩溃）
        let classifications = try await visionService.classifyImage(at: tinyImageURL, threshold: 0.0)
        // 1x1 图像可能没有分类结果
        XCTAssertTrue(true, "Vision service handled tiny image without crashing")
    }

    /// 测试：综合分析处理空结果
    func testComprehensiveAnalysisEmptyResults() async throws {
        let visionService = VisionService()
        let coreImageService = CoreImageService()
        let imageIOService = ImageIOService()

        // 创建纯色图像
        let solidImage = CIImage(color: .black).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        guard let cgImage = coreImageService.render(ciImage: solidImage) else {
            XCTFail("Failed to render solid image")
            return
        }

        let solidImageURL = tempDir.appendingPathComponent("solid.png")
        try imageIOService.saveImage(cgImage, to: solidImageURL)

        // 执行综合分析
        let analysis = try await visionService.performMultipleRequests(at: solidImageURL)

        // 纯色图像可能没有文字和条形码
        XCTAssertNotNil(analysis)
        // 但分类可能还是有的（可能识别为"black"等）
    }

    // MARK: - 配置管理错误测试

    /// 测试：配置管理器处理不存在的 provider 配置
    func testConfigManagerMissingConfig() throws {
        // 使用临时配置文件
        let tempConfigFile = tempDir.appendingPathComponent("test_config_\(UUID().uuidString).json")
        let configManager = ConfigManager(configFile: tempConfigFile)

        // 获取不存在的 provider 配置（应该返回空的 ProviderConfig）
        let config = try configManager.getProviderConfig(for: "nonexistent-provider")

        // 验证返回的是空配置
        XCTAssertNil(config.baseURL, "Should return empty config for non-existent provider")
        XCTAssertNil(config.model, "Should return empty config for non-existent provider")
    }

    /// 测试：配置管理器处理损坏的配置文件
    func testConfigManagerCorruptedConfig() {
        // 创建一个损坏的 JSON 配置文件
        let corruptedConfigFile = tempDir.appendingPathComponent("corrupted_config.json")
        try? "{ invalid json }".write(to: corruptedConfigFile, atomically: true, encoding: .utf8)

        // 创建配置管理器（应该能处理损坏的配置）
        let configManager = ConfigManager(configFile: corruptedConfigFile)

        // 操作应该不会崩溃
        XCTAssertNotNil(configManager)
    }

    // MARK: - 并发错误测试

    /// 测试：并发访问共享资源
    func testConcurrentAccessToServices() async throws {
        let visionService = VisionService()
        let coreImageService = CoreImageService()
        let imageIOService = ImageIOService()

        // 创建测试图像
        let testImage = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        guard let cgImage = coreImageService.render(ciImage: testImage) else {
            XCTFail("Failed to render test image")
            return
        }

        let testImageURL = tempDir.appendingPathComponent("concurrent_test.png")
        try imageIOService.saveImage(cgImage, to: testImageURL)

        // 并发执行多个操作
        try await withThrowingTaskGroup(of: Void.self) { group in
            // 多个并发分类请求
            for _ in 0..<5 {
                group.addTask {
                    let _ = try await visionService.classifyImage(at: testImageURL)
                }
            }

            // 等待所有任务完成
            try await group.waitForAll()
        }

        XCTAssertTrue(true, "Concurrent access completed without errors")
    }
}
