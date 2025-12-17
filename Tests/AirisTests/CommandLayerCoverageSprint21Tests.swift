import XCTest
#if !XCODE_BUILD
@testable import AirisCore
#endif

/// 第二十一批覆盖冲刺：Cut 渲染 nil 分支、Persons 默认质量分支。
final class CommandLayerCoverageSprint21Tests: XCTestCase {
    override func setUp() {
        super.setUp()
        setenv("AIRIS_TEST_MODE", "1", 1)
    }

    override func tearDown() {
        unsetenv("AIRIS_TEST_MODE")
        super.tearDown()
    }

    func testCutCommandRenderNilGuard() async {
        setenv("AIRIS_FORCE_CUT_RENDER_NIL", "1", 1)
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")

        await XCTAssertThrowsErrorAsync(
            try await CutCommand.parse([input, "-o", out.path]).run()
        )

        unsetenv("AIRIS_FORCE_CUT_RENDER_NIL")
        CommandTestHarness.cleanup(out)
    }

    func testPersonsCommandDefaultQualityBranch() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        setenv("AIRIS_TEST_PERSONS_FAKE_RESULT", "1", 1)
        // 传递未知质量字符串，走 default 分支（balanced）
        try await PersonsCommand.parse([input, "--quality", "ultra", "--format", "json"]).run()
        unsetenv("AIRIS_TEST_PERSONS_FAKE_RESULT")
    }

    func testPersonsCommandFakeResultPixelBufferFallbackBranch() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        setenv("AIRIS_TEST_PERSONS_FAKE_RESULT", "1", 1)
        setenv("AIRIS_FORCE_PERSONS_TEST_PIXELBUFFER_FAIL", "1", 1)
        try await PersonsCommand.parse([input, "--format", "json"]).run()
        unsetenv("AIRIS_FORCE_PERSONS_TEST_PIXELBUFFER_FAIL")
        unsetenv("AIRIS_TEST_PERSONS_FAKE_RESULT")
    }
}

// MARK: - Async helper

private func XCTAssertThrowsErrorAsync(
    _ expression: @autoclosure @escaping () async throws -> Void,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        try await expression()
        XCTFail("预期抛出错误", file: file, line: line)
    } catch { }
}
