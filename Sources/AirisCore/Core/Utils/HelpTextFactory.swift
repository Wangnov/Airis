import ArgumentParser

/// CLI help 文本生成工具。
///
/// 说明：ArgumentParser 的 help 文本会在参数解析早期被构建，
/// 因此这里使用 `Language.current` 来在运行时选择中英文。
enum HelpTextFactory {
    static func text(en: String, cn: String) -> String {
        Language.current == .cn ? cn : en
    }

    /// 返回 `ArgumentHelp`，用于 `@Flag/@Option/@Argument` 等需要 help 类型的场景。
    ///
    /// 注意：`ArgumentHelp` 支持字符串字面量，但不支持从运行时 `String` 隐式转换。
    static func help(en: String, cn: String) -> ArgumentHelp {
        ArgumentHelp(text(en: en, cn: cn))
    }
}
