import XCTest
@testable import Airis

/// Vision 框架性能基准测试（并行优化版）
///
/// 测试目标:
/// - 建立各 Vision 操作的性能基线
/// - 监测内存使用和 CPU 占用
/// - 使用并行 measure 加速测试
final class VisionPerformanceTests: XCTestCase {
    var service: VisionService!
    var testImageURL: URL!
    var documentImageURL: URL!

    // 测试资产目录
    static let testAssetsPath = NSString(string: "~/airis-worktrees/test-assets/task-9.1").expandingTildeInPath

    override func setUp() async throws {
        try await super.setUp()
        service = VisionService()

        // 使用预置的测试图片
        testImageURL = URL(fileURLWithPath: Self.testAssetsPath + "/benchmark_4k.png")
        documentImageURL = URL(fileURLWithPath: Self.testAssetsPath + "/document.png")

        // 验证测试资产存在
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试资产不存在: \(testImageURL.path)")
        }
    }

    override func tearDown() async throws {
        service = nil
        try await super.tearDown()
    }

    // MARK: - 图像分类性能基准

    /// 测试图像分类性能 - 使用 4K 图像（并行优化）
    func testClassifyImagePerformance_4K() async throws {
        let url = testImageURL!
        let svc = service!

        let stats = try await PerformanceUtils.measureParallel(iterations: 10, maxConcurrency: 4) {
            _ = try await svc.classifyImage(at: url, threshold: 0.1)
        }

        stats.print()
        XCTAssertLessThan(stats.average, 3.0, "平均分类时间应小于 3 秒")
    }

    /// 测试图像分类性能 - 高阈值过滤（并行优化）
    func testClassifyImagePerformance_HighThreshold() async throws {
        let url = testImageURL!
        let svc = service!

        let stats = try await PerformanceUtils.measureParallel(iterations: 10, maxConcurrency: 4) {
            _ = try await svc.classifyImage(at: url, threshold: 0.5)
        }

        stats.print()
        XCTAssertLessThan(stats.average, 3.0, "高阈值分类应小于 3 秒")
    }

    // MARK: - OCR 性能基准

    /// 测试 OCR 识别性能 - 准确模式（并行优化）
    func testOCRPerformance_Accurate() async throws {
        guard FileManager.default.fileExists(atPath: documentImageURL.path) else {
            throw XCTSkip("文档测试图片不存在")
        }

        let url = documentImageURL!
        let svc = service!

        let stats = try await PerformanceUtils.measureParallel(iterations: 10, maxConcurrency: 3) {
            _ = try await svc.recognizeText(at: url, level: .accurate)
        }

        stats.print()
        XCTAssertLessThan(stats.average, 5.0, "准确模式 OCR 应小于 5 秒")
    }

    /// 测试 OCR 识别性能 - 快速模式（并行优化）
    func testOCRPerformance_Fast() async throws {
        guard FileManager.default.fileExists(atPath: documentImageURL.path) else {
            throw XCTSkip("文档测试图片不存在")
        }

        let url = documentImageURL!
        let svc = service!

        let stats = try await PerformanceUtils.measureParallel(iterations: 10, maxConcurrency: 3) {
            _ = try await svc.recognizeText(at: url, level: .fast)
        }

        stats.print()
        XCTAssertLessThan(stats.average, 3.0, "快速模式 OCR 应小于 3 秒")
    }

    // MARK: - 人脸检测性能基准

    /// 测试人脸特征检测性能（并行优化）
    func testFaceLandmarksDetectionPerformance() async throws {
        let url = testImageURL!
        let svc = service!

        let stats = try await PerformanceUtils.measureParallel(iterations: 10, maxConcurrency: 4) {
            _ = try await svc.detectFaceLandmarks(at: url)
        }

        stats.print()
        XCTAssertLessThan(stats.average, 2.0, "人脸特征检测应小于 2 秒")
    }

    /// 测试人脸位置检测性能（不含特征，更快）（并行优化）
    func testFaceRectanglesDetectionPerformance() async throws {
        let url = testImageURL!
        let svc = service!

        let stats = try await PerformanceUtils.measureParallel(iterations: 10, maxConcurrency: 4) {
            _ = try await svc.detectFaceRectangles(at: url)
        }

        stats.print()
        XCTAssertLessThan(stats.average, 1.5, "人脸位置检测应小于 1.5 秒")
    }

    // MARK: - 批量请求性能基准

    /// 测试批量请求性能（复用同一个 handler）（并行优化）
    func testBatchRequestsPerformance() async throws {
        let url = testImageURL!
        let svc = service!

        let stats = try await PerformanceUtils.measureParallel(iterations: 10, maxConcurrency: 3) {
            _ = try await svc.performMultipleRequests(at: url)
        }

        stats.print()
        XCTAssertLessThan(stats.average, 5.0, "批量请求应小于 5 秒")
    }

    // MARK: - 显著性检测性能

    /// 测试注意力显著性检测性能（并行优化）
    func testAttentionSaliencyPerformance() async throws {
        let url = testImageURL!
        let svc = service!

        let stats = try await PerformanceUtils.measureParallel(iterations: 10, maxConcurrency: 4) {
            _ = try await svc.detectSaliency(at: url, type: .attention)
        }

        stats.print()
        XCTAssertLessThan(stats.average, 2.0, "注意力显著性检测应小于 2 秒")
    }

    /// 测试对象显著性检测性能（并行优化）
    func testObjectnessSaliencyPerformance() async throws {
        let url = testImageURL!
        let svc = service!

        let stats = try await PerformanceUtils.measureParallel(iterations: 10, maxConcurrency: 4) {
            _ = try await svc.detectSaliency(at: url, type: .objectness)
        }

        stats.print()
        XCTAssertLessThan(stats.average, 2.0, "对象显著性检测应小于 2 秒")
    }

    // MARK: - 人物分割性能

    /// 测试人物分割性能 - 快速模式（并行优化）
    func testPersonSegmentationPerformance_Fast() async throws {
        let url = testImageURL!
        let svc = service!

        let stats = try await PerformanceUtils.measureParallel(iterations: 10, maxConcurrency: 3) {
            _ = try await svc.generatePersonSegmentation(at: url, quality: .fast)
        }

        stats.print()
        XCTAssertLessThan(stats.average, 3.0, "快速人物分割应小于 3 秒")
    }

    /// 测试人物分割性能 - 精确模式（并行优化）
    func testPersonSegmentationPerformance_Accurate() async throws {
        let url = testImageURL!
        let svc = service!

        let stats = try await PerformanceUtils.measureParallel(iterations: 10, maxConcurrency: 2) {
            _ = try await svc.generatePersonSegmentation(at: url, quality: .accurate)
        }

        stats.print()
        XCTAssertLessThan(stats.average, 5.0, "精确人物分割应小于 5 秒")
    }
}
