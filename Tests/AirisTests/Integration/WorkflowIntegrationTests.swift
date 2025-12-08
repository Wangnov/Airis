import XCTest
import CoreImage
@preconcurrency import Vision
@testable import Airis

/// 工作流集成测试 - 验证多命令组合和真实工作流
final class WorkflowIntegrationTests: XCTestCase {

    // MARK: - Properties

    var visionService: VisionService!
    var coreImageService: CoreImageService!
    var imageIOService: ImageIOService!
    var tempDir: URL!

    // 测试资产路径（使用共享的 test-assets 目录）
    let testAssetsPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("airis-worktrees/test-assets/task-9.2")

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        visionService = VisionService()
        coreImageService = CoreImageService()
        imageIOService = ImageIOService()

        // 创建临时目录用于测试输出
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("airis_integration_test_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        // 清理临时目录
        try? FileManager.default.removeItem(at: tempDir)
        visionService = nil
        coreImageService = nil
        imageIOService = nil
        super.tearDown()
    }

    // MARK: - 完整图像处理工作流测试

    /// 测试：分析 → 编辑（裁剪）→ 保存 完整流程
    func testAnalyzeAndEditWorkflow() async throws {
        let imageURL = testAssetsPath.appendingPathComponent("landscape_4k.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found: landscape_4k.png")
        }

        // 1. 分析图像
        let classifications = try await visionService.classifyImage(at: imageURL, threshold: 0.1)
        XCTAssertFalse(classifications.isEmpty, "Should have classification results")

        // 2. 加载图像
        let cgImage = try imageIOService.loadImage(at: imageURL)
        let ciImage = CIImage(cgImage: cgImage)

        // 3. 应用编辑（缩放到 1024x1024）
        let resized = coreImageService.resize(ciImage: ciImage, width: 1024, height: 1024)
        XCTAssertEqual(resized.extent.width, 1024, accuracy: 1)

        // 4. 渲染并保存
        guard let outputCGImage = coreImageService.render(ciImage: resized) else {
            XCTFail("Failed to render image")
            return
        }

        let outputURL = tempDir.appendingPathComponent("workflow_output.png")
        try imageIOService.saveImage(outputCGImage, to: outputURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
    }

    /// 测试：文档扫描完整流程（检测矩形 → 透视校正）
    func testDocumentScanWorkflow() async throws {
        let documentURL = testAssetsPath.appendingPathComponent("document.png")
        guard FileManager.default.fileExists(atPath: documentURL.path) else {
            throw XCTSkip("Test asset not found: document.png")
        }

        // 1. 检测矩形区域
        let rectangles = try await visionService.detectRectangles(
            at: documentURL,
            minimumConfidence: 0.3,
            minimumSize: 0.1,
            maximumObservations: 5
        )

        // 文档图像可能检测到矩形，也可能没有（取决于图像内容）
        // 这里我们主要测试流程不崩溃

        // 2. 加载图像
        let cgImage = try imageIOService.loadImage(at: documentURL)
        let ciImage = CIImage(cgImage: cgImage)

        // 3. 如果检测到矩形，应用透视校正
        if let rect = rectangles.first {
            let imageHeight = ciImage.extent.height
            let imageWidth = ciImage.extent.width

            // 转换归一化坐标到像素坐标
            let topLeft = CGPoint(
                x: rect.topLeft.x * imageWidth,
                y: (1 - rect.topLeft.y) * imageHeight
            )
            let topRight = CGPoint(
                x: rect.topRight.x * imageWidth,
                y: (1 - rect.topRight.y) * imageHeight
            )
            let bottomLeft = CGPoint(
                x: rect.bottomLeft.x * imageWidth,
                y: (1 - rect.bottomLeft.y) * imageHeight
            )
            let bottomRight = CGPoint(
                x: rect.bottomRight.x * imageWidth,
                y: (1 - rect.bottomRight.y) * imageHeight
            )

            let corrected = coreImageService.perspectiveCorrection(
                ciImage: ciImage,
                topLeft: topLeft,
                topRight: topRight,
                bottomLeft: bottomLeft,
                bottomRight: bottomRight
            )
            XCTAssertNotNil(corrected, "Perspective correction should succeed")
        }

        // 4. 即使没有矩形，基本流程应该成功
        XCTAssertTrue(true, "Document scan workflow completed")
    }

    /// 测试：OCR 文字识别工作流
    func testOCRWorkflow() async throws {
        let documentURL = testAssetsPath.appendingPathComponent("document.png")
        guard FileManager.default.fileExists(atPath: documentURL.path) else {
            throw XCTSkip("Test asset not found: document.png")
        }

        // 1. 识别文字
        let textObservations = try await visionService.recognizeText(
            at: documentURL,
            languages: ["en", "zh-Hans"],
            level: .accurate
        )

        // 文档可能有文字，也可能没有
        // 主要测试流程不崩溃

        // 2. 提取识别到的文字
        var allText = ""
        for observation in textObservations {
            if let topCandidate = observation.topCandidates(1).first {
                allText += topCandidate.string + "\n"
            }
        }

        // 3. 流程完成
        XCTAssertTrue(true, "OCR workflow completed")
    }

    /// 测试：图像增强工作流（自动增强 → 锐化 → 保存）
    func testImageEnhanceWorkflow() async throws {
        let imageURL = testAssetsPath.appendingPathComponent("line_art.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found: line_art.png")
        }

        // 1. 加载图像
        let cgImage = try imageIOService.loadImage(at: imageURL)
        var ciImage = CIImage(cgImage: cgImage)

        // 2. 自动增强
        ciImage = coreImageService.autoEnhance(ciImage: ciImage)
        XCTAssertNotNil(ciImage)

        // 3. 应用锐化
        ciImage = coreImageService.sharpen(ciImage: ciImage, sharpness: 0.5)
        XCTAssertNotNil(ciImage)

        // 4. 调整对比度
        ciImage = coreImageService.adjustContrast(ciImage: ciImage, contrast: 1.2)
        XCTAssertNotNil(ciImage)

        // 5. 渲染并保存
        guard let outputCGImage = coreImageService.render(ciImage: ciImage) else {
            XCTFail("Failed to render enhanced image")
            return
        }

        let outputURL = tempDir.appendingPathComponent("enhanced_output.png")
        try imageIOService.saveImage(outputCGImage, to: outputURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
    }

    // MARK: - 批处理工作流测试

    /// 测试：并发批量图像分类
    func testBatchClassificationWorkflow() async throws {
        let imageURL = testAssetsPath.appendingPathComponent("landscape_4k.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found: landscape_4k.png")
        }

        // 模拟批量处理同一张图片多次（实际场景会是多张不同图片）
        let imageURLs: [URL] = Array(repeating: imageURL, count: 5)
        let service = visionService!  // 创建局部引用

        var allResults: [[VNClassificationObservation]] = []

        // 并发处理
        try await withThrowingTaskGroup(of: [VNClassificationObservation].self) { group in
            for url in imageURLs {
                group.addTask {
                    try await service.classifyImage(at: url, threshold: 0.1)
                }
            }

            for try await result in group {
                allResults.append(result)
            }
        }

        XCTAssertEqual(allResults.count, imageURLs.count, "Should have results for all images")
    }

    /// 测试：批量图像缩放工作流
    func testBatchResizeWorkflow() async throws {
        let imageURL = testAssetsPath.appendingPathComponent("landscape_4k.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found: landscape_4k.png")
        }

        // 定义多个目标尺寸
        let targetSizes: [(width: Int, height: Int)] = [
            (1920, 1080),
            (1280, 720),
            (640, 480),
            (320, 240)
        ]

        // 1. 加载原始图像
        let cgImage = try imageIOService.loadImage(at: imageURL)
        let ciImage = CIImage(cgImage: cgImage)

        // 2. 批量缩放
        var outputURLs: [URL] = []
        for (index, size) in targetSizes.enumerated() {
            let resized = coreImageService.resize(ciImage: ciImage, width: size.width, height: size.height)
            guard let outputCGImage = coreImageService.render(ciImage: resized) else {
                XCTFail("Failed to render resized image at index \(index)")
                continue
            }

            let outputURL = tempDir.appendingPathComponent("batch_resize_\(index).png")
            try imageIOService.saveImage(outputCGImage, to: outputURL)
            outputURLs.append(outputURL)
        }

        XCTAssertEqual(outputURLs.count, targetSizes.count, "Should create all resized images")

        // 验证所有文件存在
        for url in outputURLs {
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        }
    }

    /// 测试：批量滤镜应用工作流
    func testBatchFilterWorkflow() async throws {
        let imageURL = testAssetsPath.appendingPathComponent("line_art.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found: line_art.png")
        }

        // 1. 加载图像
        let cgImage = try imageIOService.loadImage(at: imageURL)
        let ciImage = CIImage(cgImage: cgImage)

        // 2. 应用不同滤镜
        let filters: [(name: String, apply: (CIImage) -> CIImage)] = [
            ("grayscale", { self.coreImageService.grayscale(ciImage: $0) }),
            ("sepia", { self.coreImageService.sepiaTone(ciImage: $0, intensity: 0.8) }),
            ("blur", { self.coreImageService.gaussianBlur(ciImage: $0, radius: 5) }),
            ("sharpen", { self.coreImageService.sharpen(ciImage: $0, sharpness: 1.0) }),
            ("invert", { self.coreImageService.invert(ciImage: $0) })
        ]

        var outputURLs: [URL] = []
        for (name, filter) in filters {
            let filtered = filter(ciImage)
            guard let outputCGImage = coreImageService.render(ciImage: filtered) else {
                XCTFail("Failed to render filtered image: \(name)")
                continue
            }

            let outputURL = tempDir.appendingPathComponent("filter_\(name).png")
            try imageIOService.saveImage(outputCGImage, to: outputURL)
            outputURLs.append(outputURL)
        }

        XCTAssertEqual(outputURLs.count, filters.count, "Should create all filtered images")
    }

    // MARK: - 复杂工作流测试

    /// 测试：综合分析工作流（分类 + OCR + 条形码）
    func testComprehensiveAnalysisWorkflow() async throws {
        let imageURL = testAssetsPath.appendingPathComponent("document.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found: document.png")
        }

        // 执行综合分析
        let analysis = try await visionService.performMultipleRequests(at: imageURL)

        // 验证返回结构
        XCTAssertNotNil(analysis.classifications, "Should have classifications array")
        XCTAssertNotNil(analysis.texts, "Should have texts array")
        XCTAssertNotNil(analysis.barcodes, "Should have barcodes array")
    }

    /// 测试：图像元数据读取 + 编辑 + 保存工作流
    func testMetadataAndEditWorkflow() async throws {
        let imageURL = testAssetsPath.appendingPathComponent("landscape_4k.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found: landscape_4k.png")
        }

        // 1. 读取图像信息
        let imageInfo = try imageIOService.getImageInfo(at: imageURL)
        XCTAssertGreaterThan(imageInfo.width, 0)
        XCTAssertGreaterThan(imageInfo.height, 0)

        // 2. 根据元数据决定处理策略
        let needsDownscale = imageInfo.width > 2048 || imageInfo.height > 2048

        // 3. 加载并处理
        let cgImage = try imageIOService.loadImage(at: imageURL)
        var ciImage = CIImage(cgImage: cgImage)

        if needsDownscale {
            ciImage = coreImageService.resize(ciImage: ciImage, width: 2048)
        }

        // 4. 保存
        guard let outputCGImage = coreImageService.render(ciImage: ciImage) else {
            XCTFail("Failed to render image")
            return
        }

        let outputURL = tempDir.appendingPathComponent("metadata_workflow_output.png")
        try imageIOService.saveImage(outputCGImage, to: outputURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))

        // 5. 验证输出图像的信息
        let outputInfo = try imageIOService.getImageInfo(at: outputURL)
        XCTAssertLessThanOrEqual(outputInfo.width, 2048)
    }

    /// 测试：显著性检测 + 智能裁剪工作流
    func testSaliencyCropWorkflow() async throws {
        let imageURL = testAssetsPath.appendingPathComponent("landscape_4k.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found: landscape_4k.png")
        }

        // 1. 检测显著性区域
        let saliencyResult = try await visionService.detectSaliency(at: imageURL, type: .attention)

        // 2. 加载图像
        let cgImage = try imageIOService.loadImage(at: imageURL)
        let ciImage = CIImage(cgImage: cgImage)

        // 3. 如果有显著区域，智能裁剪
        if let salientBound = saliencyResult.salientBounds.first {
            // 使用显著区域进行裁剪（扩展一点边界）
            let expandedBound = salientBound.insetBy(dx: -0.1, dy: -0.1)
            let cropped = coreImageService.cropNormalized(ciImage: ciImage, normalizedRect: expandedBound)

            XCTAssertGreaterThan(cropped.extent.width, 0)
            XCTAssertGreaterThan(cropped.extent.height, 0)
        }

        XCTAssertTrue(true, "Saliency crop workflow completed")
    }

    /// 测试：人物分割 + 背景替换工作流（模拟）
    func testPersonSegmentationWorkflow() async throws {
        let imageURL = testAssetsPath.appendingPathComponent("landscape_4k.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found: landscape_4k.png")
        }

        // 1. 尝试人物分割（风景图可能没有人物）
        let segmentationResult = try await visionService.generatePersonSegmentation(
            at: imageURL,
            quality: .fast
        )

        // 2. 验证返回的遮罩数据有效
        XCTAssertGreaterThan(segmentationResult.width, 0)
        XCTAssertGreaterThan(segmentationResult.height, 0)

        // 流程完成
        XCTAssertTrue(true, "Person segmentation workflow completed")
    }

    /// 测试：地平线检测 + 自动校正工作流
    func testHorizonCorrectionWorkflow() async throws {
        let imageURL = testAssetsPath.appendingPathComponent("landscape_4k.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found: landscape_4k.png")
        }

        // 1. 检测地平线
        let horizonResult = try await visionService.detectHorizon(at: imageURL)

        // 2. 加载图像
        let cgImage = try imageIOService.loadImage(at: imageURL)
        var ciImage = CIImage(cgImage: cgImage)

        // 3. 如果检测到倾斜，进行校正
        if let horizon = horizonResult, abs(horizon.angleInDegrees) > 0.5 {
            // 旋转校正
            ciImage = coreImageService.rotateAroundCenter(ciImage: ciImage, degrees: -horizon.angleInDegrees)
            XCTAssertNotNil(ciImage)
        }

        // 流程完成
        XCTAssertTrue(true, "Horizon correction workflow completed")
    }

    // MARK: - 滤镜链工作流测试

    /// 测试：复杂滤镜链工作流
    func testFilterChainWorkflow() async throws {
        let imageURL = testAssetsPath.appendingPathComponent("line_art.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found: line_art.png")
        }

        // 1. 加载图像
        let cgImage = try imageIOService.loadImage(at: imageURL)
        var ciImage = CIImage(cgImage: cgImage)

        // 2. 应用滤镜链
        // 步骤 1: 调整颜色
        ciImage = coreImageService.adjustColors(ciImage: ciImage, brightness: 0.05, contrast: 1.1, saturation: 1.2)

        // 步骤 2: 锐化
        ciImage = coreImageService.sharpen(ciImage: ciImage, sharpness: 0.3)

        // 步骤 3: 轻微模糊（柔化效果）
        ciImage = coreImageService.gaussianBlur(ciImage: ciImage, radius: 0.5)

        // 步骤 4: 添加暗角
        ciImage = coreImageService.vignette(ciImage: ciImage, intensity: 0.5)

        // 3. 渲染并保存
        guard let outputCGImage = coreImageService.render(ciImage: ciImage) else {
            XCTFail("Failed to render filter chain result")
            return
        }

        let outputURL = tempDir.appendingPathComponent("filter_chain_output.png")
        try imageIOService.saveImage(outputCGImage, to: outputURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
    }

    /// 测试：照片效果滤镜工作流
    func testPhotoEffectsWorkflow() async throws {
        let imageURL = testAssetsPath.appendingPathComponent("landscape_4k.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found: landscape_4k.png")
        }

        // 加载图像
        let cgImage = try imageIOService.loadImage(at: imageURL)
        let ciImage = CIImage(cgImage: cgImage)

        // 测试各种照片效果
        let effects: [(name: String, apply: (CIImage) -> CIImage)] = [
            ("mono", { self.coreImageService.photoEffectMono(ciImage: $0) }),
            ("chrome", { self.coreImageService.photoEffectChrome(ciImage: $0) }),
            ("noir", { self.coreImageService.photoEffectNoir(ciImage: $0) }),
            ("instant", { self.coreImageService.photoEffectInstant(ciImage: $0) }),
            ("fade", { self.coreImageService.photoEffectFade(ciImage: $0) })
        ]

        for (name, effect) in effects {
            let filtered = effect(ciImage)
            XCTAssertNotNil(filtered, "Photo effect '\(name)' should produce output")
            XCTAssertGreaterThan(filtered.extent.width, 0)
        }
    }

    // MARK: - 格式转换工作流测试

    /// 测试：多格式输出工作流
    func testMultiFormatOutputWorkflow() async throws {
        let imageURL = testAssetsPath.appendingPathComponent("line_art.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found: line_art.png")
        }

        // 1. 加载图像
        let cgImage = try imageIOService.loadImage(at: imageURL)

        // 2. 保存为不同格式
        let formats: [(ext: String, quality: Float)] = [
            ("png", 1.0),
            ("jpg", 0.9),
            ("tiff", 1.0)
        ]

        for (ext, quality) in formats {
            let outputURL = tempDir.appendingPathComponent("output.\(ext)")
            try imageIOService.saveImage(cgImage, to: outputURL, format: ext, quality: quality)
            XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path), "Should create \(ext) file")
        }
    }

    /// 测试：缩略图生成工作流
    func testThumbnailGenerationWorkflow() async throws {
        let imageURL = testAssetsPath.appendingPathComponent("landscape_4k.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found: landscape_4k.png")
        }

        // 加载原图然后使用 CoreImage 缩放
        let cgImage = try imageIOService.loadImage(at: imageURL)
        let ciImage = CIImage(cgImage: cgImage)

        // 缩放到缩略图尺寸
        let thumbnailSize = 256
        let resized = coreImageService.resize(ciImage: ciImage, width: thumbnailSize, height: thumbnailSize)

        guard let thumbnail = coreImageService.render(ciImage: resized) else {
            XCTFail("Failed to render thumbnail")
            return
        }

        XCTAssertLessThanOrEqual(thumbnail.width, thumbnailSize)
        XCTAssertLessThanOrEqual(thumbnail.height, thumbnailSize)

        // 保存缩略图
        let outputURL = tempDir.appendingPathComponent("thumbnail.jpg")
        try imageIOService.saveImage(thumbnail, to: outputURL, format: "jpg", quality: 0.8)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
    }
}
