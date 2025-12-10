import CoreImage
import CoreGraphics
import Metal
import Foundation

/// CoreImage 底层操作协议（用于依赖注入和测试 Mock）
protocol CoreImageOperations {
    /// 创建 CIContext
    func createContext(with device: MTLDevice?, options: [CIContextOption: Any]?) -> CIContext

    /// 获取系统默认 Metal 设备
    func getDefaultMetalDevice() -> MTLDevice?
}

/// CoreImage 默认实现（调用真实的 CoreImage/Metal API）
struct DefaultCoreImageOperations: CoreImageOperations, Sendable {
    func createContext(with device: MTLDevice?, options: [CIContextOption: Any]?) -> CIContext {
        if let device = device {
            return CIContext(mtlDevice: device, options: options)
        } else {
            return CIContext(options: options)
        }
    }

    func getDefaultMetalDevice() -> MTLDevice? {
        MTLCreateSystemDefaultDevice()
    }
}
