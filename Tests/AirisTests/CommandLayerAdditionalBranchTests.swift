import XCTest
#if !XCODE_BUILD
    @testable import AirisCore
#endif

/// 补充命令层剩余分支覆盖（配置、描摹、显著性等）。
final class CommandLayerAdditionalBranchTests: XCTestCase {
    override func setUp() {
        super.setUp()
        setenv("AIRIS_TEST_MODE", "1", 1)
        setenv("AIRIS_CONFIG_FILE", CommandTestHarness.temporaryFile(ext: "json").path, 1)
    }

    override func tearDown() {
        unsetenv("AIRIS_TEST_MODE")
        unsetenv("AIRIS_CONFIG_FILE")
        super.tearDown()
    }

    // MARK: Gen config

    /// 覆盖无变更提示 + 全量 provider 展示
    func testGenConfigSetNoChangesAndShowAll() async throws {
        // 无 base/model 参数，应打印 “no changes”
        try await SetConfigCommand.parse(["--provider", "demo"]).run()

        // 展示所有 provider（默认配置文件 + demo provider）
        try await ShowConfigCommand.parse([]).run()
    }

    /// 覆盖短 API Key 的掩码分支
    func testGenConfigGetKeyMaskShortValue() async throws {
        try await SetKeyCommand.parse(["--provider", "shortp", "--key", "ABC123"]).run()
        try await GetKeyCommand.parse(["--provider", "shortp"]).run()
        try await DeleteKeyCommand.parse(["--provider", "shortp"]).run()
    }

    /// 覆盖长 Key 掩码与未知 provider 展示
    func testGenConfigShowUnknownProviderAndLongKeyMask() async throws {
        try await SetKeyCommand.parse(["--provider", "longp", "--key", "LONG_SECRET_KEY_1234"]).run()
        try await GetKeyCommand.parse(["--provider", "longp"]).run() // 掩码长 key
        // 未配置 provider 的展示（config 中不存在 longp）
        try await ShowConfigCommand.parse(["--provider", "longp"]).run()
        try await DeleteKeyCommand.parse(["--provider", "longp"]).run()
    }

    /// 覆盖 reset 分支（展示重置后配置）
    func testGenConfigResetAfterSet() async throws {
        try await SetConfigCommand.parse([
            "--provider", "demo2",
            "--base-url", "https://example.reset",
            "--model", "m-reset",
        ]).run()
        try await ResetConfigCommand.parse(["--provider", "demo2"]).run()
    }

    // MARK: Trace 命令

    /// 覆盖 work 样式半径打印、文件大小输出与 --force
    func testTraceWorkStyleWithRadius() async throws {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let output = CommandTestHarness.temporaryFile(ext: "png").path
        try await TraceCommand.parse([
            input,
            "--style", "work",
            "--radius", "4",
            "--intensity", "1.2",
            "-o", output,
            "--force",
        ]).run()
        CommandTestHarness.cleanup(URL(fileURLWithPath: output))
    }

    /// 覆盖参数校验错误分支
    func testTraceInvalidArgumentsThrow() async throws {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path

        await XCTAssertThrowsErrorAsync(try TraceCommand.parse([input, "--style", "bad", "-o", "out.png"]).run())
        await XCTAssertThrowsErrorAsync(try TraceCommand.parse([input, "--intensity", "9.9", "-o", "out.png"]).run())
        await XCTAssertThrowsErrorAsync(try TraceCommand.parse([input, "--radius", "20", "-o", "out.png"]).run())
    }

    /// 输出已存在且未强制，应抛错
    func testTraceOutputExistsWithoutForce() async throws {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let output = CommandTestHarness.temporaryFile(ext: "png")
        try Data().write(to: output) // 创建空文件
        await XCTAssertThrowsErrorAsync(try TraceCommand.parse([input, "-o", output.path]).run())
        CommandTestHarness.cleanup(output)
    }

    // MARK: Vision / Saliency

    /// 覆盖显著性 attention + JSON + 输出保存分支
    func testSaliencyAttentionJSONWithOutput() async throws {
        let image = CommandTestHarness.fixture("medium_512x512.jpg").path
        let output = CommandTestHarness.temporaryFile(ext: "png").path
        try await SaliencyCommand.parse([
            image,
            "--type", "attention",
            "--format", "json",
            "-o", output,
        ]).run()
        CommandTestHarness.cleanup(URL(fileURLWithPath: output))
    }

    /// 覆盖显著性 attention 表格分支并确保有区域输出
    func testSaliencyAttentionTableWithRegions() async throws {
        let image = CommandTestHarness.fixture("medium_512x512.jpg").path
        try await SaliencyCommand.parse([
            image,
            "--type", "attention",
            "--format", "table",
        ]).run()
    }
}

// MARK: - Async throws helper

private func XCTAssertThrowsErrorAsync(
    _ expression: @autoclosure @escaping () async throws -> Void,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        try await expression()
        XCTFail("预期抛出错误", file: file, line: line)
    } catch {
        // expected
    }
}
