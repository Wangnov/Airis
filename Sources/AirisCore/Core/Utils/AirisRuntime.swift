import Foundation

/// 运行时全局配置。
///
/// ## 并发安全说明
/// 这些配置仅在以下情况下被设置：
/// 1. **生产环境**：程序启动时由 `Root.validate()` 设置一次，之后仅只读
/// 2. **测试环境**：测试用例可能在 setUp/tearDown 中修改，但测试是串行执行的
///
/// 使用 `nonisolated(unsafe)` 是 Swift 6 中处理此类全局配置的标准做法，
/// 因为这些值在正常使用中不会被并发修改。
enum AirisRuntime {
    /// 是否开启 verbose 输出。
    /// - Note: 仅在 `Root.validate()` 中设置，之后只读。
    nonisolated(unsafe) static var isVerbose: Bool = false

    /// 是否开启 quiet 模式（仅显示错误）。
    /// - Note: 仅在 `Root.validate()` 中设置，之后只读。
    nonisolated(unsafe) static var isQuiet: Bool = false
}

/// 统一的调试/详细日志输出。
/// 默认写入 stderr，避免污染 JSON 等机器可读 stdout。
enum AirisLog {
    static func debug(_ message: String) {
        guard AirisRuntime.isVerbose, !AirisRuntime.isQuiet else {
            return
        }
        let text = "[verbose] \(message)\n"
        if let data = text.data(using: .utf8) {
            FileHandle.standardError.write(data)
        }
    }
}
