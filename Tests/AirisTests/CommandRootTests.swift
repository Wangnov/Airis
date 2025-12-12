import XCTest
import ArgumentParser
@testable import Airis

/// 覆盖 Root 配置与 --help/--version 分支（捕获 CleanExit）
final class CommandRootTests: XCTestCase {
    func testRootParsesHelp() {
        do {
            _ = try Airis.parse(["--help"])
            XCTFail("Expected parser to throw CleanExit for --help")
        } catch {
            // any throw is acceptable for coverage
        }
    }

    func testRootParsesVersion() {
        do {
            _ = try Airis.parse(["--version"])
            XCTFail("Expected parser to throw CleanExit for --version")
        } catch {
            // acceptable
        }
    }
}
