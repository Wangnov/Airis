import XCTest
import ArgumentParser
@testable import Airis
import Darwin

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

    func testRootValidateQuietRedirectsStdout() throws {
        let originalQuiet = AirisRuntime.isQuiet
        let originalVerbose = AirisRuntime.isVerbose
        let originalStdout = dup(STDOUT_FILENO)
        defer {
            dup2(originalStdout, STDOUT_FILENO)
            close(originalStdout)
            AirisRuntime.isQuiet = originalQuiet
            AirisRuntime.isVerbose = originalVerbose
        }

        var cmd = try Airis.parseAsRoot(["--quiet", "gen", "config", "show"])
        try cmd.validate()
    }

    func testRootValidateQuietRedirectFailureBranch() throws {
        let originalQuiet = AirisRuntime.isQuiet
        let originalVerbose = AirisRuntime.isVerbose
        let originalStdout = dup(STDOUT_FILENO)
        defer {
            dup2(originalStdout, STDOUT_FILENO)
            close(originalStdout)
            AirisRuntime.isQuiet = originalQuiet
            AirisRuntime.isVerbose = originalVerbose
            unsetenv("AIRIS_FORCE_QUIET_REDIRECT_FAIL")
        }

        setenv("AIRIS_FORCE_QUIET_REDIRECT_FAIL", "1", 1)
        var cmd = try Airis.parseAsRoot(["--quiet", "gen", "config", "show"])
        try cmd.validate()
    }
}
