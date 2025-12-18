import XCTest
#if !XCODE_BUILD
    @testable import AirisCore
#endif

/// 第十六批覆盖冲刺：补齐 Tag 命令分支（table/json 总数分支）。
final class CommandLayerCoverageSprint16Tests: XCTestCase {
    override func setUp() {
        super.setUp()
        setenv("AIRIS_FORCE_TAG_STUB", "1", 1)
    }

    override func tearDown() {
        unsetenv("AIRIS_FORCE_TAG_STUB")
        super.tearDown()
    }

    func testTagCommandStubLimitedResultsShowsTruncatedTable() async throws {
        // limit=2 => results.count(2) < total(5) 分支
        let img = CommandTestHarness.fixture("small_100x100.png").path
        let cmd = try TagCommand.parse([img, "--threshold", "0.0", "--limit", "2", "--format", "table"])
        try await cmd.run()
    }

    func testTagCommandStubAllResultsJsonBranch() async throws {
        // limit=10 => results.count == total 分支 + JSON 输出
        let img = CommandTestHarness.fixture("medium_512x512.jpg").path
        let cmd = try TagCommand.parse([img, "--threshold", "0.0", "--limit", "10", "--format", "json"])
        try await cmd.run()
    }

    func testTagCommandStubAllResultsTableBranch() async throws {
        // limit=10 + table => 覆盖 results.count == total 的表格分支
        let img = CommandTestHarness.fixture("medium_512x512.jpg").path
        let cmd = try TagCommand.parse([img, "--threshold", "0.0", "--limit", "10", "--format", "table"])
        try await cmd.run()
    }
}
