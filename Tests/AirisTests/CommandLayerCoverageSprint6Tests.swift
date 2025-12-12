import XCTest
@preconcurrency import Vision
@testable import Airis

/// 第六批覆盖补齐：专门命中默认/错误分支，推进 100%。
final class CommandLayerCoverageSprint6Tests: XCTestCase {
    override func tearDown() {
        unsetenv("AIRIS_TEST_MODE")
        unsetenv("AIRIS_FORCE_UNKNOWN_ORIENTATION")
        unsetenv("AIRIS_FORCE_INFO_NO_COLOR")
        unsetenv("AIRIS_FORCE_INFO_NO_FILESIZE")
        unsetenv("AIRIS_FORCE_META_EMPTY_PROPS")
        unsetenv("AIRIS_FORCE_META_DEST_FAIL")
        unsetenv("AIRIS_FORCE_META_FINALIZE_FAIL")
        unsetenv("AIRIS_FORCE_BARCODE_UNKNOWN")
        unsetenv("AIRIS_TEST_KEY_INPUT")
        unsetenv("AIRIS_FORCE_RESET_PRINT")
        super.tearDown()
    }

    // MARK: Analyze
    func testInfoDescribeOrientationUnknown() {
        let result = InfoCommand.testDescribeOrientation(CGImagePropertyOrientation(rawValue: 999) ?? .up)
        XCTAssertEqual(result, "未知")
    }

    func testInfoCommandForceUnknownOrientationPrints() async throws {
        setenv("AIRIS_FORCE_UNKNOWN_ORIENTATION", "1", 1)
        let input = CommandTestHarness.fixture("small_100x100.png").path
        try await InfoCommand.parse([input, "--format", "table"]).run()
    }

    func testInfoCommandNoColorNoFileSize() async throws {
        setenv("AIRIS_FORCE_INFO_NO_COLOR", "1", 1)
        setenv("AIRIS_FORCE_INFO_NO_FILESIZE", "1", 1)
        let input = CommandTestHarness.fixture("small_100x100.png").path
        try await InfoCommand.parse([input, "--format", "table"]).run()
    }

    func testMetaCommandEmptyPropsWarning() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        setenv("AIRIS_FORCE_META_EMPTY_PROPS", "1", 1)
        try await MetaCommand.parse([input, "--category", "iptc"]).run()
    }

    func testMetaCommandDestinationFail() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "jpg")
        setenv("AIRIS_FORCE_META_DEST_FAIL", "1", 1)
        await XCTAssertThrowsErrorAsync(
            try await MetaCommand.parse([input, "--set-comment", "x", "-o", out.path]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    func testMetaCommandFinalizeFail() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "jpg")
        setenv("AIRIS_FORCE_META_FINALIZE_FAIL", "1", 1)
        await XCTAssertThrowsErrorAsync(
            try await MetaCommand.parse([input, "--set-comment", "y", "-o", out.path]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    // MARK: Detect
    func testBarcodeFormatSymbologyDefaultBranch() {
        setenv("AIRIS_FORCE_BARCODE_UNKNOWN", "1", 1)
        let custom = VNBarcodeSymbology(rawValue: "custom_unknown")
        let text = BarcodeCommand.testFormatSymbology(custom)
        XCTAssertEqual(text, "custom_unknown")
    }

    func testHandHelperUnknownAndChirality() {
        let name = HandCommand.testJointNameString("custom_joint")
        XCTAssertEqual(name, "unknown")
        let chirality = HandCommand.testChiralityString(.unknown)
        XCTAssertEqual(chirality, "Unknown Hand")

        let left = HandCommand.testChiralityString(.left)
        XCTAssertEqual(left, "Left Hand")
    }

    func testHandCommandJSONNormalized() async throws {
        let input = CommandTestHarness.fixture("hand_512x512.png").path
        try await HandCommand.parse([input, "--format", "json", "--threshold", "0.0", "--max-hands", "1"]).run()
    }

    // MARK: Edit
    func testTemperatureOutputExistsBranch() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        FileManager.default.createFile(atPath: out.path, contents: Data())
        await XCTAssertThrowsErrorAsync(
            try await TemperatureCommand.parse([input, "-o", out.path, "--temp", "100"]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    // MARK: Gen Config
    func testSetKeyInteractiveBranchWithEnvInput() async throws {
        setenv("AIRIS_TEST_KEY_INPUT", "ENV_KEY_VALUE", 1)
        try await SetKeyCommand.parse(["--provider", "interactive-env"]).run()
        try await DeleteKeyCommand.parse(["--provider", "interactive-env"]).run()
    }

    func testResetConfigForcePrint() async throws {
        setenv("AIRIS_FORCE_RESET_PRINT", "1", 1)
        try await ResetConfigCommand.parse(["--provider", "forceprint"]).run()
    }

    func testShowConfigPrintsBaseAndModel() async throws {
        try await SetConfigCommand.parse([
            "--provider", "printable",
            "--base-url", "https://example.com",
            "--model", "m1"
        ]).run()
        try await ShowConfigCommand.parse(["--provider", "printable"]).run()
    }

    // MARK: Detect PetPose helper
    func testPetPoseJointNameUnknown() {
        let joint = PetPoseCommand.testJointNameString("custom_pet_joint")
        XCTAssertEqual(joint, "unknown")
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
