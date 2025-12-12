import XCTest
@testable import Airis

/// 第十八批覆盖冲刺：Cut 渲染失败、Format/Noise 参数异常。
final class CommandLayerCoverageSprint18Tests: XCTestCase {
    // MARK: Cut
    func testCutCommandRenderFailBranch() async {
        setenv("AIRIS_FORCE_CUT_RENDER_FAIL", "1", 1)
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")

        await XCTAssertThrowsErrorAsync(
            try await CutCommand.parse([input, "-o", out.path]).run()
        )

        unsetenv("AIRIS_FORCE_CUT_RENDER_FAIL")
        CommandTestHarness.cleanup(out)
    }

    // MARK: Format
    func testFormatCommandInvalidQualityThrows() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "jpg")

        await XCTAssertThrowsErrorAsync(
            try await FormatCommand.parse([input, "-o", out.path, "--format", "jpg", "--quality", "1.5"]).run()
        )

        CommandTestHarness.cleanup(out)
    }

    func testFormatCommandInvalidFormatThrows() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "webp")

        await XCTAssertThrowsErrorAsync(
            try await FormatCommand.parse([input, "-o", out.path, "--format", "bmp"]).run()
        )

        CommandTestHarness.cleanup(out)
    }

    // MARK: Noise
    func testNoiseCommandInvalidLevelThrows() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")

        await XCTAssertThrowsErrorAsync(
            try await NoiseCommand.parse([input, "-o", out.path, "--level", "-0.1"]).run()
        )

        CommandTestHarness.cleanup(out)
    }

    func testNoiseCommandInvalidSharpnessThrows() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")

        await XCTAssertThrowsErrorAsync(
            try await NoiseCommand.parse([input, "-o", out.path, "--sharpness", "3.1"]).run()
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
