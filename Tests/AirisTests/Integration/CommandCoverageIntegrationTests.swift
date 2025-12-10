import XCTest
import CoreImage
@preconcurrency import Vision
@testable import Airis

/// 命令功能完整性集成测试 - 确保所有命令底层服务都被测试覆盖
final class CommandCoverageIntegrationTests: XCTestCase {

    // ✅ Apple 最佳实践：类级别共享服务
    static let sharedVisionService = VisionService()
    static let sharedCoreImageService = CoreImageService()
    static let sharedImageIOService = ImageIOService()


    // MARK: - Properties

    var visionService: VisionService!
    var coreImageService: CoreImageService!
    var imageIOService: ImageIOService!
    var tempDir: URL!

    // 内置测试资源路径
    static let resourcePath = "Tests/Resources/images"

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        visionService = Self.sharedVisionService
        coreImageService = Self.sharedCoreImageService
        imageIOService = Self.sharedImageIOService

        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("airis_coverage_test_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        visionService = nil
        coreImageService = nil
        imageIOService = nil
        super.tearDown()
    }

    // MARK: - Vision Commands 覆盖测试

    /// 测试：Animal 命令 - 动物识别
    func testAnimalRecognition() async throws {
        let imageURL = URL(fileURLWithPath: Self.resourcePath + "/landscape.jpg")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found")
        }

        let results = try await visionService.recognizeAnimals(at: imageURL)
        // 风景图可能没有动物，但流程应该完成
        XCTAssertNotNil(results)
    }

    /// 测试：Face 命令 - 人脸特征点检测
    func testFaceLandmarksDetection() async throws {
        let imageURL = URL(fileURLWithPath: Self.resourcePath + "/landscape.jpg")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found")
        }

        let results = try await visionService.detectFaceLandmarks(at: imageURL)
        // 风景图没有人脸
        XCTAssertNotNil(results)
    }

    /// 测试：Pose 命令 - 人体姿态检测
    func testHumanBodyPoseDetection() async throws {
        let imageURL = URL(fileURLWithPath: Self.resourcePath + "/landscape.jpg")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found")
        }

        let results = try await visionService.detectHumanBodyPose(at: imageURL)
        XCTAssertNotNil(results)
    }

    /// 测试：Pose3D 命令 - 3D 人体姿态检测
    func testHumanBodyPose3DDetection() async throws {
        let imageURL = URL(fileURLWithPath: Self.resourcePath + "/landscape.jpg")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found")
        }

        let results = try await visionService.detectHumanBodyPose3D(at: imageURL)
        XCTAssertNotNil(results)
    }

    /// 测试：Hand 命令 - 手部姿态检测
    func testHumanHandPoseDetection() async throws {
        let imageURL = URL(fileURLWithPath: Self.resourcePath + "/landscape.jpg")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found")
        }

        let results = try await visionService.detectHumanHandPose(at: imageURL, maximumHandCount: 2)
        XCTAssertNotNil(results)
    }

    /// 测试：PetPose 命令 - 动物姿态检测
    func testAnimalBodyPoseDetection() async throws {
        let imageURL = URL(fileURLWithPath: Self.resourcePath + "/landscape.jpg")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found")
        }

        let results = try await visionService.detectAnimalBodyPose(at: imageURL)
        XCTAssertNotNil(results)
    }

    /// 测试：Flow 命令 - 光流计算
    func testOpticalFlowComputation() async throws {
        let imageURL = URL(fileURLWithPath: Self.resourcePath + "/landscape.jpg")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found")
        }

        // 光流需要两张图片，这里用同一张测试
        let result = try await visionService.computeOpticalFlow(
            from: imageURL,
            to: imageURL,
            accuracy: .medium
        )
        XCTAssertNotNil(result)
    }

    /// 测试：Align 命令 - 图像对齐
    func testImageAlignment() async throws {
        let imageURL = URL(fileURLWithPath: Self.resourcePath + "/landscape.jpg")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found")
        }

        // 图像对齐需要两张图片
        let result = try await visionService.computeImageAlignment(
            referenceURL: imageURL,
            floatingURL: imageURL
        )
        XCTAssertNotNil(result)
    }

    /// 测试：前景遮罩生成
    func testForegroundMaskGeneration() async throws {
        let imageURL = URL(fileURLWithPath: Self.resourcePath + "/landscape.jpg")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found")
        }

        // 风景图可能没有明显的前景对象，可能会抛出 noResultsFound
        do {
            let mask = try await visionService.generateForegroundMask(at: imageURL)
            XCTAssertGreaterThan(mask.extent.width, 0)
        } catch AirisError.noResultsFound {
            // 预期行为：风景图可能没有可分割的前景
            XCTAssertTrue(true, "No foreground found in landscape image, which is expected")
        }
    }

    // MARK: - Edit Commands 覆盖测试

    /// 测试：Rotate 命令 - 图像旋转
    func testImageRotation() throws {
        let imageURL = URL(fileURLWithPath: Self.resourcePath + "/line_art.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found")
        }

        let cgImage = try imageIOService.loadImage(at: imageURL)
        let ciImage = CIImage(cgImage: cgImage)

        // 测试各种旋转角度
        let rotated90 = coreImageService.rotate(ciImage: ciImage, degrees: 90)
        let rotated180 = coreImageService.rotateAroundCenter(ciImage: ciImage, degrees: 180)
        let rotated45 = coreImageService.rotateAroundCenter(ciImage: ciImage, degrees: 45)

        XCTAssertNotNil(rotated90)
        XCTAssertNotNil(rotated180)
        XCTAssertNotNil(rotated45)
    }

    /// 测试：Flip 命令 - 图像翻转
    func testImageFlip() throws {
        let imageURL = URL(fileURLWithPath: Self.resourcePath + "/line_art.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found")
        }

        let cgImage = try imageIOService.loadImage(at: imageURL)
        let ciImage = CIImage(cgImage: cgImage)

        let flippedH = coreImageService.flip(ciImage: ciImage, horizontal: true)
        let flippedV = coreImageService.flip(ciImage: ciImage, vertical: true)
        let flippedBoth = coreImageService.flip(ciImage: ciImage, horizontal: true, vertical: true)

        XCTAssertNotNil(flippedH)
        XCTAssertNotNil(flippedV)
        XCTAssertNotNil(flippedBoth)
    }

    /// 测试：Blur 命令 - 各种模糊效果
    func testBlurEffects() throws {
        let imageURL = URL(fileURLWithPath: Self.resourcePath + "/line_art.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found")
        }

        let cgImage = try imageIOService.loadImage(at: imageURL)
        let ciImage = CIImage(cgImage: cgImage)

        // 高斯模糊
        let gaussianBlurred = coreImageService.gaussianBlur(ciImage: ciImage, radius: 10)
        XCTAssertNotNil(gaussianBlurred)

        // 运动模糊
        let motionBlurred = coreImageService.motionBlur(ciImage: ciImage, radius: 10, angle: 45)
        XCTAssertNotNil(motionBlurred)

        // 缩放模糊
        let zoomBlurred = coreImageService.zoomBlur(ciImage: ciImage, amount: 10)
        XCTAssertNotNil(zoomBlurred)
    }

    /// 测试：Noise 命令 - 降噪
    func testNoiseReduction() throws {
        let imageURL = URL(fileURLWithPath: Self.resourcePath + "/line_art.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found")
        }

        let cgImage = try imageIOService.loadImage(at: imageURL)
        let ciImage = CIImage(cgImage: cgImage)

        let denoised = coreImageService.noiseReduction(ciImage: ciImage, noiseLevel: 0.02, sharpness: 0.4)
        XCTAssertNotNil(denoised)
    }

    /// 测试：Pixel 命令 - 像素化
    func testPixellate() throws {
        let imageURL = URL(fileURLWithPath: Self.resourcePath + "/line_art.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found")
        }

        let cgImage = try imageIOService.loadImage(at: imageURL)
        let ciImage = CIImage(cgImage: cgImage)

        let pixellated = coreImageService.pixellate(ciImage: ciImage, scale: 10)
        XCTAssertNotNil(pixellated)
    }

    /// 测试：Comic 命令 - 漫画效果
    func testComicEffect() throws {
        let imageURL = URL(fileURLWithPath: Self.resourcePath + "/line_art.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found")
        }

        let cgImage = try imageIOService.loadImage(at: imageURL)
        let ciImage = CIImage(cgImage: cgImage)

        let comic = coreImageService.comicEffect(ciImage: ciImage)
        XCTAssertNotNil(comic)
    }

    /// 测试：Halftone 命令 - 半色调效果
    func testHalftoneEffect() throws {
        let imageURL = URL(fileURLWithPath: Self.resourcePath + "/line_art.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found")
        }

        let cgImage = try imageIOService.loadImage(at: imageURL)
        let ciImage = CIImage(cgImage: cgImage)

        let halftone = coreImageService.halftone(ciImage: ciImage, width: 6, angle: 0, sharpness: 0.7)
        XCTAssertNotNil(halftone)
    }

    /// 测试：Exposure 命令 - 曝光调整
    func testExposureAdjustment() throws {
        let imageURL = URL(fileURLWithPath: Self.resourcePath + "/line_art.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found")
        }

        let cgImage = try imageIOService.loadImage(at: imageURL)
        let ciImage = CIImage(cgImage: cgImage)

        let adjusted = coreImageService.adjustExposure(ciImage: ciImage, ev: 1.0)
        XCTAssertNotNil(adjusted)
    }

    /// 测试：Temperature 命令 - 色温调整
    func testTemperatureAdjustment() throws {
        let imageURL = URL(fileURLWithPath: Self.resourcePath + "/line_art.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found")
        }

        let cgImage = try imageIOService.loadImage(at: imageURL)
        let ciImage = CIImage(cgImage: cgImage)

        let adjusted = coreImageService.adjustTemperatureAndTint(ciImage: ciImage, temperature: 1000, tint: 0)
        XCTAssertNotNil(adjusted)
    }

    /// 测试：Posterize 命令 - 色调分离
    func testPosterize() throws {
        let imageURL = URL(fileURLWithPath: Self.resourcePath + "/line_art.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found")
        }

        let cgImage = try imageIOService.loadImage(at: imageURL)
        let ciImage = CIImage(cgImage: cgImage)

        let posterized = coreImageService.posterize(ciImage: ciImage, levels: 6)
        XCTAssertNotNil(posterized)
    }

    /// 测试：Threshold 命令 - 阈值化
    func testThreshold() throws {
        let imageURL = URL(fileURLWithPath: Self.resourcePath + "/line_art.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found")
        }

        let cgImage = try imageIOService.loadImage(at: imageURL)
        let ciImage = CIImage(cgImage: cgImage)

        let thresholded = coreImageService.threshold(ciImage: ciImage, threshold: 0.5)
        XCTAssertNotNil(thresholded)
    }

    /// 测试：Defringe 命令 - 去紫边
    func testDefringe() throws {
        let imageURL = URL(fileURLWithPath: Self.resourcePath + "/line_art.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found")
        }

        let cgImage = try imageIOService.loadImage(at: imageURL)
        let ciImage = CIImage(cgImage: cgImage)

        let defringed = coreImageService.defringe(ciImage: ciImage, amount: 0.5)
        XCTAssertNotNil(defringed)
    }

    /// 测试：Trace 命令 - 线条追踪
    func testLineOverlay() throws {
        let imageURL = URL(fileURLWithPath: Self.resourcePath + "/line_art.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found")
        }

        let cgImage = try imageIOService.loadImage(at: imageURL)
        let ciImage = CIImage(cgImage: cgImage)

        let traced = coreImageService.lineOverlay(ciImage: ciImage)
        XCTAssertNotNil(traced)
    }

    /// 测试：边缘检测
    func testEdgeDetection() throws {
        let imageURL = URL(fileURLWithPath: Self.resourcePath + "/line_art.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found")
        }

        let cgImage = try imageIOService.loadImage(at: imageURL)
        let ciImage = CIImage(cgImage: cgImage)

        let edges = coreImageService.edges(ciImage: ciImage, intensity: 1.0)
        XCTAssertNotNil(edges)

        let edgeWork = coreImageService.edgeWork(ciImage: ciImage, radius: 3.0)
        XCTAssertNotNil(edgeWork)
    }

    /// 测试：Photo Effect Process 和 Transfer
    func testPhotoEffectsProcessAndTransfer() throws {
        let imageURL = URL(fileURLWithPath: Self.resourcePath + "/line_art.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found")
        }

        let cgImage = try imageIOService.loadImage(at: imageURL)
        let ciImage = CIImage(cgImage: cgImage)

        let process = coreImageService.photoEffectProcess(ciImage: ciImage)
        let transfer = coreImageService.photoEffectTransfer(ciImage: ciImage)

        XCTAssertNotNil(process)
        XCTAssertNotNil(transfer)
    }

    /// 测试：Unsharp Mask 锐化
    func testUnsharpMask() throws {
        let imageURL = URL(fileURLWithPath: Self.resourcePath + "/line_art.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found")
        }

        let cgImage = try imageIOService.loadImage(at: imageURL)
        let ciImage = CIImage(cgImage: cgImage)

        let sharpened = coreImageService.unsharpMask(ciImage: ciImage, radius: 2.5, intensity: 0.5)
        XCTAssertNotNil(sharpened)
    }

    // MARK: - Analyze Commands 覆盖测试

    /// 测试：Info 命令 - 图像信息
    func testImageInfo() throws {
        let imageURL = URL(fileURLWithPath: Self.resourcePath + "/landscape.jpg")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found")
        }

        let info = try imageIOService.getImageInfo(at: imageURL)
        XCTAssertGreaterThan(info.width, 0)
        XCTAssertGreaterThan(info.height, 0)
        XCTAssertGreaterThan(info.dpiWidth, 0)
        XCTAssertGreaterThan(info.dpiHeight, 0)
    }

    /// 测试：Meta 命令 - 图像元数据
    func testImageMetadata() throws {
        let imageURL = URL(fileURLWithPath: Self.resourcePath + "/landscape.jpg")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found")
        }

        let metadata = try imageIOService.loadImageMetadata(at: imageURL)
        XCTAssertFalse(metadata.isEmpty)
    }

    /// 测试：Format 命令 - 格式检测
    func testImageFormat() throws {
        let imageURL = URL(fileURLWithPath: Self.resourcePath + "/line_art.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found")
        }

        let format = try imageIOService.getImageFormat(at: imageURL)
        // ImageIO 返回的格式标识符可能是 "public.png" 或其他形式
        // 只需要验证能正确获取格式
        XCTAssertFalse(format.isEmpty, "Format should not be empty")
    }

    /// 测试：图像帧数检测（GIF 等）
    func testImageFrameCount() throws {
        let imageURL = URL(fileURLWithPath: Self.resourcePath + "/line_art.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found")
        }

        let frameCount = try imageIOService.getImageFrameCount(at: imageURL)
        XCTAssertGreaterThanOrEqual(frameCount, 1)
    }

    // MARK: - 综合工作流测试

    /// 测试：完整的照片编辑工作流（覆盖多个 Adjust 命令）
    func testCompletePhotoAdjustmentWorkflow() throws {
        let imageURL = URL(fileURLWithPath: Self.resourcePath + "/landscape.jpg")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found")
        }

        let cgImage = try imageIOService.loadImage(at: imageURL)
        var ciImage = CIImage(cgImage: cgImage)

        // 曝光
        ciImage = coreImageService.adjustExposure(ciImage: ciImage, ev: 0.5)
        // 亮度
        ciImage = coreImageService.adjustBrightness(ciImage: ciImage, brightness: 0.05)
        // 对比度
        ciImage = coreImageService.adjustContrast(ciImage: ciImage, contrast: 1.1)
        // 饱和度
        ciImage = coreImageService.adjustSaturation(ciImage: ciImage, saturation: 1.1)
        // 色温
        ciImage = coreImageService.adjustTemperatureAndTint(ciImage: ciImage, temperature: 200, tint: 0)
        // 锐化
        ciImage = coreImageService.sharpen(ciImage: ciImage, sharpness: 0.3)
        // 暗角
        ciImage = coreImageService.vignette(ciImage: ciImage, intensity: 0.3)

        guard let output = coreImageService.render(ciImage: ciImage) else {
            XCTFail("Failed to render")
            return
        }

        let outputURL = tempDir.appendingPathComponent("adjusted.png")
        try imageIOService.saveImage(output, to: outputURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
    }

    /// 测试：完整的艺术效果工作流（覆盖多个 Filter 命令）
    func testCompleteArtisticEffectsWorkflow() throws {
        let imageURL = URL(fileURLWithPath: Self.resourcePath + "/line_art.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found")
        }

        let cgImage = try imageIOService.loadImage(at: imageURL)
        let ciImage = CIImage(cgImage: cgImage)

        // 测试各种艺术效果
        let effects: [(String, CIImage)] = [
            ("comic", coreImageService.comicEffect(ciImage: ciImage)),
            ("halftone", coreImageService.halftone(ciImage: ciImage)),
            ("pixellate", coreImageService.pixellate(ciImage: ciImage)),
            ("posterize", coreImageService.posterize(ciImage: ciImage)),
            ("edges", coreImageService.edges(ciImage: ciImage) ?? ciImage),
            ("lineOverlay", coreImageService.lineOverlay(ciImage: ciImage))
        ]

        for (name, filtered) in effects {
            guard let output = coreImageService.render(ciImage: filtered) else {
                XCTFail("Failed to render \(name)")
                continue
            }
            let outputURL = tempDir.appendingPathComponent("artistic_\(name).png")
            try imageIOService.saveImage(output, to: outputURL)
            XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
        }
    }

    /// 测试：完整的 Vision 分析工作流（覆盖多个 Detect 命令）
    func testCompleteVisionAnalysisWorkflow() async throws {
        let imageURL = URL(fileURLWithPath: Self.resourcePath + "/vision/document.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found")
        }

        let service = try XCTUnwrap(visionService)

        // 顺序执行所有检测
        let classifications = try await service.classifyImage(at: imageURL)
        let texts = try await service.recognizeText(at: imageURL)
        let barcodes = try await service.detectBarcodes(at: imageURL)
        let faces = try await service.detectFaceRectangles(at: imageURL)
        let rectangles = try await service.detectRectangles(at: imageURL)
        let saliency = try await service.detectSaliency(at: imageURL)

        // 验证所有分析都完成（不关心具体结果）
        XCTAssertNotNil(classifications)
        XCTAssertNotNil(texts)
        XCTAssertNotNil(barcodes)
        XCTAssertNotNil(faces)
        XCTAssertNotNil(rectangles)
        XCTAssertNotNil(saliency)
    }

    /// 测试：CoreImageService 的工具方法
    func testCoreImageServiceUtilities() throws {
        // 测试坐标转换
        let testRect = CGRect(x: 100, y: 200, width: 300, height: 400)
        let imageHeight: CGFloat = 1000

        let ciRect = CoreImageService.convertVisionToCI(rect: testRect, imageHeight: imageHeight)
        let backToVision = CoreImageService.convertCIToVision(rect: ciRect, imageHeight: imageHeight)

        XCTAssertEqual(testRect.origin.x, backToVision.origin.x, accuracy: 0.001)
        XCTAssertEqual(testRect.width, backToVision.width, accuracy: 0.001)
        XCTAssertEqual(testRect.height, backToVision.height, accuracy: 0.001)

        // 测试 Metal 加速状态
        XCTAssertNotNil(coreImageService.isUsingMetalAcceleration)

        // 测试最大尺寸
        let maxInput = coreImageService.maxInputImageSize()
        let maxOutput = coreImageService.maxOutputImageSize()
        XCTAssertGreaterThan(maxInput.width, 0)
        XCTAssertGreaterThan(maxOutput.width, 0)
    }

    /// 测试：自动增强滤镜信息获取
    func testAutoEnhanceFilterInfo() throws {
        let imageURL = URL(fileURLWithPath: Self.resourcePath + "/line_art.png")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw XCTSkip("Test asset not found")
        }

        let cgImage = try imageIOService.loadImage(at: imageURL)
        let ciImage = CIImage(cgImage: cgImage)

        let filterNames = coreImageService.getAutoEnhanceFilters(for: ciImage)
        // 可能返回空数组，但不应崩溃
        XCTAssertNotNil(filterNames)
    }
}
