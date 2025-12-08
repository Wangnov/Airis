import XCTest
import CoreImage
@testable import Airis

/// CoreImage 滤镜性能基准测试
///
/// 测试目标:
/// - 建立各滤镜操作的性能基线
/// - 测试大图像处理性能
/// - 测试滤镜链组合性能
final class CoreImagePerformanceTests: XCTestCase {
    var service: CoreImageService!
    var testCIImage: CIImage!
    var largeCIImage: CIImage!

    // 测试资产目录
    static let testAssetsPath = NSString(string: "~/airis-worktrees/test-assets/task-9.1").expandingTildeInPath

    override func setUp() {
        super.setUp()
        service = CoreImageService()

        // 创建 2K 测试图像（纯色 + 渐变混合）
        testCIImage = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 2048, height: 2048))

        // 创建 4K 测试图像
        largeCIImage = CIImage(color: .blue)
            .cropped(to: CGRect(x: 0, y: 0, width: 3840, height: 2160))
    }

    override func tearDown() {
        service = nil
        testCIImage = nil
        largeCIImage = nil
        super.tearDown()
    }

    // MARK: - 模糊滤镜性能

    /// 高斯模糊性能 - 标准半径
    func testGaussianBlurPerformance_StandardRadius() {
        measure(metrics: [XCTCPUMetric(), XCTClockMetric()]) {
            let _ = service.gaussianBlur(ciImage: testCIImage, radius: 10)
        }
    }

    /// 高斯模糊性能 - 大半径
    func testGaussianBlurPerformance_LargeRadius() {
        measure(metrics: [XCTCPUMetric(), XCTMemoryMetric()]) {
            let _ = service.gaussianBlur(ciImage: testCIImage, radius: 50)
        }
    }

    /// 运动模糊性能
    func testMotionBlurPerformance() {
        measure(metrics: [XCTCPUMetric()]) {
            let _ = service.motionBlur(ciImage: testCIImage, radius: 20, angle: 45)
        }
    }

    /// 缩放模糊性能
    func testZoomBlurPerformance() {
        measure(metrics: [XCTCPUMetric()]) {
            let _ = service.zoomBlur(ciImage: testCIImage, amount: 20)
        }
    }

    // MARK: - 缩放性能

    /// 缩放性能 - 4K → 1K
    func testResizePerformance_4KTo1K() {
        measure(metrics: [XCTCPUMetric(), XCTMemoryMetric()]) {
            let _ = service.resize(ciImage: largeCIImage, width: 1024, height: 576)
        }
    }

    /// 缩放性能 - 2K → 512
    func testResizePerformance_2KTo512() {
        measure(metrics: [XCTCPUMetric()]) {
            let _ = service.resize(ciImage: testCIImage, width: 512, height: 512)
        }
    }

    /// 缩放性能 - 上采样
    func testResizePerformance_Upscale() {
        let smallImage = CIImage(color: .green)
            .cropped(to: CGRect(x: 0, y: 0, width: 256, height: 256))

        measure(metrics: [XCTCPUMetric()]) {
            let _ = service.resize(ciImage: smallImage, width: 1024, height: 1024)
        }
    }

    // MARK: - 渲染性能

    /// 渲染性能 - 2K 图像
    func testRenderPerformance_2K() {
        measure(metrics: [XCTCPUMetric(), XCTMemoryMetric(), XCTClockMetric()]) {
            let _ = service.render(ciImage: testCIImage)
        }
    }

    /// 渲染性能 - 4K 图像
    func testRenderPerformance_4K() {
        measure(metrics: [XCTCPUMetric(), XCTMemoryMetric()]) {
            let _ = service.render(ciImage: largeCIImage)
        }
    }

    // MARK: - 滤镜链性能

    /// 滤镜链性能 - 3 个滤镜组合
    func testFilterChainPerformance_3Filters() {
        measure(metrics: [XCTCPUMetric(), XCTClockMetric()]) {
            var processed = testCIImage!
            processed = service.gaussianBlur(ciImage: processed, radius: 5)
            processed = service.sharpen(ciImage: processed, sharpness: 0.5)
            processed = service.adjustColors(ciImage: processed, brightness: 0.1, contrast: 1.2, saturation: 1.1)
            let _ = service.render(ciImage: processed)
        }
    }

    /// 滤镜链性能 - 5 个滤镜组合
    func testFilterChainPerformance_5Filters() {
        measure(metrics: [XCTCPUMetric(), XCTMemoryMetric()]) {
            var processed = testCIImage!
            processed = service.gaussianBlur(ciImage: processed, radius: 3)
            processed = service.sharpen(ciImage: processed, sharpness: 0.3)
            processed = service.adjustColors(ciImage: processed, brightness: 0.05, contrast: 1.1, saturation: 1.05)
            processed = service.vignette(ciImage: processed, intensity: 0.5)
            processed = service.noiseReduction(ciImage: processed, noiseLevel: 0.02)
            let _ = service.render(ciImage: processed)
        }
    }

    // MARK: - 颜色调整性能

    /// 颜色调整性能 - 综合调整
    func testColorAdjustmentPerformance() {
        measure(metrics: [XCTCPUMetric()]) {
            let _ = service.adjustColors(
                ciImage: testCIImage,
                brightness: 0.1,
                contrast: 1.2,
                saturation: 1.1
            )
        }
    }

    /// 色温调整性能
    func testTemperatureAdjustmentPerformance() {
        measure(metrics: [XCTCPUMetric()]) {
            let _ = service.adjustTemperatureAndTint(
                ciImage: testCIImage,
                temperature: 500,
                tint: 10
            )
        }
    }

    /// 曝光调整性能
    func testExposureAdjustmentPerformance() {
        measure(metrics: [XCTCPUMetric()]) {
            let _ = service.adjustExposure(ciImage: testCIImage, ev: 1.0)
        }
    }

    // MARK: - 艺术效果性能

    /// 漫画效果性能
    func testComicEffectPerformance() {
        measure(metrics: [XCTCPUMetric(), XCTMemoryMetric()]) {
            let _ = service.comicEffect(ciImage: testCIImage)
        }
    }

    /// 半色调效果性能
    func testHalftoneEffectPerformance() {
        measure(metrics: [XCTCPUMetric()]) {
            let _ = service.halftone(ciImage: testCIImage, width: 6)
        }
    }

    /// 像素化效果性能
    func testPixellatePerformance() {
        measure(metrics: [XCTCPUMetric()]) {
            let _ = service.pixellate(ciImage: testCIImage, scale: 10)
        }
    }

    // MARK: - 照片效果性能

    /// 黑白效果性能
    func testMonoEffectPerformance() {
        measure(metrics: [XCTCPUMetric()]) {
            let _ = service.photoEffectMono(ciImage: testCIImage)
        }
    }

    /// 棕褐色效果性能
    func testSepiaEffectPerformance() {
        measure(metrics: [XCTCPUMetric()]) {
            let _ = service.sepiaTone(ciImage: testCIImage, intensity: 1.0)
        }
    }

    /// 黑色电影效果性能
    func testNoirEffectPerformance() {
        measure(metrics: [XCTCPUMetric()]) {
            let _ = service.photoEffectNoir(ciImage: testCIImage)
        }
    }

    // MARK: - 变换性能

    /// 旋转性能
    func testRotationPerformance() {
        measure(metrics: [XCTCPUMetric()]) {
            let _ = service.rotateAroundCenter(ciImage: testCIImage, degrees: 45)
        }
    }

    /// 翻转性能
    func testFlipPerformance() {
        measure(metrics: [XCTCPUMetric()]) {
            let _ = service.flip(ciImage: testCIImage, horizontal: true, vertical: true)
        }
    }

    /// 裁剪性能
    func testCropPerformance() {
        measure(metrics: [XCTCPUMetric()]) {
            let _ = service.crop(ciImage: testCIImage, rect: CGRect(x: 100, y: 100, width: 1000, height: 1000))
        }
    }

    // MARK: - 自动增强性能

    /// 自动增强性能
    func testAutoEnhancePerformance() {
        measure(metrics: [XCTCPUMetric(), XCTMemoryMetric()]) {
            let _ = service.autoEnhance(ciImage: testCIImage, enableRedEye: false)
        }
    }
}
