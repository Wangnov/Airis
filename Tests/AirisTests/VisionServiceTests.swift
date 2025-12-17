// swiftlint:disable force_unwrapping
import XCTest
@preconcurrency import Vision
#if !XCODE_BUILD
@testable import AirisCore
#endif

final class VisionServiceTests: XCTestCase {
    var service: VisionService!

    override func setUp() {
        super.setUp()
        service = VisionService()
    }

    // MARK: - Service Creation Tests

    func testServiceInitialization() throws {
        XCTAssertNotNil(service)
    }

    func testServiceContainerAccess() throws {
        let containerService = ServiceContainer.shared.visionService
        XCTAssertNotNil(containerService)
    }

    // MARK: - Comprehensive Analysis Tests

    func testComprehensiveAnalysisStructure() throws {
        let analysis = VisionService.ComprehensiveAnalysis(
            classifications: [],
            texts: [],
            barcodes: []
        )

        XCTAssertEqual(analysis.classifications.count, 0)
        XCTAssertEqual(analysis.texts.count, 0)
        XCTAssertEqual(analysis.barcodes.count, 0)
    }

    // 注意：实际的图像分析测试需要测试图片资源
    // 这些测试在有测试图片后可以取消 skip

    // MARK: - Mock Tests (Error Path Coverage)

    /// 测试 Vision 请求执行失败
    func testClassifyImage_RequestFails() async throws {
        let mockOps = MockVisionOperations(shouldFail: true, errorMessage: "Mock error")
        let mockService = VisionService(operations: mockOps)

        // 创建测试图像
        let testImage = createTestCGImage()

        do {
            _ = try await mockService.classifyImage(cgImage: testImage)
            XCTFail("应该抛出错误")
        } catch {
            guard case AirisError.visionRequestFailed(let message) = error else {
                XCTFail("应该抛出 visionRequestFailed，实际为: \(error)")
                return
            }
            XCTAssertTrue(message.contains("Mock error"))
        }
    }

    /// 测试 detectFaceLandmarks 失败
    func testDetectFaceLandmarks_RequestFails() async throws {
        let mockOps = MockVisionOperations(shouldFail: true)
        let mockService = VisionService(operations: mockOps)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        do {
            _ = try await mockService.detectFaceLandmarks(at: tempURL)
            XCTFail("应该抛出错误")
        } catch {
            guard case AirisError.visionRequestFailed = error else {
                XCTFail("应该抛出 visionRequestFailed")
                return
            }
        }
    }

    /// 测试 detectBarcodes 失败
    func testDetectBarcodes_RequestFails() async throws {
        let mockOps = MockVisionOperations(shouldFail: true)
        let mockService = VisionService(operations: mockOps)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        do {
            _ = try await mockService.detectBarcodes(at: tempURL)
            XCTFail("应该抛出错误")
        } catch {
            guard case AirisError.visionRequestFailed = error else {
                XCTFail("应该抛出 visionRequestFailed")
                return
            }
        }
    }

    /// 测试 recognizeAnimals 失败
    func testRecognizeAnimals_RequestFails() async throws {
        let mockOps = MockVisionOperations(shouldFail: true)
        let mockService = VisionService(operations: mockOps)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        do {
            _ = try await mockService.recognizeAnimals(at: tempURL)
            XCTFail("应该抛出错误")
        } catch {
            guard case AirisError.visionRequestFailed = error else {
                XCTFail("应该抛出 visionRequestFailed")
                return
            }
        }
    }

    /// 测试 detectHumanBodyPose 失败
    func testDetectHumanBodyPose_RequestFails() async throws {
        let mockOps = MockVisionOperations(shouldFail: true)
        let mockService = VisionService(operations: mockOps)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        do {
            _ = try await mockService.detectHumanBodyPose(at: tempURL)
            XCTFail("应该抛出错误")
        } catch {
            guard case AirisError.visionRequestFailed = error else {
                XCTFail("应该抛出 visionRequestFailed")
                return
            }
        }
    }

    /// 测试 performMultipleRequests 失败
    func testPerformMultipleRequests_RequestFails() async throws {
        let mockOps = MockVisionOperations(shouldFail: true)
        let mockService = VisionService(operations: mockOps)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        do {
            _ = try await mockService.performMultipleRequests(at: tempURL)
            XCTFail("应该抛出错误")
        } catch {
            guard case AirisError.visionRequestFailed = error else {
                XCTFail("应该抛出 visionRequestFailed")
                return
            }
        }
    }

    /// 测试 recognizeText 失败
    func testRecognizeText_RequestFails() async throws {
        let mockOps = MockVisionOperations(shouldFail: true)
        let mockService = VisionService(operations: mockOps)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        do {
            _ = try await mockService.recognizeText(at: tempURL)
            XCTFail("应该抛出错误")
        } catch {
            guard case AirisError.visionRequestFailed = error else {
                XCTFail("应该抛出 visionRequestFailed")
                return
            }
        }
    }

    /// 测试 detectFaceRectangles 失败
    func testDetectFaceRectangles_RequestFails() async throws {
        let mockOps = MockVisionOperations(shouldFail: true)
        let mockService = VisionService(operations: mockOps)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        do {
            _ = try await mockService.detectFaceRectangles(at: tempURL)
            XCTFail("应该抛出错误")
        } catch {
            guard case AirisError.visionRequestFailed = error else {
                XCTFail("应该抛出 visionRequestFailed")
                return
            }
        }
    }

    /// 测试 detectHumanBodyPose3D 失败
    func testDetectHumanBodyPose3D_RequestFails() async throws {
        let mockOps = MockVisionOperations(shouldFail: true)
        let mockService = VisionService(operations: mockOps)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        do {
            _ = try await mockService.detectHumanBodyPose3D(at: tempURL)
            XCTFail("应该抛出错误")
        } catch {
            guard case AirisError.visionRequestFailed = error else {
                XCTFail("应该抛出 visionRequestFailed")
                return
            }
        }
    }

    /// 测试 detectHumanHandPose 失败
    func testDetectHumanHandPose_RequestFails() async throws {
        let mockOps = MockVisionOperations(shouldFail: true)
        let mockService = VisionService(operations: mockOps)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        do {
            _ = try await mockService.detectHumanHandPose(at: tempURL)
            XCTFail("应该抛出错误")
        } catch {
            guard case AirisError.visionRequestFailed = error else {
                XCTFail("应该抛出 visionRequestFailed")
                return
            }
        }
    }

    /// 测试 detectAnimalBodyPose 失败
    func testDetectAnimalBodyPose_RequestFails() async throws {
        let mockOps = MockVisionOperations(shouldFail: true)
        let mockService = VisionService(operations: mockOps)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        do {
            _ = try await mockService.detectAnimalBodyPose(at: tempURL)
            XCTFail("应该抛出错误")
        } catch {
            guard case AirisError.visionRequestFailed = error else {
                XCTFail("应该抛出 visionRequestFailed")
                return
            }
        }
    }

    /// 测试 detectRectangles 失败
    func testDetectRectangles_RequestFails() async throws {
        let mockOps = MockVisionOperations(shouldFail: true)
        let mockService = VisionService(operations: mockOps)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        do {
            _ = try await mockService.detectRectangles(at: tempURL)
            XCTFail("应该抛出错误")
        } catch {
            guard case AirisError.visionRequestFailed = error else {
                XCTFail("应该抛出 visionRequestFailed")
                return
            }
        }
    }

    /// 测试 detectSaliency 失败
    func testDetectSaliency_RequestFails() async throws {
        let mockOps = MockVisionOperations(shouldFail: true)
        let mockService = VisionService(operations: mockOps)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        do {
            _ = try await mockService.detectSaliency(at: tempURL, type: .attention)
            XCTFail("应该抛出错误")
        } catch {
            guard case AirisError.visionRequestFailed = error else {
                XCTFail("应该抛出 visionRequestFailed")
                return
            }
        }
    }

    /// 测试 generatePersonSegmentation 失败
    func testGeneratePersonSegmentation_RequestFails() async throws {
        let mockOps = MockVisionOperations(shouldFail: true)
        let mockService = VisionService(operations: mockOps)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        do {
            _ = try await mockService.generatePersonSegmentation(at: tempURL)
            XCTFail("应该抛出错误")
        } catch {
            guard case AirisError.visionRequestFailed = error else {
                XCTFail("应该抛出 visionRequestFailed")
                return
            }
        }
    }

    /// 测试 computeOpticalFlow 失败
    func testComputeOpticalFlow_RequestFails() async throws {
        let mockOps = MockVisionOperations(shouldFail: true)
        let mockService = VisionService(operations: mockOps)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        do {
            _ = try await mockService.computeOpticalFlow(from: tempURL, to: tempURL)
            XCTFail("应该抛出错误")
        } catch {
            guard case AirisError.visionRequestFailed = error else {
                XCTFail("应该抛出 visionRequestFailed")
                return
            }
        }
    }

    /// 测试 computeImageAlignment 失败
    func testComputeImageAlignment_RequestFails() async throws {
        let mockOps = MockVisionOperations(shouldFail: true)
        let mockService = VisionService(operations: mockOps)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        do {
            _ = try await mockService.computeImageAlignment(referenceURL: tempURL, floatingURL: tempURL)
            XCTFail("应该抛出错误")
        } catch {
            guard case AirisError.visionRequestFailed = error else {
                XCTFail("应该抛出 visionRequestFailed")
                return
            }
        }
    }

    /// 测试 detectHorizon 失败
    func testDetectHorizon_RequestFails() async throws {
        let mockOps = MockVisionOperations(shouldFail: true)
        let mockService = VisionService(operations: mockOps)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        do {
            _ = try await mockService.detectHorizon(at: tempURL)
            XCTFail("应该抛出错误")
        } catch {
            guard case AirisError.visionRequestFailed = error else {
                XCTFail("应该抛出 visionRequestFailed")
                return
            }
        }
    }

    /// 测试 generateForegroundMask 失败
    func testGenerateForegroundMask_RequestFails() async throws {
        let mockOps = MockVisionOperations(shouldFail: true)
        let mockService = VisionService(operations: mockOps)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        do {
            _ = try await mockService.generateForegroundMask(at: tempURL)
            XCTFail("应该抛出错误")
        } catch {
            guard case AirisError.visionRequestFailed = error else {
                XCTFail("应该抛出 visionRequestFailed")
                return
            }
        }
    }

    /// 测试 request.results 为 nil 的场景（触发 ?? [] 备用路径）
    func testClassifyImage_NilResults() async throws {
        let mockOps = MockVisionOperations(shouldReturnNilResults: true)
        let mockService = VisionService(operations: mockOps)

        let testImage = createTestCGImage()

        // 应该返回空数组（而不是崩溃）
        let results = try await mockService.classifyImage(cgImage: testImage)
        XCTAssertEqual(results.count, 0, "nil results 应该被转换为空数组")
    }

    /// 测试 recognizeText nil results
    func testRecognizeText_NilResults() async throws {
        let mockOps = MockVisionOperations(shouldReturnNilResults: true)
        let mockService = VisionService(operations: mockOps)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let results = try await mockService.recognizeText(at: tempURL)
        XCTAssertEqual(results.count, 0)
    }

    /// 测试 detectBarcodes nil results
    func testDetectBarcodes_NilResults() async throws {
        let mockOps = MockVisionOperations(shouldReturnNilResults: true)
        let mockService = VisionService(operations: mockOps)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let results = try await mockService.detectBarcodes(at: tempURL)
        XCTAssertEqual(results.count, 0)
    }

    /// 测试 detectFaceLandmarks nil results
    func testDetectFaceLandmarks_NilResults() async throws {
        let mockOps = MockVisionOperations(shouldReturnNilResults: true)
        let mockService = VisionService(operations: mockOps)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let results = try await mockService.detectFaceLandmarks(at: tempURL)
        XCTAssertEqual(results.count, 0)
    }

    /// 测试 detectFaceRectangles nil results
    func testDetectFaceRectangles_NilResults() async throws {
        let mockOps = MockVisionOperations(shouldReturnNilResults: true)
        let mockService = VisionService(operations: mockOps)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let results = try await mockService.detectFaceRectangles(at: tempURL)
        XCTAssertEqual(results.count, 0)
    }

    /// 测试 recognizeAnimals nil results
    func testRecognizeAnimals_NilResults() async throws {
        let mockOps = MockVisionOperations(shouldReturnNilResults: true)
        let mockService = VisionService(operations: mockOps)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let results = try await mockService.recognizeAnimals(at: tempURL)
        XCTAssertEqual(results.count, 0)
    }

    /// 测试 detectHumanBodyPose nil results
    func testDetectHumanBodyPose_NilResults() async throws {
        let mockOps = MockVisionOperations(shouldReturnNilResults: true)
        let mockService = VisionService(operations: mockOps)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let results = try await mockService.detectHumanBodyPose(at: tempURL)
        XCTAssertEqual(results.count, 0)
    }

    /// 测试 detectHumanBodyPose3D nil results
    func testDetectHumanBodyPose3D_NilResults() async throws {
        let mockOps = MockVisionOperations(shouldReturnNilResults: true)
        let mockService = VisionService(operations: mockOps)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let results = try await mockService.detectHumanBodyPose3D(at: tempURL)
        XCTAssertEqual(results.count, 0)
    }

    /// 测试 detectHumanHandPose nil results
    func testDetectHumanHandPose_NilResults() async throws {
        let mockOps = MockVisionOperations(shouldReturnNilResults: true)
        let mockService = VisionService(operations: mockOps)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let results = try await mockService.detectHumanHandPose(at: tempURL)
        XCTAssertEqual(results.count, 0)
    }

    /// 测试 detectAnimalBodyPose nil results
    func testDetectAnimalBodyPose_NilResults() async throws {
        let mockOps = MockVisionOperations(shouldReturnNilResults: true)
        let mockService = VisionService(operations: mockOps)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let results = try await mockService.detectAnimalBodyPose(at: tempURL)
        XCTAssertEqual(results.count, 0)
    }

    /// 测试 performMultipleRequests nil results
    func testPerformMultipleRequests_NilResults() async throws {
        let mockOps = MockVisionOperations(shouldReturnNilResults: true)
        let mockService = VisionService(operations: mockOps)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let analysis = try await mockService.performMultipleRequests(at: tempURL)
        // 所有 results 都是 nil 时应该返回空数组
        XCTAssertEqual(analysis.classifications.count, 0)
        XCTAssertEqual(analysis.texts.count, 0)
        XCTAssertEqual(analysis.barcodes.count, 0)
    }

    /// 测试 classifyImage(at:) nil results（URL版本的 ?? [] 路径）
    func testClassifyImageURL_NilResults() async throws {
        let mockOps = MockVisionOperations(shouldReturnNilResults: true)
        let mockService = VisionService(operations: mockOps)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let results = try await mockService.classifyImage(at: tempURL)
        XCTAssertEqual(results.count, 0)
    }

    /// 测试 computeOpticalFlow CIImage 加载失败
    func testComputeOpticalFlow_InvalidImageFile() async throws {
        let service = VisionService()

        let tempURL1 = FileManager.default.temporaryDirectory.appendingPathComponent("test1.jpg")
        let tempURL2 = FileManager.default.temporaryDirectory.appendingPathComponent("invalid.txt")

        // 创建有效的源图片
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL1, format: "jpg")

        // 创建无效的目标文件（文本文件）
        try "invalid".write(to: tempURL2, atomically: true, encoding: .utf8)

        defer {
            try? FileManager.default.removeItem(at: tempURL1)
            try? FileManager.default.removeItem(at: tempURL2)
        }

        do {
            _ = try await service.computeOpticalFlow(from: tempURL1, to: tempURL2)
            XCTFail("应该抛出错误")
        } catch {
            guard case AirisError.imageDecodeFailed = error else {
                XCTFail("应该抛出 imageDecodeFailed")
                return
            }
        }
    }

    /// 测试 computeImageAlignment CIImage 加载失败
    func testComputeImageAlignment_InvalidImageFile() async throws {
        let service = VisionService()

        let tempURL1 = FileManager.default.temporaryDirectory.appendingPathComponent("test1.jpg")
        let tempURL2 = FileManager.default.temporaryDirectory.appendingPathComponent("invalid.txt")

        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL1, format: "jpg")
        try "invalid".write(to: tempURL2, atomically: true, encoding: .utf8)

        defer {
            try? FileManager.default.removeItem(at: tempURL1)
            try? FileManager.default.removeItem(at: tempURL2)
        }

        do {
            _ = try await service.computeImageAlignment(referenceURL: tempURL1, floatingURL: tempURL2)
            XCTFail("应该抛出错误")
        } catch {
            guard case AirisError.imageDecodeFailed = error else {
                XCTFail("应该抛出 imageDecodeFailed")
                return
            }
        }
    }

    /// 测试 computeOpticalFlow 空结果（results.first 为 nil）
    func testComputeOpticalFlow_NoResults() async throws {
        let mockOps = MockVisionOperations(shouldReturnEmptyResults: true)
        let mockService = VisionService(operations: mockOps)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        do {
            _ = try await mockService.computeOpticalFlow(from: tempURL, to: tempURL)
            XCTFail("应该抛出错误")
        } catch {
            guard case AirisError.noResultsFound = error else {
                XCTFail("应该抛出 noResultsFound")
                return
            }
        }
    }

    /// 测试 computeOpticalFlow 内部 perform 抛错触发 catch 分支
    func testComputeOpticalFlow_PerformThrows() async throws {
        final class ThrowingVisionOperations: VisionOperations {
            func perform(requests: [VNRequest], on handler: VNImageRequestHandler) throws {
                throw NSError(domain: "ThrowingOps", code: -2, userInfo: [NSLocalizedDescriptionKey: "forced throw"])
            }
        }

        let service = VisionService(operations: ThrowingVisionOperations())

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("flow_throw.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        do {
            _ = try await service.computeOpticalFlow(from: tempURL, to: tempURL)
            XCTFail("应该抛出错误")
        } catch {
            guard case AirisError.visionRequestFailed = error else {
                XCTFail("错误类型不符，期望 visionRequestFailed")
                return
            }
        }
    }

    /// 测试 computeImageAlignment 空结果
    func testComputeImageAlignment_NoResults() async throws {
        let mockOps = MockVisionOperations(shouldReturnEmptyResults: true)
        let mockService = VisionService(operations: mockOps)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        do {
            _ = try await mockService.computeImageAlignment(referenceURL: tempURL, floatingURL: tempURL)
            XCTFail("应该抛出错误")
        } catch {
            guard case AirisError.noResultsFound = error else {
                XCTFail("应该抛出 noResultsFound")
                return
            }
        }
    }

    /// 测试 generatePersonSegmentation 空结果
    func testGeneratePersonSegmentation_NoResults() async throws {
        let mockOps = MockVisionOperations(shouldReturnEmptyResults: true)
        let mockService = VisionService(operations: mockOps)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        do {
            _ = try await mockService.generatePersonSegmentation(at: tempURL)
            XCTFail("应该抛出错误")
        } catch {
            guard case AirisError.noResultsFound = error else {
                XCTFail("应该抛出 noResultsFound")
                return
            }
        }
    }

    /// 测试 detectSaliency 空结果（抛出 noResultsFound）
    func testDetectSaliency_NoResults() async throws {
        let mockOps = MockVisionOperations(shouldReturnEmptyResults: true)
        let mockService = VisionService(operations: mockOps)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
        let testImage = createTestCGImage()
        try ImageIOService().saveImage(testImage, to: tempURL, format: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        do {
            _ = try await mockService.detectSaliency(at: tempURL, type: .attention)
            XCTFail("应该抛出错误")
        } catch {
            guard case AirisError.noResultsFound = error else {
                XCTFail("应该抛出 noResultsFound")
                return
            }
        }
    }

    // MARK: - Helper Methods

    /// 创建测试用 CGImage
    private func createTestCGImage() -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(
            data: nil,
            width: 100,
            height: 100,
            bitsPerComponent: 8,
            bytesPerRow: 400,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        )!
        context.setFillColor(CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        return context.makeImage()!
    }
}
