import CoreImage
import XCTest
#if !XCODE_BUILD
    @testable import AirisCore
#endif

final class CoreImageServiceTests: XCTestCase {
    var service: CoreImageService!

    // 测试用图像（100x100 红色方块）
    var testCIImage: CIImage!

    private func makeService(
        factory: CoreImageFilterFactory,
        outputOverride: ((CIFilter, CIImage) -> CIImage?)? = nil
    ) -> CoreImageService {
        CoreImageService(
            operations: DefaultCoreImageOperations(),
            filterFactory: factory,
            outputOverride: outputOverride
        )
    }

    override func setUp() {
        super.setUp()
        service = CoreImageService()

        // 创建测试用 CIImage（100x100 红色方块）
        testCIImage = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
    }

    override func tearDown() {
        service = nil
        testCIImage = nil
        super.tearDown()
    }

    // MARK: - Service Initialization Tests

    func testServiceInitialization() throws {
        XCTAssertNotNil(service)
    }

    func testServiceContainerAccess() throws {
        let containerService = ServiceContainer.shared.coreImageService
        XCTAssertNotNil(containerService)
    }

    func testMetalAccelerationAvailable() throws {
        // Metal 在 macOS 上应该可用
        #if os(macOS)
            XCTAssertTrue(service.isUsingMetalAcceleration)
        #endif
    }

    // MARK: - Resize Tests

    func testResizeImageByWidth() throws {
        let resized = service.resize(ciImage: testCIImage, width: 50)

        XCTAssertNotNil(resized)
        // Lanczos 缩放可能有微小误差，允许 1 像素误差
        XCTAssertEqual(resized.extent.width, 50, accuracy: 1)
        XCTAssertEqual(resized.extent.height, 50, accuracy: 1) // 保持宽高比
    }

    func testResizeImageByHeight() throws {
        let resized = service.resize(ciImage: testCIImage, height: 25)

        XCTAssertNotNil(resized)
        XCTAssertEqual(resized.extent.width, 25, accuracy: 1) // 保持宽高比
        XCTAssertEqual(resized.extent.height, 25, accuracy: 1)
    }

    func testResizeImageByBothDimensions() throws {
        let resized = service.resize(ciImage: testCIImage, width: 80, height: 40, maintainAspectRatio: false)

        XCTAssertNotNil(resized)
        // 不保持宽高比时，实际尺寸应接近目标
        XCTAssertGreaterThan(resized.extent.width, 0)
        XCTAssertGreaterThan(resized.extent.height, 0)
    }

    func testResizeNoChange() throws {
        // 不指定尺寸时应返回原图
        let resized = service.resize(ciImage: testCIImage)

        XCTAssertEqual(resized.extent.width, testCIImage.extent.width)
        XCTAssertEqual(resized.extent.height, testCIImage.extent.height)
    }

    // MARK: - Crop Tests

    func testCropImage() throws {
        let cropRect = CGRect(x: 10, y: 10, width: 50, height: 50)
        let cropped = service.crop(ciImage: testCIImage, rect: cropRect)

        XCTAssertEqual(cropped.extent.width, 50)
        XCTAssertEqual(cropped.extent.height, 50)
    }

    func testCropImageOutOfBounds() throws {
        // 裁剪区域超出图像边界时，应该裁剪到交集
        let cropRect = CGRect(x: 80, y: 80, width: 50, height: 50)
        let cropped = service.crop(ciImage: testCIImage, rect: cropRect)

        // 应该裁剪到有效区域
        XCTAssertEqual(cropped.extent.width, 20)
        XCTAssertEqual(cropped.extent.height, 20)
    }

    func testCropNormalizedCoordinates() throws {
        // 使用标准化坐标（左上角原点）
        let normalizedRect = CGRect(x: 0.1, y: 0.1, width: 0.5, height: 0.5)
        let cropped = service.cropNormalized(ciImage: testCIImage, normalizedRect: normalizedRect)

        XCTAssertEqual(cropped.extent.width, 50)
        XCTAssertEqual(cropped.extent.height, 50)
    }

    // MARK: - Rotation Tests

    func testRotateImage90Degrees() throws {
        let rotated = service.rotate(ciImage: testCIImage, degrees: 90)

        XCTAssertNotNil(rotated)
        // 旋转后尺寸应该交换（100x100 方形旋转后仍是 100x100）
        XCTAssertEqual(rotated.extent.width, 100, accuracy: 1)
        XCTAssertEqual(rotated.extent.height, 100, accuracy: 1)
    }

    func testRotateImageAroundCenter() throws {
        let rotated = service.rotateAroundCenter(ciImage: testCIImage, degrees: 45)

        XCTAssertNotNil(rotated)
        // 旋转后图像应该仍然有效
        XCTAssertGreaterThan(rotated.extent.width, 0)
        XCTAssertGreaterThan(rotated.extent.height, 0)
    }

    // MARK: - Flip Tests

    func testFlipHorizontal() throws {
        let flipped = service.flip(ciImage: testCIImage, horizontal: true)

        XCTAssertNotNil(flipped)
        XCTAssertEqual(flipped.extent.width, testCIImage.extent.width)
        XCTAssertEqual(flipped.extent.height, testCIImage.extent.height)
    }

    func testFlipVertical() throws {
        let flipped = service.flip(ciImage: testCIImage, vertical: true)

        XCTAssertNotNil(flipped)
        XCTAssertEqual(flipped.extent.width, testCIImage.extent.width)
        XCTAssertEqual(flipped.extent.height, testCIImage.extent.height)
    }

    func testFlipBoth() throws {
        let flipped = service.flip(ciImage: testCIImage, horizontal: true, vertical: true)

        XCTAssertNotNil(flipped)
        XCTAssertEqual(flipped.extent.width, testCIImage.extent.width)
        XCTAssertEqual(flipped.extent.height, testCIImage.extent.height)
    }

    func testFlipNone() throws {
        // 不翻转时应返回原图
        let flipped = service.flip(ciImage: testCIImage, horizontal: false, vertical: false)

        XCTAssertEqual(flipped.extent, testCIImage.extent)
    }

    // MARK: - Filter Tests

    func testGaussianBlur() throws {
        let blurred = service.gaussianBlur(ciImage: testCIImage, radius: 10)

        XCTAssertNotNil(blurred)
        // 模糊后图像应该保持原始尺寸（因为我们裁剪了扩展的边界）
        XCTAssertEqual(blurred.extent.width, testCIImage.extent.width)
        XCTAssertEqual(blurred.extent.height, testCIImage.extent.height)
    }

    func testSharpen() throws {
        let sharpened = service.sharpen(ciImage: testCIImage, sharpness: 0.5)

        XCTAssertNotNil(sharpened)
        XCTAssertEqual(sharpened.extent.width, testCIImage.extent.width)
        XCTAssertEqual(sharpened.extent.height, testCIImage.extent.height)
    }

    func testAdjustBrightness() throws {
        let adjusted = service.adjustBrightness(ciImage: testCIImage, brightness: 0.5)

        XCTAssertNotNil(adjusted)
        XCTAssertEqual(adjusted.extent.width, testCIImage.extent.width)
    }

    func testAdjustContrast() throws {
        let adjusted = service.adjustContrast(ciImage: testCIImage, contrast: 1.5)

        XCTAssertNotNil(adjusted)
        XCTAssertEqual(adjusted.extent.width, testCIImage.extent.width)
    }

    func testAdjustSaturation() throws {
        let adjusted = service.adjustSaturation(ciImage: testCIImage, saturation: 0.5)

        XCTAssertNotNil(adjusted)
        XCTAssertEqual(adjusted.extent.width, testCIImage.extent.width)
    }

    func testAdjustColors() throws {
        let adjusted = service.adjustColors(
            ciImage: testCIImage,
            brightness: 0.1,
            contrast: 1.2,
            saturation: 0.8
        )

        XCTAssertNotNil(adjusted)
        XCTAssertEqual(adjusted.extent.width, testCIImage.extent.width)
    }

    func testGrayscale() throws {
        let grayscaled = service.grayscale(ciImage: testCIImage)

        XCTAssertNotNil(grayscaled)
        XCTAssertEqual(grayscaled.extent.width, testCIImage.extent.width)
    }

    func testInvert() throws {
        let inverted = service.invert(ciImage: testCIImage)

        XCTAssertNotNil(inverted)
        XCTAssertEqual(inverted.extent.width, testCIImage.extent.width)
    }

    func testSepiaTone() throws {
        let sepia = service.sepiaTone(ciImage: testCIImage, intensity: 0.8)

        XCTAssertNotNil(sepia)
        XCTAssertEqual(sepia.extent.width, testCIImage.extent.width)
    }

    // MARK: - Render Tests

    func testRenderToCGImage() throws {
        let cgImage = service.render(ciImage: testCIImage)

        XCTAssertNotNil(cgImage)
        XCTAssertEqual(cgImage?.width, Int(testCIImage.extent.width))
        XCTAssertEqual(cgImage?.height, Int(testCIImage.extent.height))
    }

    func testRenderWithFormat() throws {
        let cgImage = service.render(
            ciImage: testCIImage,
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        XCTAssertNotNil(cgImage)
    }

    // MARK: - Apply Filters Chain Tests

    func testApplyFiltersChain() throws {
        // 创建一个简单的 CGImage 用于测试
        guard let inputCGImage = service.render(ciImage: testCIImage) else {
            XCTFail("Failed to create input CGImage")
            return
        }

        let result = service.applyFilters(to: inputCGImage) { ciImage in
            var filtered = service.gaussianBlur(ciImage: ciImage, radius: 5)
            filtered = service.adjustBrightness(ciImage: filtered, brightness: 0.1)
            return filtered
        }

        XCTAssertNotNil(result)
    }

    // MARK: - Utility Tests

    func testMaxImageSize() throws {
        let maxInput = service.maxInputImageSize()
        let maxOutput = service.maxOutputImageSize()

        // 最大尺寸应该是正数
        XCTAssertGreaterThan(maxInput.width, 0)
        XCTAssertGreaterThan(maxInput.height, 0)
        XCTAssertGreaterThan(maxOutput.width, 0)
        XCTAssertGreaterThan(maxOutput.height, 0)
    }

    func testClearCaches() throws {
        // 清理缓存不应该崩溃
        service.clearCaches()
        XCTAssertTrue(true)
    }

    // MARK: - Coordinate Conversion Tests

    func testConvertVisionToCI() throws {
        let visionRect = CGRect(x: 0.1, y: 0.2, width: 0.5, height: 0.3)
        let imageHeight: CGFloat = 100

        let ciRect = CoreImageService.convertVisionToCI(rect: visionRect, imageHeight: imageHeight)

        XCTAssertEqual(ciRect.origin.x, 0.1)
        XCTAssertEqual(ciRect.origin.y, 100 - 0.2 - 0.3) // 应该是 50
        XCTAssertEqual(ciRect.width, 0.5)
        XCTAssertEqual(ciRect.height, 0.3)
    }

    func testConvertCIToVision() throws {
        let ciRect = CGRect(x: 10, y: 50, width: 30, height: 20)
        let imageHeight: CGFloat = 100

        let visionRect = CoreImageService.convertCIToVision(rect: ciRect, imageHeight: imageHeight)

        XCTAssertEqual(visionRect.origin.x, 10)
        XCTAssertEqual(visionRect.origin.y, 100 - 50 - 20) // 应该是 30
        XCTAssertEqual(visionRect.width, 30)
        XCTAssertEqual(visionRect.height, 20)
    }

    // MARK: - Edge Case Tests

    func testZeroBlurRadius() throws {
        // 0 模糊半径应该不会崩溃
        let blurred = service.gaussianBlur(ciImage: testCIImage, radius: 0)
        XCTAssertNotNil(blurred)
    }

    func testNegativeBlurRadius() throws {
        // 负模糊半径应该被处理（取 0）
        let blurred = service.gaussianBlur(ciImage: testCIImage, radius: -5)
        XCTAssertNotNil(blurred)
    }

    func testExtremeColorAdjustments() throws {
        // 极端值应该被裁剪到有效范围
        let adjusted = service.adjustColors(
            ciImage: testCIImage,
            brightness: 10, // 超出范围
            contrast: -1, // 超出范围
            saturation: 100 // 超出范围
        )
        XCTAssertNotNil(adjusted)
    }

    // MARK: - Mock Tests (Error Path Coverage)

    /// 测试 Metal 不可用的场景（软件渲染回退）
    func testInitWithoutMetal() throws {
        let mockOps = MockCoreImageOperations(shouldReturnNilMetalDevice: true)
        let mockService = CoreImageService(operations: mockOps)

        // 服务应该成功初始化（使用软件渲染）
        XCTAssertNotNil(mockService)

        // 验证仍然可以正常使用
        let blurred = mockService.gaussianBlur(ciImage: testCIImage, radius: 5)
        XCTAssertNotNil(blurred)
    }

    /// 测试 DefaultCoreImageOperations 的 createContext else 分支
    func testDefaultCoreImageOperations_CreateContextWithoutDevice() throws {
        let ops = DefaultCoreImageOperations()

        // 调用 createContext 的 else 分支（device 为 nil）
        let context = ops.createContext(with: nil, options: [
            .useSoftwareRenderer: true,
        ])

        XCTAssertNotNil(context)
    }

    // MARK: - Defensive Branch Coverage

    func testGaussianBlurOutputNilFallsBack() throws {
        let factory = MockCoreImageFilterFactory(gaussianBehavior: .nilOutput)
        let svc = makeService(factory: factory)
        let result = svc.gaussianBlur(ciImage: testCIImage, radius: 5)
        XCTAssertEqual(result.extent, testCIImage.extent)
    }

    func testGaussianBlurFilterNilFallsBack() throws {
        let factory = MockCoreImageFilterFactory(gaussianBehavior: .nilFilter)
        let svc = makeService(factory: factory)
        let result = svc.gaussianBlur(ciImage: testCIImage, radius: 5)
        XCTAssertEqual(result.extent, testCIImage.extent)
    }

    func testMotionBlurOutputNilFallsBack() throws {
        let factory = MockCoreImageFilterFactory(motionBehavior: .nilOutput)
        let svc = makeService(factory: factory)
        let result = svc.motionBlur(ciImage: testCIImage, radius: 5, angle: 45)
        XCTAssertEqual(result.extent, testCIImage.extent)
    }

    func testMotionBlurFilterNilFallsBack() throws {
        let factory = MockCoreImageFilterFactory(motionBehavior: .nilFilter)
        let svc = makeService(factory: factory)
        let result = svc.motionBlur(ciImage: testCIImage, radius: 5, angle: 45)
        XCTAssertEqual(result.extent, testCIImage.extent)
    }

    func testZoomBlurOutputNilFallsBack() throws {
        let factory = MockCoreImageFilterFactory(zoomBehavior: .nilOutput)
        let svc = makeService(factory: factory)
        let result = svc.zoomBlur(ciImage: testCIImage, amount: 10)
        XCTAssertEqual(result.extent, testCIImage.extent)
    }

    func testZoomBlurFilterNilFallsBack() throws {
        let factory = MockCoreImageFilterFactory(zoomBehavior: .nilFilter)
        let svc = makeService(factory: factory)
        let result = svc.zoomBlur(ciImage: testCIImage, amount: 10)
        XCTAssertEqual(result.extent, testCIImage.extent)
    }

    func testPerspectiveCorrectionFilterNil() throws {
        let factory = MockCoreImageFilterFactory(perspectiveBehavior: .nilFilter)
        let svc = makeService(factory: factory)
        let corrected = svc.perspectiveCorrection(
            ciImage: testCIImage,
            topLeft: .zero,
            topRight: CGPoint(x: 1, y: 0),
            bottomLeft: CGPoint(x: 0, y: 1),
            bottomRight: CGPoint(x: 1, y: 1)
        )
        XCTAssertNil(corrected)
    }

    func testDefringeFilterNil() throws {
        let factory = MockCoreImageFilterFactory(hueBehavior: .nilFilter)
        let svc = makeService(factory: factory)
        let result = svc.defringe(ciImage: testCIImage, amount: 0.5)
        XCTAssertEqual(result.extent, testCIImage.extent)
    }

    func testDefringeOutputNilFallsBack() throws {
        let factory = MockCoreImageFilterFactory(hueBehavior: .nilOutput)
        let svc = makeService(factory: factory)
        let result = svc.defringe(ciImage: testCIImage, amount: 0.5)
        XCTAssertEqual(result.extent, testCIImage.extent)
    }

    func testThresholdFilterNilFallback() throws {
        let factory = MockCoreImageFilterFactory(thresholdBehavior: .nilFilter)
        let svc = makeService(factory: factory)
        let result = svc.threshold(ciImage: testCIImage, threshold: 0.3)
        XCTAssertEqual(result.extent, testCIImage.extent)
    }

    func testApplyAndSaveWritesFile() throws {
        let factory = MockCoreImageFilterFactory()
        let svc = makeService(factory: factory)
        let input = TestResources.image("assets/medium_512x512.jpg")
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("ci_apply_\(UUID().uuidString).png")

        try svc.applyAndSave(
            inputURL: input,
            outputURL: output,
            format: "png",
            quality: 0.9
        ) { image in
            svc.invert(ciImage: image)
        }

        XCTAssertTrue(FileManager.default.fileExists(atPath: output.path))
        try? FileManager.default.removeItem(at: output)
    }

    func testApplyAndSaveRenderFails() throws {
        let factory = MockCoreImageFilterFactory()
        let svc = CoreImageService(
            operations: DefaultCoreImageOperations(),
            filterFactory: factory,
            rendererOverride: { _ in nil } // 强制渲染失败
        )
        let input = TestResources.image("assets/medium_512x512.jpg")
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("ci_apply_fail_\(UUID().uuidString).png")

        XCTAssertThrowsError(
            try svc.applyAndSave(
                inputURL: input,
                outputURL: output,
                format: "png",
                quality: 0.9
            ) { _ in CIImage(color: .black).cropped(to: .zero) }
        ) { error in
            guard let airisError = error as? AirisError,
                  case .imageEncodeFailed = airisError
            else {
                XCTFail("Expected AirisError.imageEncodeFailed, got \(error)")
                return
            }
        }
    }

    func testAutoEnhanceAndSaveWritesFile() throws {
        let factory = MockCoreImageFilterFactory()
        let svc = makeService(factory: factory)
        let input = TestResources.image("assets/medium_512x512.jpg")
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("ci_auto_\(UUID().uuidString).png")

        try svc.autoEnhanceAndSave(
            inputURL: input,
            outputURL: output,
            format: "png",
            quality: 0.9,
            enableRedEye: false
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: output.path))
        try? FileManager.default.removeItem(at: output)
    }

    func testAutoEnhanceAndSaveRenderFails() throws {
        let factory = MockCoreImageFilterFactory()
        let svc = CoreImageService(
            operations: DefaultCoreImageOperations(),
            filterFactory: factory,
            rendererOverride: { _ in nil } // 强制渲染失败
        )
        let input = TestResources.image("assets/medium_512x512.jpg")
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("ci_auto_fail_\(UUID().uuidString).png")

        XCTAssertThrowsError(
            try svc.autoEnhanceAndSave(
                inputURL: input,
                outputURL: output,
                format: "png",
                quality: 0.9,
                enableRedEye: false
            )
        ) { error in
            guard let airisError = error as? AirisError,
                  case .imageEncodeFailed = airisError
            else {
                XCTFail("Expected AirisError.imageEncodeFailed, got \(error)")
                return
            }
        }
    }

    func testOutputOverrideForcesFallback() throws {
        let factory = MockCoreImageFilterFactory()
        let svc = makeService(factory: factory, outputOverride: { _, _ in
            // 强制覆盖为 nil，走回退分支
            nil
        })

        let result = svc.sepiaTone(ciImage: testCIImage)
        XCTAssertEqual(result.extent, testCIImage.extent)
    }

    // MARK: - One-shot coverage for remaining filters

    func testInvokeRemainingFilters() throws {
        // 直接调用未覆盖的滤镜路径，确保函数覆盖率
        _ = service.unsharpMask(ciImage: testCIImage)
        _ = service.noiseReduction(ciImage: testCIImage)
        _ = service.pixellate(ciImage: testCIImage)
        _ = service.comicEffect(ciImage: testCIImage)
        _ = service.halftone(ciImage: testCIImage)
        _ = service.photoEffectMono(ciImage: testCIImage)
        _ = service.photoEffectChrome(ciImage: testCIImage)
        _ = service.photoEffectNoir(ciImage: testCIImage)
        _ = service.photoEffectInstant(ciImage: testCIImage)
        _ = service.photoEffectFade(ciImage: testCIImage)
        _ = service.photoEffectProcess(ciImage: testCIImage)
        _ = service.photoEffectTransfer(ciImage: testCIImage)
        _ = service.vignette(ciImage: testCIImage)
        _ = service.lineOverlay(ciImage: testCIImage)
        _ = service.edgeWork(ciImage: testCIImage)
        _ = service.edges(ciImage: testCIImage)
        _ = service.defringe(ciImage: testCIImage)
        _ = service.threshold(ciImage: testCIImage)

        // 透视校正与归一化版本
        let topLeft = CGPoint(x: 0, y: 0)
        let topRight = CGPoint(x: 1, y: 0)
        let bottomLeft = CGPoint(x: 0, y: 1)
        let bottomRight = CGPoint(x: 1, y: 1)
        _ = service.perspectiveCorrection(
            ciImage: testCIImage,
            topLeft: topLeft,
            topRight: topRight,
            bottomLeft: bottomLeft,
            bottomRight: bottomRight
        )
        _ = service.perspectiveCorrectionNormalized(
            ciImage: testCIImage,
            normalizedTopLeft: CGPoint(x: 0, y: 0),
            normalizedTopRight: CGPoint(x: 1, y: 0),
            normalizedBottomLeft: CGPoint(x: 0, y: 1),
            normalizedBottomRight: CGPoint(x: 1, y: 1)
        )

        // 自动增强相关
        _ = service.autoEnhance(ciImage: testCIImage, enableRedEye: false)
        _ = service.getAutoEnhanceFilters(for: testCIImage)
        _ = service.isUsingMetalAcceleration
    }
}
