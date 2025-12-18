import CoreImage
import CoreImage.CIFilterBuiltins
#if !XCODE_BUILD
    @testable import AirisCore
#endif

/// 可控输出的滤镜工厂，用于触发 CoreImageService 的防御分支
struct MockCoreImageFilterFactory: CoreImageFilterFactory {
    enum Behavior {
        case normal
        case nilFilter
        case nilOutput
    }

    var gaussianBehavior: Behavior = .normal
    var motionBehavior: Behavior = .normal
    var zoomBehavior: Behavior = .normal
    var perspectiveBehavior: Behavior = .normal
    var hueBehavior: Behavior = .normal
    var thresholdBehavior: Behavior = .normal

    func gaussianBlur() -> CIFilter? {
        switch gaussianBehavior {
        case .normal: CIFilter.gaussianBlur()
        case .nilFilter: nil
        case .nilOutput: NullOutputFilter()
        }
    }

    func motionBlur() -> CIFilter? {
        switch motionBehavior {
        case .normal: CIFilter.motionBlur()
        case .nilFilter: nil
        case .nilOutput: NullOutputFilter()
        }
    }

    func zoomBlur() -> CIFilter? {
        switch zoomBehavior {
        case .normal: CIFilter.zoomBlur()
        case .nilFilter: nil
        case .nilOutput: NullOutputFilter()
        }
    }

    func perspectiveCorrection() -> CIFilter? {
        switch perspectiveBehavior {
        case .normal: CIFilter(name: "CIPerspectiveCorrection")
        case .nilFilter: nil
        case .nilOutput: NullOutputFilter()
        }
    }

    func hueAdjust() -> CIFilter? {
        switch hueBehavior {
        case .normal: CIFilter(name: "CIHueAdjust")
        case .nilFilter: nil
        case .nilOutput: NullOutputFilter()
        }
    }

    func colorThreshold() -> CIFilter? {
        switch thresholdBehavior {
        case .normal: CIFilter(name: "CIColorThreshold")
        case .nilFilter: nil
        case .nilOutput: NullOutputFilter()
        }
    }
}

/// 一个输出始终为 nil 的滤镜，用于触发 guard 分支
final class NullOutputFilter: CIFilter {
    override func setValue(_: Any?, forKey _: String) {
        // 忽略所有输入，确保兼容 KVC 调用
    }

    override var outputImage: CIImage? { nil }
}
