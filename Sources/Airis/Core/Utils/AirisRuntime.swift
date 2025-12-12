import Foundation

/// 运行时全局配置。
///
/// 该配置只在程序启动解析参数后设置一次，之后仅只读，
/// 因此用 nonisolated(unsafe) 作为轻量并发标注。
enum AirisRuntime {
    /// 是否开启 verbose 输出。
    nonisolated(unsafe) static var isVerbose: Bool = false

    /// 是否开启 quiet 模式（仅显示错误）。
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
