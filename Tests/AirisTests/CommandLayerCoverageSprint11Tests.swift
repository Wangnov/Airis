import XCTest
@preconcurrency import Vision
#if !XCODE_BUILD
@testable import AirisCore
#endif

/// 第十一批命令层补测：收敛剩余分支（参数错误、open 分支、桩数据）。
final class CommandLayerCoverageSprint11Tests: XCTestCase {
    override func setUp() {
        super.setUp()
        setenv("AIRIS_TEST_MODE", "1", 1)
        setenv("AIRIS_CONFIG_FILE", CommandTestHarness.temporaryFile(ext: "json").path, 1)
    }

    override func tearDown() {
        unsetenv("AIRIS_TEST_MODE")
        unsetenv("AIRIS_CONFIG_FILE")
        unsetenv("AIRIS_FORCE_INFO_NO_COLOR")
        unsetenv("AIRIS_FORCE_INFO_NO_FILESIZE")
        unsetenv("AIRIS_FORCE_UNKNOWN_ORIENTATION")
        unsetenv("AIRIS_FORCE_META_EMPTY_PROPS")
        unsetenv("AIRIS_FORCE_OCR_FAKE")
        unsetenv("AIRIS_FORCE_BARCODE_UNKNOWN")
        super.tearDown()
    }

    // MARK: Analyze
    func testInfoCommandForcesUnknownOrientationAndNoColor() async throws {
        setenv("AIRIS_FORCE_INFO_NO_COLOR", "1", 1)
        setenv("AIRIS_FORCE_INFO_NO_FILESIZE", "1", 1)
        setenv("AIRIS_FORCE_UNKNOWN_ORIENTATION", "1", 1)

        let input = CommandTestHarness.fixture("small_100x100.png").path
        try await InfoCommand.parse([input]).run()
    }

    func testMetaCommandEmptyPropsWarningForSpecificCategory() async throws {
        setenv("AIRIS_FORCE_META_EMPTY_PROPS", "1", 1)
        let input = CommandTestHarness.fixture("small_100x100.png").path
        try await MetaCommand.parse([input, "--category", "iptc"]).run()
    }

    func testMetaCommandInvalidImageThrows() async {
        // 构造零字节 PNG，通过 validateImageFile 但触发 CGImageSource 失败
        let tmp = CommandTestHarness.temporaryFile(ext: "png")
        FileManager.default.createFile(atPath: tmp.path, contents: Data())

        // 关闭测试模式以触发真实读取路径
        unsetenv("AIRIS_TEST_MODE")

        await XCTAssertThrowsErrorAsync(
            try await MetaCommand.parse([tmp.path]).run()
        )

        CommandTestHarness.cleanup(tmp)
    }

    func testOCRFakeResultsShowBounds() async throws {
        setenv("AIRIS_FORCE_OCR_FAKE", "1", 1)
        let input = CommandTestHarness.fixture("document_text_512x512.png").path
        try await OCRCommand.parse([input, "--show-bounds"]).run()
    }

    func testOCRFakeResultsPlainText() async throws {
        setenv("AIRIS_FORCE_OCR_FAKE", "1", 1)
        let input = CommandTestHarness.fixture("document_text_512x512.png").path
        try await OCRCommand.parse([input, "--format", "text"]).run()
    }

    func testBarcodeFormatSymbologyUnknownHelper() {
        setenv("AIRIS_FORCE_BARCODE_UNKNOWN", "1", 1)
        let custom = VNBarcodeSymbology.aztec
        let display = BarcodeCommand.testFormatSymbology(custom)
        XCTAssertFalse(display.isEmpty)
    }

    // MARK: Filters 参数错误/不支持格式
    func testBlurCommandInvalidTypeThrows() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        await XCTAssertThrowsErrorAsync(
            try await BlurCommand.parse([input, "-o", out.path, "--type", "unknown"]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    func testBlurCommandInvalidAngleThrows() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        await XCTAssertThrowsErrorAsync(
            try await BlurCommand.parse([input, "-o", out.path, "--type", "motion", "--angle", "361"]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    func testFilterUnsupportedOutputFormatThrows() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let commands: [() async throws -> Void] = [
            { try await ChromeCommand.parse([input, "-o", CommandTestHarness.temporaryFile(ext: "txt").path]).run() },
            { try await ComicCommand.parse([input, "-o", CommandTestHarness.temporaryFile(ext: "txt").path]).run() },
            { try await InstantCommand.parse([input, "-o", CommandTestHarness.temporaryFile(ext: "txt").path]).run() },
            { try await MonoCommand.parse([input, "-o", CommandTestHarness.temporaryFile(ext: "txt").path]).run() },
            { try await NoirCommand.parse([input, "-o", CommandTestHarness.temporaryFile(ext: "txt").path]).run() },
            { try await NoiseCommand.parse([input, "-o", CommandTestHarness.temporaryFile(ext: "txt").path, "--strength", "0.5"]).run() },
            { try await PixelCommand.parse([input, "-o", CommandTestHarness.temporaryFile(ext: "txt").path, "--scale", "4"]).run() },
            { try await SepiaCommand.parse([input, "-o", CommandTestHarness.temporaryFile(ext: "txt").path, "--intensity", "0.5"]).run() }
        ]

        for command in commands {
            await XCTAssertThrowsErrorAsync(try await command())
        }
    }

    // MARK: Adjust open 分支
    func testColorCommandOpenPath() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        try await ColorCommand.parse([input, "-o", out.path, "--brightness", "0.1", "--open", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    func testExposureCommandOpenPath() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        try await ExposureCommand.parse([input, "-o", out.path, "--ev", "0.5", "--open", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    func testPosterizeCommandOpenPath() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        try await PosterizeCommand.parse([input, "-o", out.path, "--levels", "4", "--open", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    func testThresholdCommandOpenPath() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        try await ThresholdCommand.parse([input, "-o", out.path, "--threshold", "0.4", "--open", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    func testVignetteCommandOpenPath() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        try await VignetteCommand.parse([input, "-o", out.path, "--intensity", "0.8", "--radius", "2.0", "--open", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    // MARK: Format open 分支
    func testFormatCommandOpenPath() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        try await FormatCommand.parse([input, "-o", out.path, "--format", "png", "--open", "--force"]).run()
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
