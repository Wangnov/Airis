import ArgumentParser
import Foundation

/// 支持的语言枚举
enum Language: String, ExpressibleByArgument, CaseIterable, Sendable {
    case en
    case cn

    /// 当前激活的语言
    nonisolated(unsafe) static var current: Language = .en

    /// 从系统语言环境自动检测
    static var fromSystem: Language {
        let preferred = Locale.preferredLanguages.first ?? "en"
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
        if let explicit = explicit {
            return explicit
        }
        if let fromEnv = fromEnvironment {
            return fromEnv
        }
        return fromSystem
    }
}
