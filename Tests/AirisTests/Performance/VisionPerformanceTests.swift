import XCTest
@testable import Airis

/// Vision 框架性能基准测试
///
/// 测试目标:
/// - 建立各 Vision 操作的性能基线
/// - 监测内存使用和 CPU 占用
/// - 验证批量处理性能
final class VisionPerformanceTests: XCTestCase {
    var service: VisionService!
    var testImageURL: URL!
    var documentImageURL: URL!

    // 内置测试资源路径
    static let resourcePath = "Tests/Resources/images"

    override func setUp() async throws {
        try await super.setUp()
        service = VisionService()

        // 使用 1024x1024 图片进行性能测试（平衡大小与速度）
        testImageURL = URL(fileURLWithPath: Self.resourcePath + "/assets/perf_1024x1024.jpg")
        // OCR 性能测试用 512x512 文档图（避免耗时过长）
        documentImageURL = URL(fileURLWithPath: Self.resourcePath + "/assets/document_text_512x512.png")

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

    /// 测试图像分类性能 - 使用 1K 图像
    func testClassifyImagePerformance_4K() async throws {
        let url = try XCTUnwrap(testImageURL)
        let svc = try XCTUnwrap(service)

        // 预热 - 首次调用可能较慢
        _ = try? await svc.classifyImage(at: url, threshold: 0.1)

        // 使用同步 measure 测量多次调用
        measure {
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                _ = try? await svc.classifyImage(at: url, threshold: 0.1)
                semaphore.signal()
            }
            semaphore.wait()
        }
    }

    /// 测试图像分类性能 - 高阈值过滤
    func testClassifyImagePerformance_HighThreshold() async throws {
        let url = try XCTUnwrap(testImageURL)
        let svc = try XCTUnwrap(service)

        measure {
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                _ = try? await svc.classifyImage(at: url, threshold: 0.5)
                semaphore.signal()
            }
            semaphore.wait()
        }
    }

    // MARK: - OCR 性能基准

    /// 测试 OCR 识别性能 - 准确模式
    func testOCRPerformance_Accurate() async throws {
        guard FileManager.default.fileExists(atPath: documentImageURL.path) else {
            throw XCTSkip("文档测试图片不存在")
        }

        let url = try XCTUnwrap(documentImageURL)
        let svc = try XCTUnwrap(service)

        // OCR Accurate 很慢，只测 1 次，不预热
        let options = XCTMeasureOptions()
        options.iterationCount = 1

        measure(options: options) {
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                _ = try? await svc.recognizeText(at: url, level: .accurate)
                semaphore.signal()
            }
            semaphore.wait()
        }
    }

    /// 测试 OCR 识别性能 - 快速模式
    func testOCRPerformance_Fast() async throws {
        guard FileManager.default.fileExists(atPath: documentImageURL.path) else {
            throw XCTSkip("文档测试图片不存在")
        }

        let url = try XCTUnwrap(documentImageURL)
        let svc = try XCTUnwrap(service)

        let options = XCTMeasureOptions()
        options.iterationCount = 1

        measure(options: options) {
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                _ = try? await svc.recognizeText(at: url, level: .fast)
                semaphore.signal()
            }
            semaphore.wait()
        }
    }

    // MARK: - 人脸检测性能基准

    /// 测试人脸特征检测性能
    func testFaceLandmarksDetectionPerformance() async throws {
        let url = try XCTUnwrap(testImageURL)
        let svc = try XCTUnwrap(service)

        measure {
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                _ = try? await svc.detectFaceLandmarks(at: url)
                semaphore.signal()
            }
            semaphore.wait()
        }
    }

    /// 测试人脸位置检测性能（不含特征，更快）
    func testFaceRectanglesDetectionPerformance() async throws {
        let url = try XCTUnwrap(testImageURL)
        let svc = try XCTUnwrap(service)

        measure {
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                _ = try? await svc.detectFaceRectangles(at: url)
                semaphore.signal()
            }
            semaphore.wait()
        }
    }

    // MARK: - 批量请求性能基准

    /// 测试批量请求性能（复用同一个 handler）
    func testBatchRequestsPerformance() async throws {
        let url = try XCTUnwrap(testImageURL)
        let svc = try XCTUnwrap(service)

        // 预热
        _ = try? await svc.performMultipleRequests(at: url)

        measure {
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                _ = try? await svc.performMultipleRequests(at: url)
                semaphore.signal()
            }
            semaphore.wait()
        }
    }

    // MARK: - 显著性检测性能

    /// 测试注意力显著性检测性能
    func testAttentionSaliencyPerformance() async throws {
        let url = try XCTUnwrap(testImageURL)
        let svc = try XCTUnwrap(service)

        measure {
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                _ = try? await svc.detectSaliency(at: url, type: .attention)
                semaphore.signal()
            }
            semaphore.wait()
        }
    }

    /// 测试对象显著性检测性能
    func testObjectnessSaliencyPerformance() async throws {
        let url = try XCTUnwrap(testImageURL)
        let svc = try XCTUnwrap(service)

        measure {
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                _ = try? await svc.detectSaliency(at: url, type: .objectness)
                semaphore.signal()
            }
            semaphore.wait()
        }
    }

    // MARK: - 人物分割性能

    /// 测试人物分割性能 - 快速模式
    func testPersonSegmentationPerformance_Fast() async throws {
        let url = try XCTUnwrap(testImageURL)
        let svc = try XCTUnwrap(service)

        measure {
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                _ = try? await svc.generatePersonSegmentation(at: url, quality: .fast)
                semaphore.signal()
            }
            semaphore.wait()
        }
    }

    /// 测试人物分割性能 - 精确模式
    func testPersonSegmentationPerformance_Accurate() async throws {
        let url = try XCTUnwrap(testImageURL)
        let svc = try XCTUnwrap(service)

        measure {
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                _ = try? await svc.generatePersonSegmentation(at: url, quality: .accurate)
                semaphore.signal()
            }
            semaphore.wait()
        }
    }
}
