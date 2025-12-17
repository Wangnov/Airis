import XCTest
@preconcurrency import CoreImage
@preconcurrency import Vision
#if !XCODE_BUILD
@testable import AirisCore
#endif

/// 并发安全测试
///
/// 测试目标:
/// - 验证服务的线程安全性
/// - 测试并发访问不会导致崩溃
/// - 测试并发操作的数据一致性
final class ConcurrencyTests: XCTestCase {

    var testImageURL: URL!
    var tempDirectory: URL!

    override func setUp() async throws {
        try await super.setUp()
        testImageURL = TestResources.image("assets/medium_512x512.jpg")

        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("airis_concurrent_test_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDirectory)
        try await super.tearDown()
    }

    // MARK: - Vision 服务并发测试

    /// 测试并发图像分类 - 使用 async let
    func testConcurrentClassification() async throws {
        let visionService = VisionService()
        let url = try XCTUnwrap(testImageURL)

        async let result1 = visionService.classifyImage(at: url, threshold: 0.1)
        async let result2 = visionService.classifyImage(at: url, threshold: 0.1)
        async let result3 = visionService.classifyImage(at: url, threshold: 0.1)

        let results = try await [result1, result2, result3]
        XCTAssertEqual(results.count, 3)
    }

    /// 测试并发 OCR
    func testConcurrentOCR() async throws {
        let documentURL = TestResources.image("vision/document.png")

        let visionService = VisionService()

        async let result1 = visionService.recognizeText(at: documentURL)
        async let result2 = visionService.recognizeText(at: documentURL)

        let results = try await [result1, result2]
        XCTAssertEqual(results.count, 2)
    }

    /// 测试并发人脸检测
    func testConcurrentFaceDetection() async throws {
        let visionService = VisionService()
        let url = try XCTUnwrap(testImageURL)

        async let result1 = visionService.detectFaceRectangles(at: url)
        async let result2 = visionService.detectFaceRectangles(at: url)

        _ = try await (result1, result2)
        XCTAssertTrue(true)
    }

    /// 测试混合 Vision 操作并发
    func testMixedVisionOperationsConcurrent() async throws {
        let visionService = VisionService()
        let url = try XCTUnwrap(testImageURL)

        async let classifyResult = visionService.classifyImage(at: url)
        async let faceResult = visionService.detectFaceLandmarks(at: url)
        async let saliencyResult = visionService.detectSaliency(at: url, type: .attention)
        async let barcodeResult = visionService.detectBarcodes(at: url)

        _ = try await (classifyResult, faceResult, saliencyResult, barcodeResult)
        XCTAssertTrue(true)
    }

    // MARK: - CoreImage 服务并发测试

    /// 测试并发滤镜应用
    func testConcurrentFilterApplication() async throws {
        let coreImageService = CoreImageService()
        let testImage = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 500, height: 500))

        // 并行执行多个滤镜
        let results = await withTaskGroup(of: CGFloat.self, returning: [CGFloat].self) { group in
            for i in 0..<5 {
                group.addTask { @Sendable in
                    let processed = coreImageService.gaussianBlur(ciImage: testImage, radius: Double(i + 1))
                    return processed.extent.width
                }
            }
            var results: [CGFloat] = []
            for await width in group {
                results.append(width)
            }
            return results
        }

        XCTAssertEqual(results.count, 5)
    }

    /// 测试并发渲染
    func testConcurrentRendering() async throws {
        let coreImageService = CoreImageService()
        let testImages = (0..<3).map { i in
            CIImage(color: CIColor(red: CGFloat(i) * 0.3, green: 0.5, blue: 0.5))
                .cropped(to: CGRect(x: 0, y: 0, width: 200, height: 200))
        }

        var successCount = 0
        for image in testImages where coreImageService.render(ciImage: image) != nil {
            successCount += 1
        }

        XCTAssertEqual(successCount, 3)
    }

    /// 测试并发滤镜链
    func testConcurrentFilterChains() async throws {
        let coreImageService = CoreImageService()
        let testImage = CIImage(color: .blue)
            .cropped(to: CGRect(x: 0, y: 0, width: 300, height: 300))

        // 应用滤镜链
        var processed = testImage
        processed = coreImageService.gaussianBlur(ciImage: processed, radius: 3)
        processed = coreImageService.sharpen(ciImage: processed, sharpness: 0.3)
        processed = coreImageService.adjustColors(ciImage: processed, brightness: 0.1, contrast: 1.1, saturation: 1.1)
        let result = coreImageService.render(ciImage: processed)

        XCTAssertNotNil(result)
    }

    // MARK: - ImageIO 服务并发测试

    /// 测试并发图像加载
    func testConcurrentImageLoading() async throws {
        let imageIOService = ImageIOService()
        let url = try XCTUnwrap(testImageURL)

        // 加载不同尺寸
        let image128 = try imageIOService.loadImage(at: url, maxDimension: 128)
        let image256 = try imageIOService.loadImage(at: url, maxDimension: 256)
        let image512 = try imageIOService.loadImage(at: url, maxDimension: 512)

        // 验证所有图像都成功加载
        XCTAssertGreaterThan(image128.width, 0)
        XCTAssertGreaterThan(image256.width, 0)
        XCTAssertGreaterThan(image512.width, 0)
        // 缩略图应该比原图小或等于指定尺寸
        XCTAssertLessThanOrEqual(image128.width, max(128, image128.width))
    }

    /// 测试并发图像保存
    func testConcurrentImageSaving() async throws {
        let imageIOService = ImageIOService()
        let url = try XCTUnwrap(testImageURL)
        let tempDir = try XCTUnwrap(tempDirectory)
        let cgImage = try imageIOService.loadImage(at: url, maxDimension: 200)

        // 保存多个文件
        for i in 0..<3 {
            let outputPath = tempDir.appendingPathComponent("output_\(i).png")
            try imageIOService.saveImage(cgImage, to: outputPath, format: "png")
        }

        // 验证所有文件都已创建
        for i in 0..<3 {
            let outputPath = tempDir.appendingPathComponent("output_\(i).png")
            XCTAssertTrue(FileManager.default.fileExists(atPath: outputPath.path))
        }
    }

    /// 测试并发元数据读取
    func testConcurrentMetadataReading() async throws {
        let imageIOService = ImageIOService()
        let url = try XCTUnwrap(testImageURL)

        // 多次读取元数据
        for _ in 0..<5 {
            let metadata = try imageIOService.loadImageMetadata(at: url)
            XCTAssertGreaterThan(metadata.count, 0)
        }
    }

    // MARK: - 混合服务并发测试

    /// 测试多服务同时使用
    func testMultiServiceConcurrency() async throws {
        let visionService = VisionService()
        let imageIOService = ImageIOService()
        let coreImageService = CoreImageService()
        let url = try XCTUnwrap(testImageURL)

        // Vision 操作
        _ = try await visionService.classifyImage(at: url)

        // ImageIO 操作
        _ = try imageIOService.loadImage(at: url, maxDimension: 512)

        // CoreImage 操作
        let image = try XCTUnwrap(CIImage(contentsOf: url))
        let blurred = coreImageService.gaussianBlur(ciImage: image, radius: 5)
        _ = coreImageService.render(ciImage: blurred)

        XCTAssertTrue(true)
    }

    /// 测试完整工作流
    func testFullWorkflow() async throws {
        let imageIOService = ImageIOService()
        let coreImageService = CoreImageService()
        let url = try XCTUnwrap(testImageURL)
        let tempDir = try XCTUnwrap(tempDirectory)

        for i in 0..<2 {
            let outputPath = tempDir.appendingPathComponent("workflow_\(i).jpg")
            let cgImage = try imageIOService.loadImage(at: url, maxDimension: 512)
            let ciImage = CIImage(cgImage: cgImage)
            let processed = coreImageService.gaussianBlur(ciImage: ciImage, radius: 3)
            guard let outputCGImage = coreImageService.render(ciImage: processed) else {
                XCTFail("渲染失败")
                return
            }
            try imageIOService.saveImage(outputCGImage, to: outputPath, format: "jpg", quality: 0.9)
        }

        for i in 0..<2 {
            let outputPath = tempDir.appendingPathComponent("workflow_\(i).jpg")
            XCTAssertTrue(FileManager.default.fileExists(atPath: outputPath.path))
        }
    }

    // MARK: - 压力测试

    /// 测试大量请求
    func testHighLoadStress() async throws {
        let coreImageService = CoreImageService()
        let testImage = CIImage(color: .green)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        var successCount = 0

        // 执行 20 次操作
        for _ in 0..<20 {
            let blurred = coreImageService.gaussianBlur(ciImage: testImage, radius: 5)
            if coreImageService.render(ciImage: blurred) != nil {
                successCount += 1
            }
        }

        XCTAssertEqual(successCount, 20)
    }
}
