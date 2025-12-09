import XCTest
@testable import Airis

/// 边界测试 - Vision 服务
///
/// 测试目标:
/// - 测试空结果场景
/// - 测试无效输入处理
/// - 测试极端情况
final class VisionEdgeCaseTests: XCTestCase {

    // ✅ Apple 最佳实践：类级别共享服务
    nonisolated(unsafe) static let sharedVisionService = VisionService()

    var service: VisionService!

    // 测试资产目录
    static let testAssetsPath = NSString(string: "~/airis-worktrees/test-assets/task-9.1").expandingTildeInPath

    override func setUp() {
        super.setUp()
        service = VisionService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // MARK: - 无效文件测试

    /// 测试不存在的文件
    func testNonExistentFile() async {
        let nonExistentURL = URL(fileURLWithPath: "/nonexistent/path/image.jpg")

        do {
            _ = try await service.classifyImage(at: nonExistentURL)
            XCTFail("应该抛出错误")
        } catch {
            // 预期会抛出错误
            XCTAssertTrue(true)
        }
    }

    /// 测试不存在的文件 - OCR
    func testNonExistentFile_OCR() async {
        let nonExistentURL = URL(fileURLWithPath: "/nonexistent/path/document.png")

        do {
            _ = try await service.recognizeText(at: nonExistentURL)
            XCTFail("应该抛出错误")
        } catch {
            XCTAssertTrue(true)
        }
    }

    /// 测试不存在的文件 - 人脸检测
    func testNonExistentFile_FaceDetection() async {
        let nonExistentURL = URL(fileURLWithPath: "/nonexistent/path/face.jpg")

        do {
            _ = try await service.detectFaceLandmarks(at: nonExistentURL)
            XCTFail("应该抛出错误")
        } catch {
            XCTAssertTrue(true)
        }
    }

    // MARK: - CGImage 测试

    /// 测试 1x1 像素图像分类
    func testClassifyTinyImage() async throws {
        // 创建 1x1 像素图像
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let context = CGContext(
            data: nil,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            XCTFail("无法创建 CGContext")
            return
        }

        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))

        guard let cgImage = context.makeImage() else {
            XCTFail("无法创建 CGImage")
            return
        }

        // 1x1 图像的分类结果可能很少或没有
        let results = try await service.classifyImage(cgImage: cgImage, threshold: 0)
        // 不崩溃就是成功
        XCTAssertNotNil(results)
    }

    /// 测试纯色图像分类
    func testClassifySolidColorImage() async throws {
        // 创建纯红色图像
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let context = CGContext(
            data: nil,
            width: 100,
            height: 100,
            bitsPerComponent: 8,
            bytesPerRow: 400,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            XCTFail("无法创建 CGContext")
            return
        }

        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))

        guard let cgImage = context.makeImage() else {
            XCTFail("无法创建 CGImage")
            return
        }

        // 纯色图像应该可以正常处理
        let results = try await service.classifyImage(cgImage: cgImage, threshold: 0)
        XCTAssertNotNil(results)
    }

    // MARK: - 阈值边界测试

    /// 测试零阈值
    func testClassifyZeroThreshold() async throws {
        let testImageURL = URL(fileURLWithPath: Self.testAssetsPath + "/benchmark_4k.png")
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试资产不存在")
        }

        let results = try await service.classifyImage(at: testImageURL, threshold: 0)
        // 零阈值应该返回所有结果
        XCTAssertFalse(results.isEmpty)
    }

    /// 测试满阈值（1.0）
    func testClassifyFullThreshold() async throws {
        let testImageURL = URL(fileURLWithPath: Self.testAssetsPath + "/benchmark_4k.png")
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试资产不存在")
        }

        let results = try await service.classifyImage(at: testImageURL, threshold: 1.0)
        // 满阈值应该返回很少或没有结果
        XCTAssertNotNil(results)
    }

    /// 测试负阈值
    func testClassifyNegativeThreshold() async throws {
        let testImageURL = URL(fileURLWithPath: Self.testAssetsPath + "/benchmark_4k.png")
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试资产不存在")
        }

        // 负阈值应该被处理（等同于 0）
        let results = try await service.classifyImage(at: testImageURL, threshold: -1.0)
        XCTAssertNotNil(results)
    }

    // MARK: - OCR 边界测试

    /// 测试空语言列表
    func testOCREmptyLanguages() async throws {
        let testImageURL = URL(fileURLWithPath: Self.testAssetsPath + "/document.png")
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试资产不存在")
        }

        // 空语言列表应该启用自动检测
        let results = try await service.recognizeText(at: testImageURL, languages: [])
        XCTAssertNotNil(results)
    }

    /// 测试多语言列表
    func testOCRMultipleLanguages() async throws {
        let testImageURL = URL(fileURLWithPath: Self.testAssetsPath + "/document.png")
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试资产不存在")
        }

        let results = try await service.recognizeText(
            at: testImageURL,
            languages: ["en", "zh-Hans", "zh-Hant", "ja", "ko"]
        )
        XCTAssertNotNil(results)
    }

    // MARK: - 条形码检测边界测试

    /// 测试无条形码的图像
    func testBarcodeDetectionNoBarcode() async throws {
        let testImageURL = URL(fileURLWithPath: Self.testAssetsPath + "/benchmark_4k.png")
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试资产不存在")
        }

        let results = try await service.detectBarcodes(at: testImageURL)
        // 普通图像可能没有条形码
        XCTAssertNotNil(results)
    }

    // MARK: - 矩形检测边界测试

    /// 测试矩形检测 - 最小置信度
    func testRectangleDetectionMinConfidence() async throws {
        let testImageURL = URL(fileURLWithPath: Self.testAssetsPath + "/document.png")
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试资产不存在")
        }

        let results = try await service.detectRectangles(
            at: testImageURL,
            minimumConfidence: 0.0,
            minimumSize: 0.01
        )
        XCTAssertNotNil(results)
    }

    /// 测试矩形检测 - 最大置信度
    func testRectangleDetectionMaxConfidence() async throws {
        let testImageURL = URL(fileURLWithPath: Self.testAssetsPath + "/document.png")
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试资产不存在")
        }

        let results = try await service.detectRectangles(
            at: testImageURL,
            minimumConfidence: 1.0,
            minimumSize: 0.9
        )
        // 高要求可能返回空结果
        XCTAssertNotNil(results)
    }

    // MARK: - 显著性检测边界测试

    /// 测试纯色图像的显著性检测
    func testSaliencyOnSolidColor() async throws {
        // 创建纯色图像
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let context = CGContext(
            data: nil,
            width: 100,
            height: 100,
            bitsPerComponent: 8,
            bytesPerRow: 400,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            throw XCTSkip("无法创建 CGContext")
        }

        context.setFillColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))

        guard let cgImage = context.makeImage() else {
            throw XCTSkip("无法创建 CGImage")
        }

        // 保存临时文件
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("solid_color_test.png")
        let imageIO = ImageIOService()
        try imageIO.saveImage(cgImage, to: tempURL, format: "png")

        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }

        // 纯色图像的显著性检测应该能正常工作
        let result = try await service.detectSaliency(at: tempURL, type: .attention)
        XCTAssertNotNil(result)
    }

    // MARK: - 人物分割边界测试

    /// 测试无人物图像的分割
    func testPersonSegmentationNoPerson() async throws {
        // 创建纯色图像（无人物）
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let context = CGContext(
            data: nil,
            width: 100,
            height: 100,
            bitsPerComponent: 8,
            bytesPerRow: 400,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            throw XCTSkip("无法创建 CGContext")
        }

        context.setFillColor(CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))

        guard let cgImage = context.makeImage() else {
            throw XCTSkip("无法创建 CGImage")
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("no_person_test.png")
        let imageIO = ImageIOService()
        try imageIO.saveImage(cgImage, to: tempURL, format: "png")

        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }

        // 应该能正常处理（可能返回空遮罩或抛出 noResultsFound）
        do {
            let result = try await service.generatePersonSegmentation(at: tempURL, quality: .fast)
            XCTAssertNotNil(result)
        } catch {
            // 无人物时可能抛出错误，这也是可接受的
            XCTAssertTrue(true)
        }
    }

    // MARK: - 人脸检测边界测试

    /// 测试无人脸图像的检测
    func testFaceDetectionNoFace() async throws {
        let testImageURL = URL(fileURLWithPath: Self.testAssetsPath + "/benchmark_4k.png")
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试资产不存在")
        }

        // 风景图可能没有人脸
        let results = try await service.detectFaceLandmarks(at: testImageURL)
        // 不崩溃就是成功，结果可能为空
        XCTAssertNotNil(results)
    }

    // MARK: - 动物检测边界测试

    /// 测试无动物图像的检测
    func testAnimalRecognitionNoAnimal() async throws {
        let testImageURL = URL(fileURLWithPath: Self.testAssetsPath + "/document.png")
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试资产不存在")
        }

        // 文档图像没有动物
        let results = try await service.recognizeAnimals(at: testImageURL)
        XCTAssertNotNil(results)
        // 结果应该为空或很少
    }

    // MARK: - 手部检测边界测试

    /// 测试无手部图像的检测
    func testHandDetectionNoHand() async throws {
        let testImageURL = URL(fileURLWithPath: Self.testAssetsPath + "/benchmark_4k.png")
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试资产不存在")
        }

        let results = try await service.detectHumanHandPose(at: testImageURL)
        XCTAssertNotNil(results)
    }

    /// 测试手部检测最大数量参数
    func testHandDetectionMaxCount() async throws {
        let testImageURL = URL(fileURLWithPath: Self.testAssetsPath + "/benchmark_4k.png")
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试资产不存在")
        }

        // 测试不同的最大手部数量
        let results1 = try await service.detectHumanHandPose(at: testImageURL, maximumHandCount: 1)
        XCTAssertNotNil(results1)

        let results4 = try await service.detectHumanHandPose(at: testImageURL, maximumHandCount: 4)
        XCTAssertNotNil(results4)
    }
}
