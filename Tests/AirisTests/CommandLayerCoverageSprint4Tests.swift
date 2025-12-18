import XCTest
#if !XCODE_BUILD
    @testable import AirisCore
#endif

/// 第四批覆盖补充：针对余下未满 100% 的命令增加分支覆盖。
final class CommandLayerCoverageSprint4Tests: XCTestCase {
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

    // MARK: Analyze

    func testInfoCommandTableOrientation() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        try await InfoCommand.parse([input, "--format", "table"]).run()
    }

    func testMetaCommandTableGPS() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        try await MetaCommand.parse([input, "--category", "gps", "--format", "table"]).run()
    }

    func testMetaCommandWriteClearAll() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "jpg")
        try await MetaCommand.parse([input, "--clear-all", "-o", out.path]).run()
        CommandTestHarness.cleanup(out)
    }

    func testMetaCommandWriteSetCommentClearGps() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "jpg")
        try await MetaCommand.parse([input, "--set-comment", "note", "--clear-gps", "-o", out.path]).run()
        CommandTestHarness.cleanup(out)
    }

    func testPaletteCommandAverageClampJSON() async throws {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        try await PaletteCommand.parse([input, "--format", "json", "--include-average"]).run()
    }

    // MARK: Detect

    func testBarcodeCommandNoResults() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        try await BarcodeCommand.parse([input, "--format", "table"]).run()
    }

    func testHandCommandNoResultsTable() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        try await HandCommand.parse([input, "--threshold", "0.99", "--max-hands", "1", "--format", "table"]).run()
    }

    func testPetPoseCommandNoResultsTable() async throws {
        let input = CommandTestHarness.fixture("rectangle_512x512.png").path
        try await PetPoseCommand.parse([input, "--threshold", "0.99", "--format", "table"]).run()
    }

    // MARK: Gen Config & Draw

    func testSetConfigCommandUpdate() async throws {
        try await SetConfigCommand.parse([
            "--provider", "gemini",
            "--base-url", "https://example.com",
            "--model", "demo-model",
        ]).run()
    }

    func testDrawCommandRevealBranch() async throws {
        let out = CommandTestHarness.temporaryFile(ext: "png")
        try await DrawCommand.parse([
            "test prompt",
            "--reveal",
            "-o", out.path,
            "--ref", CommandTestHarness.fixture("small_100x100.png").path,
        ]).run()
        CommandTestHarness.cleanup(out)
    }
}
