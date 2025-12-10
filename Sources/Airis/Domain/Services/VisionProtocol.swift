import Vision
import CoreImage
import Foundation

/// Vision 框架底层操作协议（用于依赖注入和测试 Mock）
protocol VisionOperations {
    /// 执行 Vision 请求
    func perform(requests: [VNRequest], on handler: VNImageRequestHandler) throws
}

/// Vision 默认实现（调用真实的 Vision framework）
struct DefaultVisionOperations: VisionOperations, Sendable {
    func perform(requests: [VNRequest], on handler: VNImageRequestHandler) throws {
        try handler.perform(requests)
    }
}
