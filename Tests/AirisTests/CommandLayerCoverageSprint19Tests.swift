import XCTest
#if !XCODE_BUILD
@testable import AirisCore
#endif

/// 第十九批覆盖冲刺：Noise 渲染失败、Trace 渲染失败/输出存在、Cut 输出存在。
final class CommandLayerCoverageSprint19Tests: XCTestCase {
    // MARK: Noise
    func testNoiseRenderFailBranch() async {
        setenv("AIRIS_FORCE_NOISE_RENDER_FAIL", "1", 1)
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")

        await XCTAssertThrowsErrorAsync(
            try await NoiseCommand.parse([input, "-o", out.path]).run()
        )

        unsetenv("AIRIS_FORCE_NOISE_RENDER_FAIL")
        CommandTestHarness.cleanup(out)
    }

    // MARK: Trace
    func testTraceRenderFailBranch() async {
        setenv("AIRIS_FORCE_TRACE_RENDER_FAIL", "1", 1)
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")

        await XCTAssertThrowsErrorAsync(
            try await TraceCommand.parse([input, "-o", out.path, "--style", "edges"]).run()
        )

        unsetenv("AIRIS_FORCE_TRACE_RENDER_FAIL")
        CommandTestHarness.cleanup(out)
    }

    func testTraceOutputExistsThrows() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        FileManager.default.createFile(atPath: out.path, contents: Data())

        await XCTAssertThrowsErrorAsync(
            try await TraceCommand.parse([input, "-o", out.path]).run()
        )

        CommandTestHarness.cleanup(out)
    }

    // MARK: Cut 输出已存在
    func testCutOutputExistsThrows() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        FileManager.default.createFile(atPath: out.path, contents: Data())

        await XCTAssertThrowsErrorAsync(
            try await CutCommand.parse([input, "-o", out.path]).run()
        )

        CommandTestHarness.cleanup(out)
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
