import XCTest
@testable import Airis

/// 第三批命令层覆盖补充：补齐 JSON / 负角度 / 0 分支 / 输出存在等未覆盖路径。
final class CommandLayerCoverageSprint3Tests: XCTestCase {
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
    func testInfoCommandJSON() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        try await InfoCommand.parse([input, "--format", "json"]).run()
    }

    // MARK: Adjust
    func testRotateCommandNegativeAngle() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        try await RotateCommand.parse([input, "-o", out.path, "--angle=-45", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    func testTemperatureCommandUnchangedBranch() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "jpg")
        try await TemperatureCommand.parse([input, "-o", out.path, "--temp", "0", "--tint", "0", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    // MARK: Straighten
    func testStraightenOutputExistsThrows() async {
        let input = CommandTestHarness.fixture("horizon_clear_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "jpg")
        FileManager.default.createFile(atPath: out.path, contents: Data())

        await XCTAssertThrowsErrorAsync(
            try await StraightenCommand.parse([input, "-o", out.path]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    // MARK: Detect
    func testBarcodeCommandTypeFilterJSON() async throws {
        let input = CommandTestHarness.fixture("qrcode_512x512.png").path
        try await BarcodeCommand.parse([input, "--type", "qr", "--format", "json"]).run()
    }

    func testHandCommandJSONWithPixels() async throws {
        let input = CommandTestHarness.fixture("hand_512x512.png").path
        try await HandCommand.parse([input, "--threshold", "0.0", "--max-hands", "2", "--pixels", "--format", "json"]).run()
    }

    func testPetPoseCommandJSON() async throws {
        let input = CommandTestHarness.fixture("cat_512x512.png").path
        try await PetPoseCommand.parse([input, "--threshold", "0.0", "--pixels", "--format", "json"]).run()
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
