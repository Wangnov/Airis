import XCTest
import Vision
#if !XCODE_BUILD
@testable import AirisCore
#endif

/// 边界测试 - Vision 服务
///
/// 测试目标:
/// - 测试空结果场景
/// - 测试无效输入处理
/// - 测试极端情况
/// - 测试正向检测能力
final class VisionEdgeCaseTests: XCTestCase {

    // ✅ Apple 最佳实践：类级别共享服务
    static let sharedVisionService = VisionService()

    var service: VisionService!

    override func setUp() {
        super.setUp()
        service = Self.sharedVisionService
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // MARK: - 无效文件测试

    /// 测试不存在的文件
    func testNonExistentFile() async throws {
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
    func testNonExistentFile_OCR() async throws {
        let nonExistentURL = URL(fileURLWithPath: "/nonexistent/path/document.png")

        do {
            _ = try await service.recognizeText(at: nonExistentURL)
            XCTFail("应该抛出错误")
        } catch {
            XCTAssertTrue(true)
        }
    }

    /// 测试不存在的文件 - 人脸检测
    func testNonExistentFile_FaceDetection() async throws {
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

    /// 测试零阈值 - 应返回所有分类结果
    func testClassifyZeroThreshold() async throws {
        let testImageURL = TestResources.image("vision/classify.jpg")

        let results = try await service.classifyImage(at: testImageURL, threshold: 0)
        // 零阈值应该返回所有结果
        XCTAssertFalse(results.isEmpty, "零阈值应返回分类结果")
    }

    /// 测试满阈值（1.0）- 应返回空或极少结果
    func testClassifyFullThreshold() async throws {
        let testImageURL = TestResources.image("vision/classify.jpg")

        let results = try await service.classifyImage(at: testImageURL, threshold: 1.0)
        // 满阈值应该返回空结果（置信度几乎不可能达到 1.0）
        XCTAssertTrue(results.isEmpty, "阈值 1.0 应返回空结果")
    }

    /// 测试负阈值 - 应等同于阈值 0
    func testClassifyNegativeThreshold() async throws {
        let testImageURL = TestResources.image("vision/classify.jpg")

        // 负阈值应该被处理（等同于 0）
        let results = try await service.classifyImage(at: testImageURL, threshold: -1.0)
        XCTAssertFalse(results.isEmpty, "负阈值应等同于阈值 0，返回结果")
    }

    // MARK: - OCR 测试

    /// 测试 OCR 空语言列表 - 应启用自动检测
    func testOCREmptyLanguages() async throws {
        let documentURL = TestResources.image("vision/document.png")

        // 空语言列表应该启用自动检测
        let results = try await service.recognizeText(at: documentURL, languages: [])
        // 文档图片应该识别出文字
        XCTAssertFalse(results.isEmpty, "应识别出文字")
    }

    /// 测试 OCR 多语言列表
    func testOCRMultipleLanguages() async throws {
        let documentURL = TestResources.image("vision/document.png")

        let results = try await service.recognizeText(
            at: documentURL,
            languages: ["en", "zh-Hans", "zh-Hant", "ja", "ko"]
        )
        // 文档图片应该识别出文字
        XCTAssertFalse(results.isEmpty, "多语言模式应识别出文字")
    }

    // MARK: - 条形码/QR 码检测测试

    /// 测试 QR 码检测 - 应检测到条形码
    func testBarcodeDetectionWithQRCode() async throws {
        let qrcodeURL = TestResources.image("vision/qrcode.png")

        let results = try await service.detectBarcodes(at: qrcodeURL)
        // QR 码图片应该检测到条形码
        XCTAssertFalse(results.isEmpty, "应检测到 QR 码")

        // 验证是 QR 类型
        if let firstBarcode = results.first {
            XCTAssertEqual(firstBarcode.symbology, .qr, "应识别为 QR 码类型")
        }
    }

    /// 测试无条形码图像 - 应返回空结果
    func testBarcodeDetectionNoBarcode() async throws {
        let testImageURL = TestResources.image("vision/classify.jpg")
        let results = try await service.detectBarcodes(at: testImageURL)
        // 普通风景图没有条形码
        XCTAssertTrue(results.isEmpty, "无条形码图片应返回空结果")
    }

    // MARK: - 矩形检测测试

    /// 测试矩形检测 - 最小置信度
    func testRectangleDetectionMinConfidence() async throws {
        let rectangleURL = TestResources.image("assets/rectangle_512x512.png")
        let results = try await service.detectRectangles(
            at: rectangleURL,
            minimumConfidence: 0.0,
            minimumSize: 0.01
        )
        // 矩形/文档图片应检测到矩形
        XCTAssertFalse(results.isEmpty, "应检测到矩形")
    }

    /// 测试矩形检测 - 最大置信度（极端边界）
    func testRectangleDetectionMaxConfidence() async throws {
        let rectangleURL = TestResources.image("assets/rectangle_512x512.png")
        let results = try await service.detectRectangles(
            at: rectangleURL,
            minimumConfidence: 1.0,
            minimumSize: 0.9
        )
        // 极高要求可能返回空结果
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

    // MARK: - 人脸检测测试

    /// 测试人脸检测 - 有人脸图片应检测到人脸
    func testFaceDetectionWithFace() async throws {
        let faceURL = TestResources.image("vision/face.png")
        let results = try await service.detectFaceLandmarks(at: faceURL)
        // 人脸图片应检测到人脸
        XCTAssertFalse(results.isEmpty, "应检测到人脸")
    }

    /// 测试无人脸图像的检测 - 应返回空结果
    func testFaceDetectionNoFace() async throws {
        let testImageURL = TestResources.image("vision/classify.jpg")
        // 风景图没有人脸
        let results = try await service.detectFaceLandmarks(at: testImageURL)
        XCTAssertTrue(results.isEmpty, "风景图应检测不到人脸")
    }

    // MARK: - 动物检测测试

    /// 测试动物识别 - 有动物图片应识别到动物
    func testAnimalRecognitionWithAnimal() async throws {
        let catURL = TestResources.image("vision/cat.png")
        let results = try await service.recognizeAnimals(at: catURL)
        // 猫图片应识别到动物
        XCTAssertFalse(results.isEmpty, "应识别到动物")

        // 验证识别到的是动物（VNRecognizedObjectObservation 的 labels 包含动物类别）
        if let firstAnimal = results.first, let label = firstAnimal.labels.first {
            let identifier = label.identifier.lowercased()
            XCTAssertTrue(
                identifier.contains("cat") || identifier.contains("animal") || identifier.contains("dog"),
                "应识别为动物，实际为: \(identifier)"
            )
        }
    }

    /// 测试无动物图像的检测 - 应返回空结果
    func testAnimalRecognitionNoAnimal() async throws {
        let documentURL = TestResources.image("vision/document.png")
        // 文档图像没有动物
        let results = try await service.recognizeAnimals(at: documentURL)
        XCTAssertTrue(results.isEmpty, "文档图片应检测不到动物")
    }

    // MARK: - 手部检测测试

    /// 测试手部检测 - 有手部图片应检测到手部
    func testHandDetectionWithHand() async throws {
        let handURL = TestResources.image("vision/hand.png")
        let results = try await service.detectHumanHandPose(at: handURL)
        // 手部图片应检测到手部
        XCTAssertFalse(results.isEmpty, "应检测到手部")
    }

    /// 测试无手部图像的检测 - 应返回空结果
    func testHandDetectionNoHand() async throws {
        let testImageURL = TestResources.image("vision/classify.jpg")
        let results = try await service.detectHumanHandPose(at: testImageURL)
        XCTAssertTrue(results.isEmpty, "风景图应检测不到手部")
    }

    /// 测试手部检测最大数量参数
    func testHandDetectionMaxCount() async throws {
        let handURL = TestResources.image("vision/hand.png")
        // 测试限制最大手部数量为 1
        let results1 = try await service.detectHumanHandPose(at: handURL, maximumHandCount: 1)
        XCTAssertLessThanOrEqual(results1.count, 1, "应最多检测到 1 只手")

        // 测试允许最多 4 只手
        let results4 = try await service.detectHumanHandPose(at: handURL, maximumHandCount: 4)
        XCTAssertNotNil(results4)
    }
}
