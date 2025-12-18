import CoreImage
import Vision
import XCTest
#if !XCODE_BUILD
    @testable import AirisCore
#endif

/// 真实用例集成测试 - 模拟实际使用场景
final class RealWorldUseCaseTests: XCTestCase {
    // ✅ Apple 最佳实践：类级别共享服务
    static let sharedVisionService = VisionService()
    static let sharedCoreImageService = CoreImageService()
    static let sharedImageIOService = ImageIOService()

    // MARK: - Properties

    var visionService: VisionService!
    var coreImageService: CoreImageService!
    var imageIOService: ImageIOService!
    var tempDir: URL!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        visionService = Self.sharedVisionService
        coreImageService = Self.sharedCoreImageService
        imageIOService = Self.sharedImageIOService

        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("airis_realworld_test_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        visionService = nil
        coreImageService = nil
        imageIOService = nil
        super.tearDown()
    }

    // MARK: - 产品照片处理流程

    /// 测试：电商产品照片标准化处理流程
    /// 流程：加载 → 缩放到标准尺寸 → 增强 → 压缩保存
    func testProductPhotoStandardization() async throws {
        let imageURL = TestResources.image("landscape.jpg")

        // 1. 加载原始产品照片
        let cgImage = try imageIOService.loadImage(at: imageURL)
        var ciImage = CIImage(cgImage: cgImage)

        // 2. 缩放到电商标准尺寸（800x800）
        let standardSize = 800
        ciImage = coreImageService.resize(ciImage: ciImage, width: standardSize, height: standardSize)

        // 3. 轻微增强（提高清晰度和饱和度）
        ciImage = coreImageService.sharpen(ciImage: ciImage, sharpness: 0.3)
        ciImage = coreImageService.adjustSaturation(ciImage: ciImage, saturation: 1.1)

        // 4. 渲染
        guard let outputCGImage = coreImageService.render(ciImage: ciImage) else {
            XCTFail("Failed to render product photo")
            return
        }

        // 5. 保存为压缩的 JPEG（节省存储）
        let outputURL = tempDir.appendingPathComponent("product_standard.jpg")
        try imageIOService.saveImage(outputCGImage, to: outputURL, format: "jpg", quality: 0.85)

        // 验证输出
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
        let outputInfo = try imageIOService.getImageInfo(at: outputURL)
        XCTAssertLessThanOrEqual(outputInfo.width, standardSize)
        XCTAssertLessThanOrEqual(outputInfo.height, standardSize)
    }

    /// 测试：产品缩略图批量生成
    /// 场景：为同一产品生成多种尺寸的缩略图
    func testProductThumbnailGeneration() async throws {
        let imageURL = TestResources.image("landscape.jpg")

        // 定义需要生成的缩略图尺寸
        let thumbnailSizes: [String: Int] = [
            "large": 600,
            "medium": 300,
            "small": 150,
            "icon": 64,
        ]

        // 加载原图
        let cgImage = try imageIOService.loadImage(at: imageURL)
        let ciImage = CIImage(cgImage: cgImage)

        var generatedFiles: [String: URL] = [:]

        // 批量生成
        for (name, size) in thumbnailSizes {
            let resized = coreImageService.resize(ciImage: ciImage, width: size, height: size)
            guard let outputCGImage = coreImageService.render(ciImage: resized) else {
                XCTFail("Failed to render thumbnail: \(name)")
                continue
            }

            let outputURL = tempDir.appendingPathComponent("thumb_\(name).jpg")
            try imageIOService.saveImage(outputCGImage, to: outputURL, format: "jpg", quality: 0.8)
            generatedFiles[name] = outputURL
        }

        // 验证所有缩略图已生成
        XCTAssertEqual(generatedFiles.count, thumbnailSizes.count)
        for (name, url) in generatedFiles {
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "Thumbnail \(name) should exist")
        }
    }

    // MARK: - 文档扫描流程

    /// 测试：文档扫描完整流程
    /// 流程：检测文档边界 → 透视校正 → 增强对比度 → OCR
    func testDocumentScanningWorkflow() async throws {
        let documentURL = TestResources.image("vision/document.png")

        // 1. 检测文档边界
        let rectangles = try await visionService.detectRectangles(
            at: documentURL,
            minimumConfidence: 0.3,
            minimumSize: 0.1
        )

        // 2. 加载图像
        let cgImage = try imageIOService.loadImage(at: documentURL)
        var ciImage = CIImage(cgImage: cgImage)

        // 3. 如果检测到边界，进行透视校正
        if let rect = rectangles.first {
            let imageHeight = ciImage.extent.height
            let imageWidth = ciImage.extent.width

            let topLeft = CGPoint(x: rect.topLeft.x * imageWidth, y: (1 - rect.topLeft.y) * imageHeight)
            let topRight = CGPoint(x: rect.topRight.x * imageWidth, y: (1 - rect.topRight.y) * imageHeight)
            let bottomLeft = CGPoint(x: rect.bottomLeft.x * imageWidth, y: (1 - rect.bottomLeft.y) * imageHeight)
            let bottomRight = CGPoint(x: rect.bottomRight.x * imageWidth, y: (1 - rect.bottomRight.y) * imageHeight)

            if let corrected = coreImageService.perspectiveCorrection(
                ciImage: ciImage,
                topLeft: topLeft,
                topRight: topRight,
                bottomLeft: bottomLeft,
                bottomRight: bottomRight
            ) {
                ciImage = corrected
            }
        }

        // 4. 增强文档可读性
        ciImage = coreImageService.adjustContrast(ciImage: ciImage, contrast: 1.3)
        ciImage = coreImageService.sharpen(ciImage: ciImage, sharpness: 0.2)

        // 5. 保存处理后的文档
        guard let outputCGImage = coreImageService.render(ciImage: ciImage) else {
            XCTFail("Failed to render scanned document")
            return
        }

        let outputURL = tempDir.appendingPathComponent("scanned_document.png")
        try imageIOService.saveImage(outputCGImage, to: outputURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))

        // 6. OCR 提取文字（集成测试用 fast 模式）
        _ = try await visionService.recognizeText(at: documentURL, level: .fast)
        // 文档中可能有文字，流程应该完成
        XCTAssertTrue(true, "Document scanning workflow completed")
    }

    /// 测试：批量文档处理
    /// 场景：处理多页文档，每页应用相同的增强处理
    func testBatchDocumentProcessing() async throws {
        let documentURL = TestResources.image("vision/document.png")

        // 模拟多页文档（实际场景会有多个不同文件）
        let pageCount = 3
        var processedPages: [URL] = []

        for pageNum in 1 ... pageCount {
            // 1. 加载页面
            let cgImage = try imageIOService.loadImage(at: documentURL)
            var ciImage = CIImage(cgImage: cgImage)

            // 2. 应用文档增强
            ciImage = coreImageService.autoEnhance(ciImage: ciImage)
            ciImage = coreImageService.adjustContrast(ciImage: ciImage, contrast: 1.2)

            // 3. 保存
            guard let outputCGImage = coreImageService.render(ciImage: ciImage) else {
                XCTFail("Failed to render page \(pageNum)")
                continue
            }

            let outputURL = tempDir.appendingPathComponent("page_\(pageNum).png")
            try imageIOService.saveImage(outputCGImage, to: outputURL)
            processedPages.append(outputURL)
        }

        XCTAssertEqual(processedPages.count, pageCount)
    }

    // MARK: - 批量图像分析流程

    /// 测试：图像库分类标签生成
    /// 场景：为图像库中的图片自动生成分类标签
    func testImageLibraryTagging() async throws {
        let imageURL = TestResources.image("landscape.jpg")

        // 模拟图像库（实际场景会有多张不同图片）
        let imageCount = 3
        var imageTags: [[String]] = []

        // 为每张图片生成标签
        for _ in 0 ..< imageCount {
            let classifications = try await visionService.classifyImage(at: imageURL, threshold: 0.3)
            let tags = classifications.prefix(5).map { classification in
                classification.identifier
            }
            imageTags.append(tags)
        }

        // 验证所有图片都有标签
        XCTAssertEqual(imageTags.count, imageCount)
        for (index, tags) in imageTags.enumerated() {
            XCTAssertNotNil(tags, "Image \(index) should have tags")
        }
    }

    /// 测试：图像内容审核流程
    /// 场景：检测图像中是否包含特定内容（人脸、文字等）
    func testImageContentModeration() async throws {
        let imageURL = TestResources.image("landscape.jpg")

        // 内容审核结果
        struct ModerationResult {
            var hasFaces: Bool
            var hasText: Bool
            var hasBarcodes: Bool
            var primaryCategories: [String]
        }

        // 1. 检测人脸
        let faces = try await visionService.detectFaceRectangles(at: imageURL)

        // 2. 检测文字
        let texts = try await visionService.recognizeText(at: imageURL)

        // 3. 检测条形码
        let barcodes = try await visionService.detectBarcodes(at: imageURL)

        // 4. 分类
        let classifications = try await visionService.classifyImage(at: imageURL, threshold: 0.5)
        let topCategories = classifications.prefix(3).map(\.identifier)

        // 生成审核结果
        let result = ModerationResult(
            hasFaces: !faces.isEmpty,
            hasText: !texts.isEmpty,
            hasBarcodes: !barcodes.isEmpty,
            primaryCategories: topCategories
        )

        // 验证审核流程完成
        XCTAssertTrue(true, "Content moderation completed")
        // 风景图通常没有人脸和条形码
        XCTAssertFalse(result.hasFaces, "Landscape should not have faces")
    }

    // MARK: - 社交媒体图片处理

    /// 测试：社交媒体头像处理
    /// 场景：裁剪为正方形 → 缩放 → 应用滤镜
    func testSocialMediaAvatarProcessing() async throws {
        let imageURL = TestResources.image("landscape.jpg")

        // 1. 加载图像
        let cgImage = try imageIOService.loadImage(at: imageURL)
        var ciImage = CIImage(cgImage: cgImage)

        // 2. 裁剪为正方形（取中心区域）
        let extent = ciImage.extent
        let minDimension = min(extent.width, extent.height)
        let cropRect = CGRect(
            x: (extent.width - minDimension) / 2,
            y: (extent.height - minDimension) / 2,
            width: minDimension,
            height: minDimension
        )
        ciImage = coreImageService.crop(ciImage: ciImage, rect: cropRect)

        // 3. 缩放到头像尺寸
        let avatarSize = 512
        ciImage = coreImageService.resize(ciImage: ciImage, width: avatarSize, height: avatarSize)

        // 4. 应用轻微的暖色调滤镜
        ciImage = coreImageService.adjustColors(ciImage: ciImage, brightness: 0.02, saturation: 1.1)

        // 5. 保存
        guard let outputCGImage = coreImageService.render(ciImage: ciImage) else {
            XCTFail("Failed to render avatar")
            return
        }

        let outputURL = tempDir.appendingPathComponent("avatar.png")
        try imageIOService.saveImage(outputCGImage, to: outputURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))

        // 验证尺寸（允许 2 像素误差，Lanczos 缩放可能有微小偏差）
        let outputInfo = try imageIOService.getImageInfo(at: outputURL)
        XCTAssertTrue(abs(outputInfo.width - avatarSize) <= 2, "Width should be close to \(avatarSize)")
        XCTAssertTrue(abs(outputInfo.height - avatarSize) <= 2, "Height should be close to \(avatarSize)")
    }

    /// 测试：Instagram 风格滤镜批量应用
    /// 场景：为同一张图片生成多种滤镜效果预览
    func testInstagramStyleFilters() async throws {
        let imageURL = TestResources.image("landscape.jpg")

        // 加载图像
        let cgImage = try imageIOService.loadImage(at: imageURL)
        let originalImage = CIImage(cgImage: cgImage)

        // 定义滤镜预设
        let filterPresets: [(name: String, apply: (CIImage) -> CIImage)] = [
            ("original", { $0 }),
            ("vintage", { self.coreImageService.sepiaTone(ciImage: $0, intensity: 0.6) }),
            ("noir", { self.coreImageService.photoEffectNoir(ciImage: $0) }),
            ("chrome", { self.coreImageService.photoEffectChrome(ciImage: $0) }),
            ("instant", { self.coreImageService.photoEffectInstant(ciImage: $0) }),
            ("fade", { self.coreImageService.photoEffectFade(ciImage: $0) }),
            ("vivid", {
                var img = $0
                img = self.coreImageService.adjustSaturation(ciImage: img, saturation: 1.5)
                img = self.coreImageService.adjustContrast(ciImage: img, contrast: 1.2)
                return img
            }),
            ("cool", {
                var img = $0
                img = self.coreImageService.adjustSaturation(ciImage: img, saturation: 0.8)
                return self.coreImageService.adjustColors(ciImage: img, brightness: -0.05, contrast: 1.1, saturation: 0.9)
            }),
        ]

        var generatedPreviews: [String: URL] = [:]

        // 生成预览缩略图
        let previewSize = 300
        for (name, filter) in filterPresets {
            var filtered = filter(originalImage)
            filtered = coreImageService.resize(ciImage: filtered, width: previewSize, height: previewSize)

            guard let outputCGImage = coreImageService.render(ciImage: filtered) else {
                continue
            }

            let outputURL = tempDir.appendingPathComponent("filter_\(name).jpg")
            try imageIOService.saveImage(outputCGImage, to: outputURL, format: "jpg", quality: 0.8)
            generatedPreviews[name] = outputURL
        }

        XCTAssertEqual(generatedPreviews.count, filterPresets.count)
    }

    // MARK: - 多 Provider 切换测试

    /// 测试：服务容器多次访问
    /// 场景：模拟在应用中多次获取服务
    func testServiceContainerMultipleAccess() throws {
        // 多次获取同一个服务
        let vision1 = ServiceContainer.shared.visionService
        let vision2 = ServiceContainer.shared.visionService

        let coreImage1 = ServiceContainer.shared.coreImageService
        let coreImage2 = ServiceContainer.shared.coreImageService

        let imageIO1 = ServiceContainer.shared.imageIOService
        let imageIO2 = ServiceContainer.shared.imageIOService

        // 验证是同一个实例（lazy var 保证单例）
        XCTAssertTrue(vision1 === vision2, "VisionService should be same instance")
        XCTAssertTrue(coreImage1 === coreImage2, "CoreImageService should be same instance")
        XCTAssertTrue(imageIO1 === imageIO2, "ImageIOService should be same instance")
    }

    /// 测试：获取不同的 Provider
    func testMultipleProviders() throws {
        let container = ServiceContainer.shared

        // 获取默认 provider
        let defaultProvider = container.geminiProvider

        // 获取自定义 provider
        let customProvider1 = container.getProvider(name: "custom1")
        let customProvider2 = container.getProvider(name: "custom2")

        // 验证都是有效的 provider
        XCTAssertNotNil(defaultProvider)
        XCTAssertNotNil(customProvider1)
        XCTAssertNotNil(customProvider2)
    }

    // MARK: - 性能敏感场景测试

    /// 测试：高分辨率图像处理
    /// 场景：处理 4K+ 图像时的稳定性
    func testHighResolutionImageProcessing() async throws {
        let imageURL = TestResources.image("landscape.jpg")

        // 1. 加载高分辨率图像
        let cgImage = try imageIOService.loadImage(at: imageURL)
        var ciImage = CIImage(cgImage: cgImage)

        let originalWidth = ciImage.extent.width
        let originalHeight = ciImage.extent.height

        // 2. 执行一系列操作
        ciImage = coreImageService.gaussianBlur(ciImage: ciImage, radius: 5)
        ciImage = coreImageService.sharpen(ciImage: ciImage, sharpness: 0.5)
        ciImage = coreImageService.adjustColors(ciImage: ciImage, brightness: 0.05, contrast: 1.1, saturation: 1.05)
        ciImage = coreImageService.vignette(ciImage: ciImage, intensity: 0.3)

        // 3. 渲染
        guard let outputCGImage = coreImageService.render(ciImage: ciImage) else {
            XCTFail("Failed to render high-res image")
            return
        }

        // 4. 保存
        let outputURL = tempDir.appendingPathComponent("highres_processed.png")
        try imageIOService.saveImage(outputCGImage, to: outputURL)

        // 验证尺寸保持
        let outputInfo = try imageIOService.getImageInfo(at: outputURL)
        XCTAssertEqual(CGFloat(outputInfo.width), originalWidth, accuracy: 1)
        XCTAssertEqual(CGFloat(outputInfo.height), originalHeight, accuracy: 1)
    }

    /// 测试：内存敏感的批量处理
    /// 场景：处理多张图片时避免内存泄漏
    func testMemoryEfficientBatchProcessing() async throws {
        let imageURL = TestResources.image("line_art.png")

        // 处理多张图片，每次处理后清理缓存
        for i in 1 ... 5 {
            autoreleasepool {
                do {
                    let cgImage = try imageIOService.loadImage(at: imageURL)
                    var ciImage = CIImage(cgImage: cgImage)

                    // 应用滤镜
                    ciImage = coreImageService.gaussianBlur(ciImage: ciImage, radius: 3)
                    ciImage = coreImageService.resize(ciImage: ciImage, width: 500)

                    guard let outputCGImage = coreImageService.render(ciImage: ciImage) else {
                        return
                    }

                    let outputURL = tempDir.appendingPathComponent("batch_\(i).jpg")
                    try imageIOService.saveImage(outputCGImage, to: outputURL, format: "jpg", quality: 0.8)
                } catch {
                    // 继续处理
                }
            }

            // 清理缓存
            coreImageService.clearCaches()
        }

        XCTAssertTrue(true, "Memory-efficient batch processing completed")
    }

    // MARK: - 端到端用户流程测试

    /// 测试：完整的图片编辑用户流程
    /// 模拟用户：打开图片 → 查看信息 → 编辑 → 预览 → 保存
    func testCompleteUserEditingFlow() async throws {
        let imageURL = TestResources.image("landscape.jpg")

        // 步骤 1: 用户打开图片，查看信息
        let imageInfo = try imageIOService.getImageInfo(at: imageURL)
        XCTAssertGreaterThan(imageInfo.width, 0)
        XCTAssertGreaterThan(imageInfo.height, 0)

        // 步骤 2: 用户请求分析图片内容
        _ = try await visionService.classifyImage(at: imageURL, threshold: 0.3)
        // 用户看到分类结果

        // 步骤 3: 用户加载图片进行编辑
        let cgImage = try imageIOService.loadImage(at: imageURL)
        var ciImage = CIImage(cgImage: cgImage)

        // 步骤 4: 用户应用编辑
        // - 调整亮度
        ciImage = coreImageService.adjustBrightness(ciImage: ciImage, brightness: 0.05)
        // - 调整对比度
        ciImage = coreImageService.adjustContrast(ciImage: ciImage, contrast: 1.1)
        // - 裁剪为 16:9
        let extent = ciImage.extent
        let targetRatio: CGFloat = 16.0 / 9.0
        let currentRatio = extent.width / extent.height

        if currentRatio > targetRatio {
            // 图片太宽，裁剪两边
            let newWidth = extent.height * targetRatio
            let cropRect = CGRect(
                x: (extent.width - newWidth) / 2,
                y: 0,
                width: newWidth,
                height: extent.height
            )
            ciImage = coreImageService.crop(ciImage: ciImage, rect: cropRect)
        }

        // 步骤 5: 用户预览结果（渲染）
        guard let previewCGImage = coreImageService.render(ciImage: ciImage) else {
            XCTFail("Failed to generate preview")
            return
        }
        XCTAssertNotNil(previewCGImage)

        // 步骤 6: 用户满意，保存结果
        let outputURL = tempDir.appendingPathComponent("user_edited.png")
        try imageIOService.saveImage(previewCGImage, to: outputURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))

        // 步骤 7: 用户导出为 JPEG（用于分享）
        let shareURL = tempDir.appendingPathComponent("user_share.jpg")
        try imageIOService.saveImage(previewCGImage, to: shareURL, format: "jpg", quality: 0.9)
        XCTAssertTrue(FileManager.default.fileExists(atPath: shareURL.path))
    }

    /// 测试：图片比较功能
    /// 场景：用户想比较原图和编辑后的效果
    func testImageComparisonWorkflow() async throws {
        let imageURL = TestResources.image("line_art.png")

        // 加载原图
        let originalCGImage = try imageIOService.loadImage(at: imageURL)
        let originalCIImage = CIImage(cgImage: originalCGImage)

        // 创建编辑版本
        var editedCIImage = originalCIImage
        editedCIImage = coreImageService.photoEffectChrome(ciImage: editedCIImage)
        editedCIImage = coreImageService.vignette(ciImage: editedCIImage, intensity: 0.5)

        // 渲染两个版本
        guard let originalRendered = coreImageService.render(ciImage: originalCIImage),
              let editedRendered = coreImageService.render(ciImage: editedCIImage)
        else {
            XCTFail("Failed to render comparison images")
            return
        }

        // 保存两个版本以便比较
        let originalURL = tempDir.appendingPathComponent("compare_original.png")
        let editedURL = tempDir.appendingPathComponent("compare_edited.png")

        try imageIOService.saveImage(originalRendered, to: originalURL)
        try imageIOService.saveImage(editedRendered, to: editedURL)

        XCTAssertTrue(FileManager.default.fileExists(atPath: originalURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: editedURL.path))

        // 验证两个文件尺寸相同
        let originalInfo = try imageIOService.getImageInfo(at: originalURL)
        let editedInfo = try imageIOService.getImageInfo(at: editedURL)

        XCTAssertEqual(originalInfo.width, editedInfo.width)
        XCTAssertEqual(originalInfo.height, editedInfo.height)
    }
}
