import XCTest
@testable import Airis

/// 第八批覆盖补齐：聚焦滤镜参数错误、输出格式错误，以及 Draw/Config 交互分支。
final class CommandLayerCoverageSprint8Tests: XCTestCase {
    override func tearDown() {
        let envs = [
            "AIRIS_GEN_STUB",
            "AIRIS_TEST_MODE",
            "AIRIS_FORCE_DRAW_NETWORK_BRANCH",
            "AIRIS_TEST_KEY_STDIN"
        ]
        envs.forEach { unsetenv($0) }
        super.tearDown()
    }

    // MARK: Gen / Draw
    func testDrawFlashModelEnableSearchAndReveal() async throws {
        setenv("AIRIS_GEN_STUB", "1", 1)          // 避免真实网络
        setenv("AIRIS_TEST_MODE", "1", 1)         // open/reveal 使用 /usr/bin/true
        let output = CommandTestHarness.temporaryFile(ext: "png")
        defer { CommandTestHarness.cleanup(output) }

        try await DrawCommand.parse([
            "flash test",
            "--model", "gemini-2.5-flash-image",
            "--aspect-ratio", "16:9",
            "--image-size", "4k",
            "--enable-search",
            "--reveal",
            "-o", output.path
        ]).run()

        XCTAssertTrue(FileManager.default.fileExists(atPath: output.path))
    }

    func testDrawWithReferenceAndOpenDefaultBranch() async throws {
        setenv("AIRIS_GEN_STUB", "1", 1)
        setenv("AIRIS_TEST_MODE", "1", 1)
        let ref = CommandTestHarness.fixture("small_100x100.png").path

        try await DrawCommand.parse([
            "ref test",
            "--ref", ref,
            "--open"
        ]).run()
    }

    // MARK: Config set-key 交互分支
    func testSetKeyInteractiveReadsFromStdinStub() async throws {
        setenv("AIRIS_TEST_KEY_STDIN", "STDIN_KEY_VALUE", 1)
        try await SetKeyCommand.parse(["--provider", "stdin-provider"]).run()
        try await DeleteKeyCommand.parse(["--provider", "stdin-provider"]).run()
    }

    // MARK: 滤镜参数校验与默认分支
    func testHalftoneInvalidParametersThrow() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        defer { CommandTestHarness.cleanup(out) }

        await XCTAssertThrowsErrorAsync(
            try await HalftoneCommand.parse([input, "-o", out.path, "--width", "0"]).run()
        )
        await XCTAssertThrowsErrorAsync(
            try await HalftoneCommand.parse([input, "-o", out.path, "--angle", "400"]).run()
        )
        await XCTAssertThrowsErrorAsync(
            try await HalftoneCommand.parse([input, "-o", out.path, "--sharpness", "2"]).run()
        )
        await XCTAssertThrowsErrorAsync(
            try await HalftoneCommand.parse([input, "-o", "out.bmp"]).run()
        )
    }

    func testPixelInvalidScaleAndFormatThrow() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        defer { CommandTestHarness.cleanup(out) }

        await XCTAssertThrowsErrorAsync(
            try await PixelCommand.parse([input, "-o", out.path, "--scale", "0"]).run()
        )
        await XCTAssertThrowsErrorAsync(
            try await PixelCommand.parse([input, "-o", "pix.bmp"]).run()
        )
    }

    func testSepiaInvalidIntensityAndFormatThrow() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        defer { CommandTestHarness.cleanup(out) }

        await XCTAssertThrowsErrorAsync(
            try await SepiaCommand.parse([input, "-o", out.path, "--intensity", "2"]).run()
        )
        await XCTAssertThrowsErrorAsync(
            try await SepiaCommand.parse([input, "-o", "sepia.bmp"]).run()
        )
    }

    func testSharpenUnsharpAndDefaultBranches() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out1 = CommandTestHarness.temporaryFile(ext: "png")
        defer {
            CommandTestHarness.cleanup(out1)
        }

        // unsharp 分支（打印半径）
        try await SharpenCommand.parse([
            input, "-o", out1.path,
            "--intensity", "0.5",
            "--method", "unsharp",
            "--radius", "2.0"
        ]).run()

        // default 分支（未知方法 -> fallback sharpen）通过 DEBUG 辅助覆盖
        let result = SharpenCommand._testFilter(method: "unknown", intensity: 0.4, radius: 2.0)
        XCTAssertFalse(result.extent.isEmpty)
    }
}

// MARK: - Helper

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
