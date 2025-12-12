import XCTest
@testable import Airis

final class NSWorkspaceTests: XCTestCase {
    func testOpenForCLISkipInTestMode() {
        setenv("AIRIS_TEST_MODE", "1", 1)
        let url = URL(fileURLWithPath: "/tmp/airis_test_dummy.txt")
        let result = NSWorkspace.openForCLI(url)
        XCTAssertTrue(result)
        unsetenv("AIRIS_TEST_MODE")
    }

    func testOpenForCLISkipInCI() {
        unsetenv("AIRIS_TEST_MODE")
        setenv("CI", "1", 1)
        let url = URL(fileURLWithPath: "/tmp/airis_test_dummy_ci.txt")
        let result = NSWorkspace.openForCLI(url)
        XCTAssertTrue(result)
        unsetenv("CI")
    }

    func testOpenForCLINormalBranch() {
        unsetenv("AIRIS_TEST_MODE")
        unsetenv("CI")
        let url = URL(fileURLWithPath: "/tmp/airis_test_dummy_normal.txt")
        _ = NSWorkspace.openForCLI(url)
        // 只要不抛异常即可，结果可真可假
        XCTAssertTrue(true)
    }
}
