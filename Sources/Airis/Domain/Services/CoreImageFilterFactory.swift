import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

/// 滤镜工厂，便于测试时返回自定义或空滤镜以覆盖防御分支
protocol CoreImageFilterFactory {
    func gaussianBlur() -> CIFilter?
    func motionBlur() -> CIFilter?
    func zoomBlur() -> CIFilter?
    func perspectiveCorrection() -> CIFilter?
    func hueAdjust() -> CIFilter?
    func colorThreshold() -> CIFilter?
}

struct DefaultCoreImageFilterFactory: CoreImageFilterFactory {
    func gaussianBlur() -> CIFilter? { CIFilter.gaussianBlur() }
    func motionBlur() -> CIFilter? { CIFilter.motionBlur() }
    func zoomBlur() -> CIFilter? { CIFilter.zoomBlur() }
    func perspectiveCorrection() -> CIFilter? { CIFilter(name: "CIPerspectiveCorrection") }
    func hueAdjust() -> CIFilter? { CIFilter(name: "CIHueAdjust") }
    func colorThreshold() -> CIFilter? { CIFilter(name: "CIColorThreshold") }
}
