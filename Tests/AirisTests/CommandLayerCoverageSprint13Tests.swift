import XCTest
#if !XCODE_BUILD
@testable import AirisCore
#endif

/// 第十三批补测：覆盖剩余错误/分支（Cut/Defringe/Trace/Blur/Format/Straighten）。
final class CommandLayerCoverageSprint13Tests: XCTestCase {
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

    // MARK: Cut
    func testCutCommandOutputMustBePNGThrows() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        await XCTAssertThrowsErrorAsync(
            try await CutCommand.parse([input, "-o", CommandTestHarness.temporaryFile(ext: "jpg").path]).run()
        )
    }

    func testCutCommandOutputExistsThrows() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        FileManager.default.createFile(atPath: out.path, contents: Data())

        await XCTAssertThrowsErrorAsync(
            try await CutCommand.parse([input, "-o", out.path]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    // MARK: Defringe
    func testDefringeAmountInvalidThrows() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        await XCTAssertThrowsErrorAsync(
            try await DefringeCommand.parse([input, "-o", CommandTestHarness.temporaryFile(ext: "png").path, "--amount", "1.5"]).run()
        )
    }

    // MARK: Trace / Blur
    func testTraceInvalidStyleThrows() async {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        await XCTAssertThrowsErrorAsync(
            try await TraceCommand.parse([input, "-o", CommandTestHarness.temporaryFile(ext: "png").path, "--style", "invalid"]).run()
        )
    }

    func testBlurOutputExistsThrows() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        FileManager.default.createFile(atPath: out.path, contents: Data())

        await XCTAssertThrowsErrorAsync(
            try await BlurCommand.parse([input, "-o", out.path]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    // MARK: Format 压缩/膨胀比
    func testFormatCompressionSmallerRatioBranch() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "jpg")
        try await FormatCommand.parse([input, "-o", out.path, "--format", "jpg", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    func testFormatExpansionLargerRatioBranch() async throws {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "tiff")
        try await FormatCommand.parse([input, "-o", out.path, "--format", "tiff", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    // MARK: Straighten 手动角度分支
    func testStraightenManualAngleBranch() async throws {
        let input = CommandTestHarness.fixture("horizon_clear_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "jpg")
        try await StraightenCommand.parse([input, "-o", out.path, "--angle", "1.2", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }
}

// MARK: - Helpers

private func XCTAssertThrowsErrorAsync<T>(
    _ expression: @autoclosure @escaping () async throws -> T,
    _ message: String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await expression()
        XCTFail(message, file: file, line: line)
    } catch { }
}
