import Foundation

/// 统一的输出策略（stdout / stderr / 静默 / 测试模式）。
enum AirisOutput {
    static var isTestMode: Bool {
        if ProcessInfo.processInfo.environment["AIRIS_TEST_ALLOW_STDOUT"] == "1" {
            return false
        }
        if ProcessInfo.processInfo.environment["AIRIS_TEST_MODE"] == "1" {
            return true
        }
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            return true
        }
        return NSClassFromString("XCTestCase") != nil
    }

    static func shouldPrintHumanOutput(format: OutputFormat) -> Bool {
        if AirisRuntime.isQuiet {
            return false
        }
        return format == .table
    }

    static func printBanner(_ lines: [String], enabled: Bool) {
        guard enabled else { return }
        for line in lines {
            print(line)
        }
        print("")
    }
}
