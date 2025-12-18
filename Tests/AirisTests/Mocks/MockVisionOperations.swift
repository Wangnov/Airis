import Foundation
import Vision
#if !XCODE_BUILD
    @testable import AirisCore
#endif

/// Mock Vision 操作 - 用于测试错误路径
final class MockVisionOperations: VisionOperations {
    let shouldFail: Bool
    let errorMessage: String
    let shouldReturnNilResults: Bool
    let shouldReturnEmptyResults: Bool

    init(
        shouldFail: Bool = false,
        errorMessage: String = "Mock Vision error",
        shouldReturnNilResults: Bool = false,
        shouldReturnEmptyResults: Bool = false
    ) {
        self.shouldFail = shouldFail
        self.errorMessage = errorMessage
        self.shouldReturnNilResults = shouldReturnNilResults
        self.shouldReturnEmptyResults = shouldReturnEmptyResults
    }

    func perform(requests: [VNRequest], on handler: VNImageRequestHandler) throws {
        if shouldFail {
            throw NSError(domain: "MockVisionError", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        // 模拟 nil results（触发 ?? [] 路径）
        if shouldReturnNilResults {
            // 不设置 results（保持为 nil）
            return
        }

        // 模拟空 results（触发 results.first == nil 路径）
        if shouldReturnEmptyResults {
            // Vision requests 默认 results 为空，直接返回
            return
        }

        // 正常情况：让真实的 handler 执行
        try handler.perform(requests)
    }
}
