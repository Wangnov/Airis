import Foundation

/// 在单元测试中默认抑制 stdout 噪音（banner/进度条等），避免影响 `make test/cov` 体验。
///
/// - Note: 不影响 stderr（`AirisLog.debug` 等仍会输出到 stderr）。
func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    if AirisOutput.isTestMode {
        return
    }
    let text = items.map { String(describing: $0) }.joined(separator: separator)
    Swift.print(text, terminator: terminator)
}
