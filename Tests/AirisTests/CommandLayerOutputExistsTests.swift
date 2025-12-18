import XCTest
#if !XCODE_BUILD
    @testable import AirisCore
#endif

/// 覆盖各命令的“输出已存在”与补充分支，避免遗漏分支导致覆盖率不足。
final class CommandLayerOutputExistsTests: XCTestCase {
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

    // MARK: Temperature

    func testTemperatureOutputExistsThrows() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "jpg")
        FileManager.default.createFile(atPath: out.path, contents: Data())

        await XCTAssertThrowsErrorAsync(
            try TemperatureCommand.parse([input, "-o", out.path, "--temp", "-200"]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    func testTemperatureCoolerBranch() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "jpg")
        try await TemperatureCommand.parse([input, "-o", out.path, "--temp=-800", "--tint=-20", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    // MARK: Scan

    func testScanOutputExistsThrows() async {
        let input = CommandTestHarness.fixture("rectangle_512x512.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        FileManager.default.createFile(atPath: out.path, contents: Data())

        await XCTAssertThrowsErrorAsync(
            try ScanCommand.parse([input, "-o", out.path]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    // MARK: Filters (输出已存在)

    func testHalftoneOutputExistsThrows() async {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        FileManager.default.createFile(atPath: out.path, contents: Data())

        await XCTAssertThrowsErrorAsync(
            try HalftoneCommand.parse([input, "-o", out.path, "--width", "6", "--angle", "10"]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    func testPixelOutputExistsThrows() async {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        FileManager.default.createFile(atPath: out.path, contents: Data())

        await XCTAssertThrowsErrorAsync(
            try PixelCommand.parse([input, "-o", out.path, "--scale", "12"]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    func testChromeOutputExistsThrows() async {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "jpg")
        FileManager.default.createFile(atPath: out.path, contents: Data())

        await XCTAssertThrowsErrorAsync(
            try ChromeCommand.parse([input, "-o", out.path]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    func testComicOutputExistsThrows() async {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        FileManager.default.createFile(atPath: out.path, contents: Data())

        await XCTAssertThrowsErrorAsync(
            try ComicCommand.parse([input, "-o", out.path]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    func testInstantOutputExistsThrows() async {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        FileManager.default.createFile(atPath: out.path, contents: Data())

        await XCTAssertThrowsErrorAsync(
            try InstantCommand.parse([input, "-o", out.path]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    func testMonoOutputExistsThrows() async {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        FileManager.default.createFile(atPath: out.path, contents: Data())

        await XCTAssertThrowsErrorAsync(
            try MonoCommand.parse([input, "-o", out.path]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    func testNoirOutputExistsThrows() async {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        FileManager.default.createFile(atPath: out.path, contents: Data())

        await XCTAssertThrowsErrorAsync(
            try NoirCommand.parse([input, "-o", out.path]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    func testSepiaOutputExistsThrows() async {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        FileManager.default.createFile(atPath: out.path, contents: Data())

        await XCTAssertThrowsErrorAsync(
            try SepiaCommand.parse([input, "-o", out.path]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    func testBlurOutputExistsThrows() async {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        FileManager.default.createFile(atPath: out.path, contents: Data())

        await XCTAssertThrowsErrorAsync(
            try BlurCommand.parse([input, "-o", out.path, "--radius", "4"]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    func testSharpenOutputExistsThrows() async {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        FileManager.default.createFile(atPath: out.path, contents: Data())

        await XCTAssertThrowsErrorAsync(
            try SharpenCommand.parse([input, "-o", out.path, "--intensity", "0.8"]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    // MARK: 其他编辑命令

    func testThumbOutputExistsThrows() async {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "jpg")
        FileManager.default.createFile(atPath: out.path, contents: Data())

        await XCTAssertThrowsErrorAsync(
            try ThumbCommand.parse([input, "-o", out.path, "--size", "256"]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    func testDefringeOutputExistsThrows() async {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "jpg")
        FileManager.default.createFile(atPath: out.path, contents: Data())

        await XCTAssertThrowsErrorAsync(
            try DefringeCommand.parse([input, "-o", out.path, "--amount", "0.5"]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    func testRotateOutputExistsThrows() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        FileManager.default.createFile(atPath: out.path, contents: Data())

        await XCTAssertThrowsErrorAsync(
            try RotateCommand.parse([input, "-o", out.path, "--angle", "-30"]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    func testInvertOutputExistsThrows() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        FileManager.default.createFile(atPath: out.path, contents: Data())

        await XCTAssertThrowsErrorAsync(
            try InvertCommand.parse([input, "-o", out.path]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    func testEnhanceOutputExistsThrows() async {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "jpg")
        FileManager.default.createFile(atPath: out.path, contents: Data())

        await XCTAssertThrowsErrorAsync(
            try EnhanceCommand.parse([input, "-o", out.path]).run()
        )
        CommandTestHarness.cleanup(out)
    }
}

// MARK: - Helpers

private func XCTAssertThrowsErrorAsync(
    _ expression: @autoclosure @escaping () async throws -> some Any,
    _ message: String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await expression()
        XCTFail(message, file: file, line: line)
    } catch {}
}
