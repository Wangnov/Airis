import Foundation

/// 解析 ArgumentParser 之前需要用到的少量参数。
///
/// 目的：让 `--help` 在解析阶段就能依据 `--lang` 或 `AIRIS_LANG` 选择语言。
enum ArgumentPreparser {
    /// 预解析 `--lang`（支持 `--lang cn` 与 `--lang=cn`）。
    ///
    /// - Note: 只用于早期 help 文本选择；真实业务仍以 ArgumentParser 解析结果为准。
    static func parseLang(from args: [String]) -> Language? {
        var parsed: Language?

        // 跳过 argv[0]（可执行文件路径）。
        for (index, arg) in args.enumerated() where index > 0 {
            if arg == "--lang" {
                let nextIndex = index + 1
                guard nextIndex < args.count else { continue }
                parsed = Language(rawValue: args[nextIndex].lowercased())
                continue
            }

            if arg.hasPrefix("--lang=") {
                let value = String(arg.dropFirst("--lang=".count))
                parsed = Language(rawValue: value.lowercased())
                continue
            }
        }

        return parsed
    }
}
