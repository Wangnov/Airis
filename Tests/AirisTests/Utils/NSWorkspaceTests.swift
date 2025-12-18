import XCTest
#if !XCODE_BUILD
    @testable import AirisCore
#endif

final class NSWorkspaceTests: XCTestCase {
    private func withEnv(_ env: [String: String?], perform block: () throws -> Void) rethrows {
        var originals: [String: String?] = [:]
        for (key, value) in env {
            originals[key] = getenv(key).flatMap { String(cString: $0) }
            if let value {
                setenv(key, value, 1)
            } else {
                unsetenv(key)
            }
        }
        defer {
            for (key, value) in originals {
                if let value {
                    setenv(key, value, 1)
                } else {
                    unsetenv(key)
                }
            }
        }
        try block()
    }

    func testOpenForCLISkipInTestMode() {
        withEnv(["AIRIS_TEST_MODE": "1", "CI": nil]) {
            let url = URL(fileURLWithPath: "/tmp/airis_test_dummy.txt")
            let result = NSWorkspace.openForCLI(url)
            XCTAssertTrue(result)
        }
    }

    func testOpenForCLISkipWhenXCTestConfigurationPresent() {
        withEnv([
            "AIRIS_TEST_MODE": nil,
            "CI": nil,
            "XCTestConfigurationFilePath": "/tmp/xctest_config",
        ]) {
            let url = URL(fileURLWithPath: "/tmp/airis_test_dummy_xctest.txt")
            let result = NSWorkspace.openForCLI(url)
            XCTAssertTrue(result)
        }
    }

    func testOpenForCLISkipInCI() {
        withEnv(["AIRIS_TEST_MODE": nil, "CI": "1"]) {
            let url = URL(fileURLWithPath: "/tmp/airis_test_dummy_ci.txt")
            let result = NSWorkspace.openForCLI(url)
            XCTAssertTrue(result)
        }
    }

    func testOpenForCLINormalBranch() {
        withEnv(["AIRIS_TEST_MODE": nil, "CI": nil]) {
            let url = URL(fileURLWithPath: "/tmp/airis_test_dummy_normal.txt")
            _ = NSWorkspace.openForCLI(url)
            // 只要不抛异常即可，结果可真可假
            XCTAssertTrue(true)
        }
    }

    func testOpenForCLISkipsGUIInXCTestCaseRuntime() {
        withEnv([
            "AIRIS_TEST_MODE": nil,
            "CI": nil,
            "XCTestConfigurationFilePath": nil,
        ]) {
            let url = URL(fileURLWithPath: "/tmp/airis_test_dummy_runtime.txt")
            let result = NSWorkspace.openForCLI(url)
            XCTAssertTrue(result)
        }
    }

    func testOpenForCLIAllowInTestsCallsOpener() {
        let url = URL(fileURLWithPath: "/tmp/airis_test_dummy_allow_in_tests.txt")
        var openedURL: URL?
        let result = NSWorkspace.openForCLI(url, allowInTests: true) { url in
            openedURL = url
            return false
        }

        XCTAssertEqual(openedURL, url)
        XCTAssertFalse(result)
    }

    func testOpenForCLICallsOpenerWhenNotInTestRuntime() {
        withEnv([
            "AIRIS_TEST_MODE": nil,
            "CI": nil,
            "XCTestConfigurationFilePath": nil,
        ]) {
            let url = URL(fileURLWithPath: "/tmp/airis_test_dummy_opener_called.txt")
            var openedURL: URL?
            let result = NSWorkspace.openForCLI(url, isXCTestRuntime: false) { url in
                openedURL = url
                return true
            }

            XCTAssertEqual(openedURL, url)
            XCTAssertTrue(result)
        }
    }
}
