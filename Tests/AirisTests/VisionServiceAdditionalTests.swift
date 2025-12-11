import XCTest
import Vision
@testable import Airis

/// VisionService 补充测试
///
/// 覆盖之前未测试的方法
final class VisionServiceAdditionalTests: XCTestCase {
    var service: VisionService!
    var testImageURL: URL!

    // 测试资源路径（相对于项目根目录）
    static let resourcePath = "Tests/Resources/images"

    override func setUp() async throws {
        try await super.setUp()
        service = VisionService()

        // 使用内置的 512x512 中等尺寸图片，避免光流等计算密集操作耗时过长
        testImageURL = URL(fileURLWithPath: Self.resourcePath + "/assets/medium_512x512.jpg")

        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试资产不存在: \(testImageURL.path)")
        }
    }

    override func tearDown() async throws {
        service = nil
        try await super.tearDown()
    }

    // MARK: - 人体姿态检测

    /// 测试人体 2D 姿态检测
    func testDetectHumanBodyPose() async throws {
        let results = try await service.detectHumanBodyPose(at: testImageURL)
        // 风景图可能没有人体
        XCTAssertNotNil(results)
    }

    /// 测试人体 3D 姿态检测 (macOS 14.0+)
    @available(macOS 14.0, *)
    func testDetectHumanBodyPose3D() async throws {
        let results = try await service.detectHumanBodyPose3D(at: testImageURL)
        XCTAssertNotNil(results)
    }

    // MARK: - 动物姿态检测

    /// 测试动物姿态检测 (macOS 14.0+)
    @available(macOS 14.0, *)
    func testDetectAnimalBodyPose() async throws {
        let results = try await service.detectAnimalBodyPose(at: testImageURL)
        XCTAssertNotNil(results)
    }

    // MARK: - 光流分析

    /// 测试光流计算
    func testComputeOpticalFlow() async throws {
        // 使用同一张图片作为源和目标（光流应该为零）
        let result = try await service.computeOpticalFlow(
            from: testImageURL,
            to: testImageURL,
            accuracy: .medium
        )

        XCTAssertGreaterThan(result.width, 0)
        XCTAssertGreaterThan(result.height, 0)
        XCTAssertNotNil(result.pixelBuffer)
    }

    /// 测试光流精度级别
    func testOpticalFlowAccuracyLevels() async throws {
        // 测试不同精度级别
        for accuracy in VisionService.OpticalFlowAccuracy.allCases {
            let result = try await service.computeOpticalFlow(
                from: testImageURL,
                to: testImageURL,
                accuracy: accuracy
            )
            XCTAssertGreaterThan(result.width, 0)
        }
    }

    // MARK: - 图像配准

    /// 测试图像对齐计算
    func testComputeImageAlignment() async throws {
        // 使用同一张图片（应该对齐，平移接近零）
        let result = try await service.computeImageAlignment(
            referenceURL: testImageURL,
            floatingURL: testImageURL
        )

        XCTAssertNotNil(result.transform)
        // 同一张图片的平移应该接近零
        XCTAssertEqual(result.translationX, 0, accuracy: 1.0)
        XCTAssertEqual(result.translationY, 0, accuracy: 1.0)
    }

    // MARK: - 地平线检测

    /// 测试地平线检测
    func testDetectHorizon() async throws {
        let result = try await service.detectHorizon(at: testImageURL)
        // 可能检测到也可能检测不到
        if let horizon = result {
            XCTAssertGreaterThanOrEqual(horizon.confidence, 0)
            XCTAssertLessThanOrEqual(horizon.confidence, 1)
        }
    }

    /// 使用清晰地平线图片，期望命中成功分支
    func testDetectHorizonWithClearLine() async throws {
        let url = URL(fileURLWithPath: Self.resourcePath + "/assets/horizon_clear_512x512.jpg")
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw XCTSkip("清晰地平线测试图片不存在")
        }

        let result = try await service.detectHorizon(at: url)
        XCTAssertNotNil(result, "清晰地平线图片应检测到地平线")
    }

    // MARK: - 前景分割

    /// 测试前景遮罩生成 (macOS 14.0+)
    @available(macOS 14.0, *)
    func testGenerateForegroundMask() async throws {
        do {
            let result = try await service.generateForegroundMask(at: testImageURL)
            XCTAssertGreaterThan(result.extent.width, 0)
        } catch AirisError.noResultsFound {
            // 风景图可能没有前景对象
            XCTAssertTrue(true)
        }
    }

    /// 使用单人沙滩照片，期望生成前景遮罩
    @available(macOS 14.0, *)
    func testGenerateForegroundMaskWithForegroundSubject() async throws {
        let url = URL(fileURLWithPath: Self.resourcePath + "/assets/foreground_person_beach_512x512.jpg")
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw XCTSkip("前景人物测试图片不存在")
        }

        let result = try await service.generateForegroundMask(at: url)
        XCTAssertGreaterThan(result.extent.width, 0)
        XCTAssertGreaterThan(result.extent.height, 0)
    }

    /// 覆盖 AirisError 分支
    @available(macOS 14.0, *)
    func testGenerateForegroundMaskAirisErrorBranch() async throws {
        final class AirisErrorOps: VisionOperations {
            func perform(requests: [VNRequest], on handler: VNImageRequestHandler) throws {
                throw AirisError.noResultsFound
            }
        }

        let service = VisionService(operations: AirisErrorOps())
        let url = URL(fileURLWithPath: Self.resourcePath + "/assets/foreground_person_indoor_512x512.jpg")
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw XCTSkip("前景人物室内测试图片不存在")
        }

        do {
            _ = try await service.generateForegroundMask(at: url)
            XCTFail("应抛出 AirisError.noResultsFound")
        } catch AirisError.noResultsFound {
            // 预期路径，命中 catch 分支
        }
    }

    // MARK: - 条形码检测带符号类型

    /// 测试指定符号类型的条形码检测
    func testDetectBarcodesWithSymbologies() async throws {
        let results = try await service.detectBarcodes(
            at: testImageURL,
            symbologies: [.qr, .ean13, .code128]
        )
        XCTAssertNotNil(results)
    }

    // MARK: - 显著性类型测试

    /// 测试所有显著性类型
    func testAllSaliencyTypes() async throws {
        for type in VisionService.SaliencyType.allCases {
            let result = try await service.detectSaliency(at: testImageURL, type: type)
            XCTAssertGreaterThan(result.width, 0)
            XCTAssertGreaterThan(result.height, 0)
        }
    }

    // MARK: - 人物分割质量级别

    /// 测试所有人物分割质量级别
    func testAllPersonSegmentationQualities() async throws {
        for quality in VisionService.PersonSegmentationQuality.allCases {
            do {
                let result = try await service.generatePersonSegmentation(at: testImageURL, quality: quality)
                XCTAssertGreaterThan(result.width, 0)
            } catch AirisError.noResultsFound {
                // 没有人物也是正常的
                XCTAssertTrue(true)
            }
        }
    }

    // MARK: - 矩形检测参数测试

    /// 测试矩形检测不同参数
    func testDetectRectanglesWithParameters() async throws {
        // 使用包含矩形（文档）的测试图片
        let rectangleURL = URL(fileURLWithPath: Self.resourcePath + "/assets/rectangle_512x512.png")
        guard FileManager.default.fileExists(atPath: rectangleURL.path) else {
            throw XCTSkip("矩形测试图片不存在")
        }

        let results = try await service.detectRectangles(
            at: rectangleURL,
            minimumConfidence: 0.3,
            minimumSize: 0.05,
            maximumObservations: 5
        )

        XCTAssertNotNil(results)
        // 文档图片应该检测到矩形
        XCTAssertFalse(results.isEmpty, "应该检测到至少一个矩形")
        // 验证结果结构
        for rect in results {
            XCTAssertGreaterThanOrEqual(rect.confidence, 0.3)
        }
    }
}
