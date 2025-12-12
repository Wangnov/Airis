import XCTest
@testable import Airis

/// 第十四批补测：继续填平剩余错误分支（Crop/Trace/Noise/Format/Hand/PetPose）。
final class CommandLayerCoverageSprint14Tests: XCTestCase {
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

    // MARK: Crop
    func testCropZeroWidthThrows() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        await XCTAssertThrowsErrorAsync(
            try await CropCommand.parse([input, "-o", CommandTestHarness.temporaryFile(ext: "png").path, "--x", "0", "--y", "0", "--width", "0", "--height", "10"]).run()
        )
    }

    func testCropRegionExceedsBoundsThrows() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        await XCTAssertThrowsErrorAsync(
            try await CropCommand.parse([input, "-o", CommandTestHarness.temporaryFile(ext: "png").path, "--x", "90", "--y", "90", "--width", "20", "--height", "20"]).run()
        )
    }

    // MARK: Trace guards
    func testTraceIntensityOutOfRangeThrows() async {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        await XCTAssertThrowsErrorAsync(
            try await TraceCommand.parse([input, "-o", CommandTestHarness.temporaryFile(ext: "png").path, "--style", "edges", "--intensity", "6"]).run()
        )
    }

    func testTraceRadiusOutOfRangeThrows() async {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        await XCTAssertThrowsErrorAsync(
            try await TraceCommand.parse([input, "-o", CommandTestHarness.temporaryFile(ext: "png").path, "--style", "work", "--radius", "0.5"]).run()
        )
    }

    // MARK: Noise
    func testNoiseStrengthOutOfRangeThrows() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        await XCTAssertThrowsErrorAsync(
            try await NoiseCommand.parse([input, "-o", CommandTestHarness.temporaryFile(ext: "png").path, "--strength", "1.5"]).run()
        )
    }

    // MARK: Format extra guards
    func testFormatQualityOutOfRangeThrows() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        await XCTAssertThrowsErrorAsync(
            try await FormatCommand.parse([input, "-o", CommandTestHarness.temporaryFile(ext: "jpg").path, "--format", "jpg", "--quality", "1.2"]).run()
        )
    }

    func testFormatOutputExistsThrows() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        FileManager.default.createFile(atPath: out.path, contents: Data())
        await XCTAssertThrowsErrorAsync(
            try await FormatCommand.parse([input, "-o", out.path, "--format", "png"]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    // MARK: Hand / PetPose helpers
    func testHandChiralityStringHelper() {
        XCTAssertEqual(HandCommand._testChiralityString(.left), "Left Hand")
        XCTAssertEqual(HandCommand._testChiralityString(.right), "Right Hand")
    }

    func testPetPoseJointNameHelper() {
        XCTAssertEqual(PetPoseCommand._testJointNameString("unknown_joint"), "unknown")
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
