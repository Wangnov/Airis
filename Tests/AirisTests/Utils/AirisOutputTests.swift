import XCTest
#if !XCODE_BUILD
    @testable import AirisCore
#endif
import Darwin
import Foundation

final class AirisOutputTests: XCTestCase {
    private var originalAllowStdout: String?
    private var originalTestMode: String?
    private var originalXCTestConfig: String?
    private var originalIsQuiet: Bool = false

    override func setUp() {
        super.setUp()
        originalAllowStdout = getenv("AIRIS_TEST_ALLOW_STDOUT").flatMap { String(cString: $0) }
        originalTestMode = getenv("AIRIS_TEST_MODE").flatMap { String(cString: $0) }
        originalXCTestConfig = getenv("XCTestConfigurationFilePath").flatMap { String(cString: $0) }
        unsetenv("AIRIS_TEST_ALLOW_STDOUT")
        unsetenv("AIRIS_TEST_MODE")
        unsetenv("XCTestConfigurationFilePath")
        originalIsQuiet = AirisRuntime.isQuiet
        AirisRuntime.isQuiet = false
    }

    override func tearDown() {
        if let originalAllowStdout {
            setenv("AIRIS_TEST_ALLOW_STDOUT", originalAllowStdout, 1)
        } else {
            unsetenv("AIRIS_TEST_ALLOW_STDOUT")
        }
        if let originalTestMode {
            setenv("AIRIS_TEST_MODE", originalTestMode, 1)
        } else {
            unsetenv("AIRIS_TEST_MODE")
        }
        if let originalXCTestConfig {
            setenv("XCTestConfigurationFilePath", originalXCTestConfig, 1)
        } else {
            unsetenv("XCTestConfigurationFilePath")
        }
        AirisRuntime.isQuiet = originalIsQuiet
        super.tearDown()
    }

    private func withCapturedStdout(_ work: () -> Void) -> String {
        fflush(stdout)

        let originalStdout = dup(STDOUT_FILENO)
        let pipe = Pipe()
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)

        work()

        fflush(stdout)
        pipe.fileHandleForWriting.closeFile()
        dup2(originalStdout, STDOUT_FILENO)
        close(originalStdout)

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }

    func testPrintBannerIsSuppressedInTestsByDefault() {
        XCTAssertTrue(AirisOutput.isTestMode)
        AirisOutput.printBanner(["test"], enabled: true)
    }

    func testPrintBannerCanBeEnabledForCoverage() {
        setenv("AIRIS_TEST_ALLOW_STDOUT", "1", 1)
        XCTAssertFalse(AirisOutput.isTestMode)

        let output = withCapturedStdout {
            AirisOutput.printBanner(["test"], enabled: true)
        }
        XCTAssertTrue(output.contains("test"))
    }

    func testIsTestModeCanBeForcedByEnvVar() {
        setenv("AIRIS_TEST_MODE", "1", 1)
        XCTAssertTrue(AirisOutput.isTestMode)
    }

    func testIsTestModeCanBeDetectedByXCTestConfiguration() {
        setenv("XCTestConfigurationFilePath", "/tmp/xctest_config", 1)
        XCTAssertTrue(AirisOutput.isTestMode)
    }

    func testShouldPrintHumanOutputTableOnly() {
        setenv("AIRIS_TEST_ALLOW_STDOUT", "1", 1)
        XCTAssertTrue(AirisOutput.shouldPrintHumanOutput(format: .table))
        XCTAssertFalse(AirisOutput.shouldPrintHumanOutput(format: .json))
        XCTAssertFalse(AirisOutput.shouldPrintHumanOutput(format: .text))
    }

    func testShouldPrintHumanOutputRespectsQuietMode() {
        setenv("AIRIS_TEST_ALLOW_STDOUT", "1", 1)
        AirisRuntime.isQuiet = true
        XCTAssertFalse(AirisOutput.shouldPrintHumanOutput(format: .table))
    }

    func testOutputFormatParseFallbacksToTable() {
        XCTAssertEqual(OutputFormat.parse("json"), .json)
        XCTAssertEqual(OutputFormat.parse("JSON"), .json)
        XCTAssertEqual(OutputFormat.parse("text"), .text)
        XCTAssertEqual(OutputFormat.parse("table"), .table)
        XCTAssertEqual(OutputFormat.parse("unknown"), .table)
    }

    func testPrintBannerGuardDisabled() {
        AirisOutput.printBanner(["should not print"], enabled: false)
    }
}
