import AppKit
import Foundation

extension NSWorkspace {
    /// 在 CLI 环境下打开文件。
    ///
    /// - 默认在 XCTest/CI/测试模式下跳过实际打开，避免跑测时弹出 GUI 窗口。
    /// - `allowInTests` 仅用于测试覆盖（配合注入 `opener`），正常业务代码不要使用。
    @discardableResult
    static func openForCLI(
        _ url: URL,
        allowInTests: Bool = false,
        isXCTestRuntime: Bool = NSClassFromString("XCTestCase") != nil,
        opener: (URL) -> Bool = NSWorkspace.shared.open
    ) -> Bool {
        if !allowInTests {
            // 在 CI/无头环境下跳过实际打开，避免 GUI 依赖。
            if ProcessInfo.processInfo.environment["CI"] == "1" {
                return true
            }

            // 显式测试模式：跳过打开（也用于命令层覆盖测试）。
            if ProcessInfo.processInfo.environment["AIRIS_TEST_MODE"] == "1" {
                AirisLog.debug("(test mode: skip open \(url.lastPathComponent))")
                return true
            }

            // 部分环境下并不会设置 XCTestConfigurationFilePath，所以不能只依赖该变量。
            if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
                return true
            }

            // 在跑单元测试时，无论环境变量是否被其它并发用例临时 unset，都必须跳过 GUI 副作用。
            if isXCTestRuntime {
                return true
            }
        }

        return opener(url)
    }
}
