import XCTest
@testable import Airis

/// 第十二批补测：覆盖剩余分支（Blur 动态类型、裁剪/翻转错误、Straighten 调试分支、Score/Similar 低分等）。
final class CommandLayerCoverageSprint12Tests: XCTestCase {
    override func setUp() {
        super.setUp()
        setenv("AIRIS_TEST_MODE", "1", 1)
        setenv("AIRIS_CONFIG_FILE", CommandTestHarness.temporaryFile(ext: "json").path, 1)
    }

    override func tearDown() {
        unsetenv("AIRIS_TEST_MODE")
        unsetenv("AIRIS_CONFIG_FILE")
        unsetenv("AIRIS_FORCE_STRAIGHTEN_NO_HORIZON")
        unsetenv("AIRIS_FORCE_STRAIGHTEN_ZERO")
        unsetenv("AIRIS_SIMILAR_TEST_DISTANCE")
        unsetenv("AIRIS_SCORE_TEST_VALUE")
        super.tearDown()
    }

    // MARK: Blur 多类型
    func testBlurMotionAndZoomBranches() async throws {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path

        let motionOut = CommandTestHarness.temporaryFile(ext: "png")
        try await BlurCommand.parse([input, "-o", motionOut.path, "--type", "motion", "--angle", "45", "--radius", "12", "--force"]).run()
        CommandTestHarness.cleanup(motionOut)

        let zoomOut = CommandTestHarness.temporaryFile(ext: "png")
        try await BlurCommand.parse([input, "-o", zoomOut.path, "--type", "zoom", "--radius", "8", "--force"]).run()
        CommandTestHarness.cleanup(zoomOut)
    }

    // MARK: Flip
    func testFlipOutputExistsThrows() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        FileManager.default.createFile(atPath: out.path, contents: Data())

        await XCTAssertThrowsErrorAsync(
            try await FlipCommand.parse([input, "-o", out.path, "-h"]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    func testFlipOpenBothDirections() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        try await FlipCommand.parse([input, "-o", out.path, "-h", "-v", "--open", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    // MARK: Crop
    func testCropNegativeCoordinatesThrow() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        await XCTAssertThrowsErrorAsync(
            try await CropCommand.parse([input, "-o", CommandTestHarness.temporaryFile(ext: "png").path, "--x", "-1", "--y", "0", "--width", "10", "--height", "10"]).run()
        )
    }

    func testCropOpenBranch() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        try await CropCommand.parse([input, "-o", out.path, "--x", "10", "--y", "10", "--width", "50", "--height", "50", "--open", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    // MARK: Resize
    func testResizeWidthOnlyOpenBranch() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        try await ResizeCommand.parse([input, "-o", out.path, "--width", "80", "--open", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    func testResizeHeightOnly() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        try await ResizeCommand.parse([input, "-o", out.path, "--height", "60", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    // MARK: Straighten 调试分支
    func testStraightenForceNoHorizon() async throws {
        setenv("AIRIS_FORCE_STRAIGHTEN_NO_HORIZON", "1", 1)
        let input = CommandTestHarness.fixture("horizon_clear_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "jpg")
        try await StraightenCommand.parse([input, "-o", out.path, "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    func testStraightenForceZeroAngleAlreadyLevel() async throws {
        setenv("AIRIS_FORCE_STRAIGHTEN_ZERO", "1", 1)
        let input = CommandTestHarness.fixture("horizon_clear_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "jpg")
        try await StraightenCommand.parse([input, "-o", out.path, "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    // MARK: Trace sketch 分支
    func testTraceSketchStyle() async throws {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        try await TraceCommand.parse([input, "-o", out.path, "--style", "sketch", "--intensity", "1.2", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    // MARK: Score / Similar 低分
    func testScoreCommandPoorRatingTableAndJSON() async throws {
        setenv("AIRIS_SCORE_TEST_VALUE", "-0.75", 1)
        let input = CommandTestHarness.fixture("small_100x100.png").path
        try await ScoreCommand.parse([input]).run()
        try await ScoreCommand.parse([input, "--format", "json"]).run()
    }

    func testSimilarCommandMultipleRatings() async throws {
        let img1 = CommandTestHarness.fixture("small_100x100.png").path
        let img2 = CommandTestHarness.fixture("small_100x100_meta.png").path

        setenv("AIRIS_SIMILAR_TEST_DISTANCE", "0.1", 1)
        try await SimilarCommand.parse([img1, img2]).run()

        setenv("AIRIS_SIMILAR_TEST_DISTANCE", "0.7", 1)
        try await SimilarCommand.parse([img1, img2, "--format", "json"]).run()

        setenv("AIRIS_SIMILAR_TEST_DISTANCE", "1.8", 1)
        try await SimilarCommand.parse([img1, img2]).run()
    }

    // MARK: Barcode 解析未知类型（symbology nil 路径）
    func testBarcodeInvalidTypeIgnored() async throws {
        let input = CommandTestHarness.fixture("qrcode_512x512.png").path
        try await BarcodeCommand.parse([input, "--type", "unknownType"]).run()
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
