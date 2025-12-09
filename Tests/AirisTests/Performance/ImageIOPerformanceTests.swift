import XCTest
import CoreImage
@testable import Airis

/// 图像 I/O 性能基准测试
///
/// 测试目标:
/// - 测试图像加载性能
/// - 测试图像保存性能（不同格式）
/// - 测试元数据读取性能
/// - 测试格式转换性能
final class ImageIOPerformanceTests: XCTestCase {
    var service: ImageIOService!
    var testImageURL: URL!
    var tempDirectory: URL!

    // 测试资产目录
    static let testAssetsPath = URL(fileURLWithPath: "worktrees/test-assets/task-9.1", relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)).path

    override func setUp() async throws {
        try await super.setUp()
        service = ImageIOService()

        testImageURL = URL(fileURLWithPath: Self.testAssetsPath + "/benchmark_4k.png")

        // 创建临时目录用于保存测试
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("airis_perf_test_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("测试资产不存在: \(testImageURL.path)")
        }
    }

    override func tearDown() async throws {
        // 清理临时目录
        try? FileManager.default.removeItem(at: tempDirectory)
        service = nil
        try await super.tearDown()
    }

    // MARK: - 图像加载性能

    /// 测试 4K 图像加载性能 - 完整加载
    func testLoadImage_4K_Full() throws {
        let options = XCTMeasureOptions()
        options.iterationCount = 3
        
        measure(metrics: [XCTCPUMetric(), XCTMemoryMetric(), XCTClockMetric()], options: options) {
            _ = try? service.loadImage(at: testImageURL)
        }
    }

    /// 测试 4K 图像加载性能 - 缩略图模式
    func testLoadImage_4K_Thumbnail() throws {
        let options = XCTMeasureOptions()
        options.iterationCount = 3
        
        measure(metrics: [XCTCPUMetric(), XCTMemoryMetric()], options: options) {
            _ = try? service.loadImage(at: testImageURL, maxDimension: 512)
        }
    }

    /// 测试 4K 图像加载性能 - 1K 缩略图
    func testLoadImage_4K_Thumbnail1K() throws {
        let options = XCTMeasureOptions()
        options.iterationCount = 3
        
        measure(metrics: [XCTCPUMetric()], options: options) {
            _ = try? service.loadImage(at: testImageURL, maxDimension: 1024)
        }
    }

    // MARK: - 元数据读取性能

    /// 测试元数据读取性能（零拷贝）
    func testLoadMetadata() throws {
        let options = XCTMeasureOptions()
        options.iterationCount = 3
        
        measure(metrics: [XCTCPUMetric(), XCTClockMetric()], options: options) {
            _ = try? service.loadImageMetadata(at: testImageURL)
        }
    }

    /// 测试图像信息读取性能
    func testGetImageInfo() throws {
        let options = XCTMeasureOptions()
        options.iterationCount = 3
        
        measure(metrics: [XCTCPUMetric()], options: options) {
            _ = try? service.getImageInfo(at: testImageURL)
        }
    }

    // MARK: - 图像保存性能

    /// 测试保存为 PNG 性能
    func testSaveImage_PNG() throws {
        let cgImage = try service.loadImage(at: testImageURL, maxDimension: 1024)
        let outputPath = tempDirectory.appendingPathComponent("test_output.png")

        let options = XCTMeasureOptions()
        options.iterationCount = 3
        
        measure(metrics: [XCTCPUMetric(), XCTClockMetric()], options: options) {
            try? service.saveImage(cgImage, to: outputPath, format: "png")
        }

        // 清理
        try? FileManager.default.removeItem(at: outputPath)
    }

    /// 测试保存为 JPEG 性能 - 高质量
    func testSaveImage_JPEG_HighQuality() throws {
        let cgImage = try service.loadImage(at: testImageURL, maxDimension: 1024)
        let outputPath = tempDirectory.appendingPathComponent("test_output_hq.jpg")

        let options = XCTMeasureOptions()
        options.iterationCount = 3
        
        measure(metrics: [XCTCPUMetric(), XCTClockMetric()], options: options) {
            try? service.saveImage(cgImage, to: outputPath, format: "jpg", quality: 0.95)
        }

        try? FileManager.default.removeItem(at: outputPath)
    }

    /// 测试保存为 JPEG 性能 - 低质量（压缩更多）
    func testSaveImage_JPEG_LowQuality() throws {
        let cgImage = try service.loadImage(at: testImageURL, maxDimension: 1024)
        let outputPath = tempDirectory.appendingPathComponent("test_output_lq.jpg")

        let options = XCTMeasureOptions()
        options.iterationCount = 3
        
        measure(metrics: [XCTCPUMetric(), XCTClockMetric()], options: options) {
            try? service.saveImage(cgImage, to: outputPath, format: "jpg", quality: 0.5)
        }

        try? FileManager.default.removeItem(at: outputPath)
    }

    /// 测试保存为 HEIC 性能
    func testSaveImage_HEIC() throws {
        let cgImage = try service.loadImage(at: testImageURL, maxDimension: 1024)
        let outputPath = tempDirectory.appendingPathComponent("test_output.heic")

        let options = XCTMeasureOptions()
        options.iterationCount = 3
        
        measure(metrics: [XCTCPUMetric(), XCTClockMetric()], options: options) {
            try? service.saveImage(cgImage, to: outputPath, format: "heic", quality: 0.9)
        }

        try? FileManager.default.removeItem(at: outputPath)
    }

    // MARK: - 格式转换性能

    /// 测试完整的加载-处理-保存流程
    func testFullPipeline_LoadProcessSave() throws {
        let coreImageService = CoreImageService()
        let outputPath = tempDirectory.appendingPathComponent("processed_output.jpg")

        let options = XCTMeasureOptions()
        options.iterationCount = 3
        
        measure(metrics: [XCTCPUMetric(), XCTMemoryMetric(), XCTClockMetric()], options: options) {
            // 加载
            guard let cgImage = try? service.loadImage(at: testImageURL, maxDimension: 1024) else { return }

            // 处理
            let ciImage = CIImage(cgImage: cgImage)
            let processed = coreImageService.gaussianBlur(ciImage: ciImage, radius: 5)

            // 渲染
            guard let outputCGImage = coreImageService.render(ciImage: processed) else { return }

            // 保存
            try? service.saveImage(outputCGImage, to: outputPath, format: "jpg", quality: 0.9)
        }

        try? FileManager.default.removeItem(at: outputPath)
    }

    /// 测试批量缩略图生成性能
    func testBatchThumbnailGeneration() throws {
        let thumbnailSizes = [128, 256, 512, 1024]

        let options = XCTMeasureOptions()
        options.iterationCount = 3
        
        measure(metrics: [XCTCPUMetric(), XCTClockMetric()], options: options) {
            for size in thumbnailSizes {
                _ = try? service.loadImage(at: testImageURL, maxDimension: size)
            }
        }
    }
}
