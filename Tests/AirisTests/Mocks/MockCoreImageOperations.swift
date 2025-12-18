import CoreGraphics
import CoreImage
import Foundation
import Metal
#if !XCODE_BUILD
    @testable import AirisCore
#endif

/// Mock CoreImage 操作 - 用于测试 Metal 不可用的场景
final class MockCoreImageOperations: CoreImageOperations {
    let shouldReturnNilMetalDevice: Bool

    init(shouldReturnNilMetalDevice: Bool = false) {
        self.shouldReturnNilMetalDevice = shouldReturnNilMetalDevice
    }

    func createContext(with device: MTLDevice?, options: [CIContextOption: Any]?) -> CIContext {
        if let device {
            CIContext(mtlDevice: device, options: options)
        } else {
            CIContext(options: options)
        }
    }

    func getDefaultMetalDevice() -> MTLDevice? {
        if shouldReturnNilMetalDevice {
            return nil // 模拟 Metal 不可用
        }
        return MTLCreateSystemDefaultDevice()
    }
}
