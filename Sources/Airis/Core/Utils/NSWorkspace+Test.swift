import AppKit
import Foundation

extension NSWorkspace {
    /// 在测试模式下跳过实际打开文件，避免 UI 弹窗；正常模式保持原行为。
    @discardableResult
    static func openForCLI(_ url: URL) -> Bool {
        // XCTest 环境统一跳过，避免本地/CI 跑测时弹出空窗口
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            return true
        }
        if ProcessInfo.processInfo.environment["AIRIS_TEST_MODE"] == "1" {
            print("(test mode: skip open \(url.lastPathComponent))")
            return true
        }
        // 在 CI/无头环境下仍然跳过实际打开，避免 GUI 依赖
        if ProcessInfo.processInfo.environment["CI"] == "1" {
            return true
        }
        return NSWorkspace.shared.open(url)
    }
}
