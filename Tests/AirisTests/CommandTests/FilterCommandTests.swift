import XCTest
import CoreImage
@testable import Airis

final class FilterCommandTests: XCTestCase {
    var coreImageService: CoreImageService!

    // 测试用图像（100x100 红色方块）
    var testCIImage: CIImage!

    override func setUp() {
        super.setUp()
        coreImageService = CoreImageService()

        // 创建测试用 CIImage（100x100 红色方块）
        testCIImage = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
    }

    override func tearDown() {
        coreImageService = nil
        testCIImage = nil
        super.tearDown()
    }

    // MARK: - Motion Blur Tests

    func testMotionBlur() {
        let blurred = coreImageService.motionBlur(ciImage: testCIImage, radius: 10, angle: 0)

        XCTAssertNotNil(blurred)
        XCTAssertEqual(blurred.extent.width, testCIImage.extent.width)
        XCTAssertEqual(blurred.extent.height, testCIImage.extent.height)
    }

    func testMotionBlurWithAngle() {
        let blurred = coreImageService.motionBlur(ciImage: testCIImage, radius: 15, angle: 45)

        XCTAssertNotNil(blurred)
        XCTAssertEqual(blurred.extent.width, testCIImage.extent.width)
    }

    func testMotionBlurZeroRadius() {
        let blurred = coreImageService.motionBlur(ciImage: testCIImage, radius: 0, angle: 0)

        XCTAssertNotNil(blurred)
    }

    // MARK: - Zoom Blur Tests

    func testZoomBlur() {
        let blurred = coreImageService.zoomBlur(ciImage: testCIImage, amount: 10)

        XCTAssertNotNil(blurred)
        XCTAssertEqual(blurred.extent.width, testCIImage.extent.width)
        XCTAssertEqual(blurred.extent.height, testCIImage.extent.height)
    }

    func testZoomBlurWithCenter() {
        let center = CGPoint(x: 50, y: 50)
        let blurred = coreImageService.zoomBlur(ciImage: testCIImage, center: center, amount: 15)

        XCTAssertNotNil(blurred)
    }

    func testZoomBlurZeroAmount() {
        let blurred = coreImageService.zoomBlur(ciImage: testCIImage, amount: 0)

        XCTAssertNotNil(blurred)
    }

    // MARK: - Unsharp Mask Tests

    func testUnsharpMask() {
        let sharpened = coreImageService.unsharpMask(ciImage: testCIImage, radius: 2.5, intensity: 0.5)

        XCTAssertNotNil(sharpened)
        XCTAssertEqual(sharpened.extent.width, testCIImage.extent.width)
        XCTAssertEqual(sharpened.extent.height, testCIImage.extent.height)
    }

    func testUnsharpMaskHighIntensity() {
        let sharpened = coreImageService.unsharpMask(ciImage: testCIImage, radius: 5, intensity: 1.5)

        XCTAssertNotNil(sharpened)
    }

    // MARK: - Noise Reduction Tests

    func testNoiseReduction() {
        let denoised = coreImageService.noiseReduction(ciImage: testCIImage, noiseLevel: 0.02, sharpness: 0.4)

        XCTAssertNotNil(denoised)
        XCTAssertEqual(denoised.extent.width, testCIImage.extent.width)
        XCTAssertEqual(denoised.extent.height, testCIImage.extent.height)
    }

    func testNoiseReductionHighLevel() {
        let denoised = coreImageService.noiseReduction(ciImage: testCIImage, noiseLevel: 0.08, sharpness: 0.2)

        XCTAssertNotNil(denoised)
    }

    // MARK: - Pixellate Tests

    func testPixellate() {
        let pixelated = coreImageService.pixellate(ciImage: testCIImage, scale: 8)

        XCTAssertNotNil(pixelated)
        // Pixellate may slightly expand the image due to the tile pattern
        XCTAssertGreaterThanOrEqual(pixelated.extent.width, testCIImage.extent.width)
        XCTAssertGreaterThanOrEqual(pixelated.extent.height, testCIImage.extent.height)
    }

    func testPixellateMinScale() {
        let pixelated = coreImageService.pixellate(ciImage: testCIImage, scale: 1)

        XCTAssertNotNil(pixelated)
    }

    func testPixellateLargeScale() {
        let pixelated = coreImageService.pixellate(ciImage: testCIImage, scale: 50)

        XCTAssertNotNil(pixelated)
    }

    // MARK: - Comic Effect Tests

    func testComicEffect() {
        let comic = coreImageService.comicEffect(ciImage: testCIImage)

        XCTAssertNotNil(comic)
        // Comic effect may slightly expand the image
        XCTAssertGreaterThanOrEqual(comic.extent.width, testCIImage.extent.width)
        XCTAssertGreaterThanOrEqual(comic.extent.height, testCIImage.extent.height)
    }

    // MARK: - Halftone Tests

    func testHalftone() {
        let halftone = coreImageService.halftone(ciImage: testCIImage, width: 6, angle: 0, sharpness: 0.7)

        XCTAssertNotNil(halftone)
        // Halftone may slightly expand the image due to the dot pattern
        XCTAssertGreaterThanOrEqual(halftone.extent.width, testCIImage.extent.width)
        XCTAssertGreaterThanOrEqual(halftone.extent.height, testCIImage.extent.height)
    }

    func testHalftoneWithAngle() {
        let halftone = coreImageService.halftone(ciImage: testCIImage, width: 10, angle: 45, sharpness: 0.5)

        XCTAssertNotNil(halftone)
    }

    func testHalftoneLargeWidth() {
        let halftone = coreImageService.halftone(ciImage: testCIImage, width: 30, angle: 0, sharpness: 0.7)

        XCTAssertNotNil(halftone)
    }

    // MARK: - Photo Effect Mono Tests

    func testPhotoEffectMono() {
        let mono = coreImageService.photoEffectMono(ciImage: testCIImage)

        XCTAssertNotNil(mono)
        XCTAssertEqual(mono.extent.width, testCIImage.extent.width)
        XCTAssertEqual(mono.extent.height, testCIImage.extent.height)
    }

    // MARK: - Photo Effect Chrome Tests

    func testPhotoEffectChrome() {
        let chrome = coreImageService.photoEffectChrome(ciImage: testCIImage)

        XCTAssertNotNil(chrome)
        XCTAssertEqual(chrome.extent.width, testCIImage.extent.width)
        XCTAssertEqual(chrome.extent.height, testCIImage.extent.height)
    }

    // MARK: - Photo Effect Noir Tests

    func testPhotoEffectNoir() {
        let noir = coreImageService.photoEffectNoir(ciImage: testCIImage)

        XCTAssertNotNil(noir)
        XCTAssertEqual(noir.extent.width, testCIImage.extent.width)
        XCTAssertEqual(noir.extent.height, testCIImage.extent.height)
    }

    // MARK: - Photo Effect Instant Tests

    func testPhotoEffectInstant() {
        let instant = coreImageService.photoEffectInstant(ciImage: testCIImage)

        XCTAssertNotNil(instant)
        XCTAssertEqual(instant.extent.width, testCIImage.extent.width)
        XCTAssertEqual(instant.extent.height, testCIImage.extent.height)
    }

    // MARK: - Photo Effect Fade Tests

    func testPhotoEffectFade() {
        let fade = coreImageService.photoEffectFade(ciImage: testCIImage)

        XCTAssertNotNil(fade)
        XCTAssertEqual(fade.extent.width, testCIImage.extent.width)
        XCTAssertEqual(fade.extent.height, testCIImage.extent.height)
    }

    // MARK: - Photo Effect Process Tests

    func testPhotoEffectProcess() {
        let process = coreImageService.photoEffectProcess(ciImage: testCIImage)

        XCTAssertNotNil(process)
        XCTAssertEqual(process.extent.width, testCIImage.extent.width)
        XCTAssertEqual(process.extent.height, testCIImage.extent.height)
    }

    // MARK: - Photo Effect Transfer Tests

    func testPhotoEffectTransfer() {
        let transfer = coreImageService.photoEffectTransfer(ciImage: testCIImage)

        XCTAssertNotNil(transfer)
        XCTAssertEqual(transfer.extent.width, testCIImage.extent.width)
        XCTAssertEqual(transfer.extent.height, testCIImage.extent.height)
    }

    // MARK: - Vignette Tests

    func testVignette() {
        let vignetted = coreImageService.vignette(ciImage: testCIImage, intensity: 1.0)

        XCTAssertNotNil(vignetted)
        XCTAssertEqual(vignetted.extent.width, testCIImage.extent.width)
        XCTAssertEqual(vignetted.extent.height, testCIImage.extent.height)
    }

    func testVignetteWithRadius() {
        let vignetted = coreImageService.vignette(ciImage: testCIImage, intensity: 0.5, radius: 50)

        XCTAssertNotNil(vignetted)
    }

    func testVignetteHighIntensity() {
        let vignetted = coreImageService.vignette(ciImage: testCIImage, intensity: 2.0)

        XCTAssertNotNil(vignetted)
    }

    // MARK: - Filter Chain Tests

    func testFilterChainBlurAndMono() {
        var filtered = coreImageService.gaussianBlur(ciImage: testCIImage, radius: 5)
        filtered = coreImageService.photoEffectMono(ciImage: filtered)

        XCTAssertNotNil(filtered)
        XCTAssertEqual(filtered.extent.width, testCIImage.extent.width)
    }

    func testFilterChainSharpenAndSepia() {
        var filtered = coreImageService.sharpen(ciImage: testCIImage, sharpness: 0.5)
        filtered = coreImageService.sepiaTone(ciImage: filtered, intensity: 0.8)

        XCTAssertNotNil(filtered)
        XCTAssertEqual(filtered.extent.width, testCIImage.extent.width)
    }

    func testFilterChainPixelAndComic() {
        var filtered = coreImageService.pixellate(ciImage: testCIImage, scale: 4)
        filtered = coreImageService.comicEffect(ciImage: filtered)

        XCTAssertNotNil(filtered)
    }

    // MARK: - Edge Case Tests

    func testNegativeRadius() {
        // 负值应该被处理为 0
        let blurred = coreImageService.motionBlur(ciImage: testCIImage, radius: -10, angle: 0)
        XCTAssertNotNil(blurred)
    }

    func testZeroPixelScale() {
        // 0 会被处理为 1
        let pixelated = coreImageService.pixellate(ciImage: testCIImage, scale: 0)
        XCTAssertNotNil(pixelated)
    }

    func testExtremeNoiseLevel() {
        // 超出范围的值应该被正常处理
        let denoised = coreImageService.noiseReduction(ciImage: testCIImage, noiseLevel: 1.0, sharpness: 10)
        XCTAssertNotNil(denoised)
    }

    func testNegativeHalftoneAngle() {
        // 负角度应该正常工作
        let halftone = coreImageService.halftone(ciImage: testCIImage, width: 6, angle: -45, sharpness: 0.7)
        XCTAssertNotNil(halftone)
    }

    // MARK: - Render Tests

    func testRenderAfterMotionBlur() {
        let blurred = coreImageService.motionBlur(ciImage: testCIImage, radius: 10, angle: 45)
        let cgImage = coreImageService.render(ciImage: blurred)

        XCTAssertNotNil(cgImage)
        XCTAssertEqual(cgImage?.width, Int(testCIImage.extent.width))
    }

    func testRenderAfterComicEffect() {
        let comic = coreImageService.comicEffect(ciImage: testCIImage)
        let cgImage = coreImageService.render(ciImage: comic)

        XCTAssertNotNil(cgImage)
    }

    func testRenderAfterMultipleFilters() {
        var filtered = coreImageService.gaussianBlur(ciImage: testCIImage, radius: 3)
        filtered = coreImageService.photoEffectChrome(ciImage: filtered)
        filtered = coreImageService.vignette(ciImage: filtered, intensity: 0.5)

        let cgImage = coreImageService.render(ciImage: filtered)

        XCTAssertNotNil(cgImage)
        XCTAssertEqual(cgImage?.width, Int(testCIImage.extent.width))
    }
}
