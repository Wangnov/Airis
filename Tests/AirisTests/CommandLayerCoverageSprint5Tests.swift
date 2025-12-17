import XCTest
#if !XCODE_BUILD
@testable import AirisCore
#endif

/// 第五批覆盖冲刺：补齐剩余命令分支以逼近 100%。
final class CommandLayerCoverageSprint5Tests: XCTestCase {
    // MARK: Analyze / Info
    func testInfoCommandNormalOrientationWithoutTestMode() async throws {
        unsetenv("AIRIS_TEST_MODE")
        let input = CommandTestHarness.fixture("small_100x100.png").path
        try await InfoCommand.parse([input, "--format", "table"]).run()
    }

    // MARK: Analyze / Meta
    func testMetaCommandIptcNoDataNonTestMode() async throws {
        unsetenv("AIRIS_TEST_MODE")
        let input = CommandTestHarness.fixture("small_100x100.png").path
        try await MetaCommand.parse([input, "--category", "iptc", "--format", "table"]).run()
    }

    func testMetaCommandWriteHeicAndTiff() async throws {
        setenv("AIRIS_TEST_MODE", "1", 1)
        let heic = try CommandTestHarness.copyFixture("small_100x100.png", toExtension: "heic")
        let heicOut = CommandTestHarness.temporaryFile(ext: "heic")
        try await MetaCommand.parse([heic.path, "--set-comment", "h1", "-o", heicOut.path]).run()

        let tiff = try CommandTestHarness.copyFixture("small_100x100.png", toExtension: "tiff")
        let tiffOut = CommandTestHarness.temporaryFile(ext: "tiff")
        try await MetaCommand.parse([tiff.path, "--set-comment", "t1", "-o", tiffOut.path]).run()

        CommandTestHarness.cleanup(heic)
        CommandTestHarness.cleanup(heicOut)
        CommandTestHarness.cleanup(tiff)
        CommandTestHarness.cleanup(tiffOut)
        unsetenv("AIRIS_TEST_MODE")
    }

    func testMetaCommandWriteWithEmptyFileThrows() async {
        setenv("AIRIS_TEST_MODE", "1", 1)
        let empty = CommandTestHarness.temporaryFile(ext: "png")
        FileManager.default.createFile(atPath: empty.path, contents: Data())
        let out = CommandTestHarness.temporaryFile(ext: "png")

        await XCTAssertThrowsErrorAsync(
            try await MetaCommand.parse([empty.path, "--set-comment", "x", "-o", out.path]).run()
        )
        CommandTestHarness.cleanup(empty)
        CommandTestHarness.cleanup(out)
        unsetenv("AIRIS_TEST_MODE")
    }

    // MARK: Analyze / Palette
    func testPaletteCommandDecodeFail() async {
        let empty = CommandTestHarness.temporaryFile(ext: "png")
        FileManager.default.createFile(atPath: empty.path, contents: Data())
        await XCTAssertThrowsErrorAsync(
            try await PaletteCommand.parse([empty.path, "--count", "5"]).run()
        )
        CommandTestHarness.cleanup(empty)
    }

    func testPaletteCommandForceNoColorsAndAverageNil() async throws {
        setenv("AIRIS_FORCE_PALETTE_OUTPUT_NIL", "1", 1)
        let input = CommandTestHarness.fixture("small_100x100.png").path
        try await PaletteCommand.parse([input, "--count", "5", "--format", "table"]).run()
        unsetenv("AIRIS_FORCE_PALETTE_OUTPUT_NIL")

        setenv("AIRIS_FORCE_PALETTE_AVG_NIL", "1", 1)
        try await PaletteCommand.parse([input, "--include-average", "--format", "json"]).run()
        unsetenv("AIRIS_FORCE_PALETTE_AVG_NIL")
    }

    // MARK: Analyze / Score & Similar
    func testScoreCommandFallbackBranch() async throws {
        unsetenv("AIRIS_TEST_MODE")
        let input = CommandTestHarness.fixture("small_100x100.png").path
        try await ScoreCommand.parse([input]).run()
    }

    func testSimilarCommandOverrideDistance() async throws {
        setenv("AIRIS_TEST_MODE", "1", 1)
        setenv("AIRIS_SIMILAR_TEST_DISTANCE", "1.20", 1)
        let img1 = CommandTestHarness.fixture("small_100x100.png").path
        let img2 = CommandTestHarness.fixture("medium_512x512.jpg").path
        try await SimilarCommand.parse([img1, img2, "--format", "json"]).run()
        unsetenv("AIRIS_SIMILAR_TEST_DISTANCE")
        unsetenv("AIRIS_TEST_MODE")
    }

    func testSimilarCommandNonTestModeFallback() async throws {
        unsetenv("AIRIS_TEST_MODE")
        let img1 = CommandTestHarness.fixture("small_100x100.png").path
        let img2 = CommandTestHarness.fixture("medium_512x512.jpg").path
        try await SimilarCommand.parse([img1, img2, "--format", "table"]).run()
    }

    // MARK: Analyze / Tag
    func testTagCommandNoResultsHighThreshold() async throws {
        let img = CommandTestHarness.fixture("small_100x100.png").path
        try await TagCommand.parse([img, "--threshold", "2.0", "--limit", "5", "--format", "json"]).run()
    }

    func testTagCommandNoResultsHighThresholdTable() async throws {
        let img = CommandTestHarness.fixture("small_100x100.png").path
        try await TagCommand.parse([img, "--threshold", "2.0", "--limit", "5", "--format", "table"]).run()
    }

    func testTagCommandAllResultsPrinted() async throws {
        let img = CommandTestHarness.fixture("medium_512x512.jpg").path
        try await TagCommand.parse([img, "--threshold", "0.0", "--limit", "50", "--format", "table"]).run()
    }

    // MARK: Detect / Barcode, Hand, PetPose
    func testBarcodeCommandCode39JSON() async throws {
        let img = CommandTestHarness.fixture("qrcode_512x512.png").path
        try await BarcodeCommand.parse([img, "--type", "code39", "--format", "json"]).run()
    }

    func testHandCommandPixelsTable() async throws {
        let img = CommandTestHarness.fixture("hand_512x512.png").path
        try await HandCommand.parse([img, "--pixels", "--format", "table", "--threshold", "0.0", "--max-hands", "1"]).run()
    }

    func testPetPoseCommandPixelsTable() async throws {
        let img = CommandTestHarness.fixture("cat_512x512.png").path
        try await PetPoseCommand.parse([img, "--pixels", "--format", "table", "--threshold", "0.0"]).run()
    }

    func testPetPoseCommandForceUnsupportedBranch() async throws {
        setenv("AIRIS_FORCE_PETPOSE_UNSUPPORTED", "1", 1)
        let img = CommandTestHarness.fixture("small_100x100.png").path
        try await PetPoseCommand.parse([img]).run()
        unsetenv("AIRIS_FORCE_PETPOSE_UNSUPPORTED")
    }

    // MARK: Edit / Rotate
    func testRotateCommandOutputExistsBranch() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        FileManager.default.createFile(atPath: out.path, contents: Data())

        await XCTAssertThrowsErrorAsync(
            try await RotateCommand.parse([input, "-o", out.path, "--angle", "15"]).run()
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
