import ArgumentParser
import Foundation

/// 支持的语言枚举
///
/// ## 并发安全说明
/// `Language.current` 使用 `nonisolated(unsafe)` 是 Swift 6 中处理全局配置的标准做法：
/// - **生产环境**：在 `Root.configuration` 和 `Root.validate()` 中设置，之后只读
/// - **测试环境**：测试用例可能在 setUp/tearDown 中修改，但测试是串行执行的
enum Language: String, ExpressibleByArgument, CaseIterable, Sendable {
    case en
    case cn

    /// 当前激活的语言
    /// - Note: 仅在 `Root.configuration` 和 `Root.validate()` 中设置，之后只读。
    nonisolated(unsafe) static var current: Language = .en

    /// 从系统语言环境自动检测
    static var fromSystem: Language {
        fromSystemLanguages(Locale.preferredLanguages)
    }

    /// 从语言列表中检测（可测试的内部方法）
    static func fromSystemLanguages(_ languages: [String]) -> Language {
        let preferred = languages.first ?? "en"
        return preferred.hasPrefix("zh") ? .cn : .en
    }

    /// 从环境变量读取
    static var fromEnvironment: Language? {
        guard let envLang = ProcessInfo.processInfo.environment["AIRIS_LANG"] else {
            return nil
        }
        return Language(rawValue: envLang.lowercased())
    }

    /// 按优先级解析语言设置: 参数 > 环境变量 > 系统语言
    static func resolve(explicit: Language?) -> Language {
        if let explicit {
            return explicit
        }
        if let fromEnv = fromEnvironment {
            return fromEnv
        }
        return fromSystem
    }
}
