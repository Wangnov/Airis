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
        case .normal: return CIFilter.gaussianBlur()
        case .nilFilter: return nil
        case .nilOutput: return NullOutputFilter()
        }
    }

    func motionBlur() -> CIFilter? {
        switch motionBehavior {
        case .normal: return CIFilter.motionBlur()
        case .nilFilter: return nil
        case .nilOutput: return NullOutputFilter()
        }
    }

    func zoomBlur() -> CIFilter? {
        switch zoomBehavior {
        case .normal: return CIFilter.zoomBlur()
        case .nilFilter: return nil
        case .nilOutput: return NullOutputFilter()
        }
    }

    func perspectiveCorrection() -> CIFilter? {
        switch perspectiveBehavior {
        case .normal: return CIFilter(name: "CIPerspectiveCorrection")
        case .nilFilter: return nil
        case .nilOutput: return NullOutputFilter()
        }
    }

    func hueAdjust() -> CIFilter? {
        switch hueBehavior {
        case .normal: return CIFilter(name: "CIHueAdjust")
        case .nilFilter: return nil
        case .nilOutput: return NullOutputFilter()
        }
    }

    func colorThreshold() -> CIFilter? {
        switch thresholdBehavior {
        case .normal: return CIFilter(name: "CIColorThreshold")
        case .nilFilter: return nil
        case .nilOutput: return NullOutputFilter()
        }
    }
}

/// 一个输出始终为 nil 的滤镜，用于触发 guard 分支
final class NullOutputFilter: CIFilter {
    override func setValue(_ value: Any?, forKey key: String) {
        // 忽略所有输入，确保兼容 KVC 调用
    }

    override var outputImage: CIImage? { nil }
}
