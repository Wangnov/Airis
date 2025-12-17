import XCTest
#if !XCODE_BUILD
@testable import AirisCore
#endif

/// 覆盖各类参数校验/异常分支，冲刺剩余命令层行覆盖。
final class CommandLayerCoverageValidationTests: XCTestCase {
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

    // MARK: Adjust 命令参数校验

    func testColorCommandValidationErrorsAndOutputExists() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")

        await XCTAssertThrowsErrorAsync(
            try await ColorCommand.parse([input, "-o", out.path, "--brightness", "2"]).run()
        )
        await XCTAssertThrowsErrorAsync(
            try await ColorCommand.parse([input, "-o", out.path, "--contrast", "5"]).run()
        )
        await XCTAssertThrowsErrorAsync(
            try await ColorCommand.parse([input, "-o", out.path, "--saturation", "3"]).run()
        )

        // 输出已存在且未 --force
        FileManager.default.createFile(atPath: out.path, contents: Data())
        await XCTAssertThrowsErrorAsync(
            try await ColorCommand.parse([input, "-o", out.path]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    func testExposureCommandValidationAndExists() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "jpg")

        await XCTAssertThrowsErrorAsync(
            try await ExposureCommand.parse([input, "-o", out.path, "--ev", "20"]).run()
        )

        FileManager.default.createFile(atPath: out.path, contents: Data())
        await XCTAssertThrowsErrorAsync(
            try await ExposureCommand.parse([input, "-o", out.path]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    func testTemperatureCommandValidationErrors() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "jpg").path

        await XCTAssertThrowsErrorAsync(
            try await TemperatureCommand.parse([input, "-o", out, "--temp", "6000"]).run()
        )

        await XCTAssertThrowsErrorAsync(
            try await TemperatureCommand.parse([input, "-o", out, "--tint", "200"]).run()
        )
    }

    // MARK: Filter 命令校验

    func testBlurCommandValidationErrors() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png").path

        await XCTAssertThrowsErrorAsync(
            try await BlurCommand.parse([input, "-o", out, "--type", "weird"]).run()
        )
        await XCTAssertThrowsErrorAsync(
            try await BlurCommand.parse([input, "-o", out, "--radius", "120"]).run()
        )
        await XCTAssertThrowsErrorAsync(
            try await BlurCommand.parse([input, "-o", out, "--type", "motion", "--angle", "400"]).run()
        )
        // 不支持的输出格式
        await XCTAssertThrowsErrorAsync(
            try await BlurCommand.parse([input, "-o", out + ".webp"]).run()
        )
    }

    func testSharpenCommandValidationErrors() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png").path

        await XCTAssertThrowsErrorAsync(
            try await SharpenCommand.parse([input, "-o", out, "--method", "soft"]).run()
        )
        await XCTAssertThrowsErrorAsync(
            try await SharpenCommand.parse([input, "-o", out, "--intensity", "3"]).run()
        )
        await XCTAssertThrowsErrorAsync(
            try await SharpenCommand.parse([input, "-o", out, "--method", "unsharp", "--radius", "20"]).run()
        )
        await XCTAssertThrowsErrorAsync(
            try await SharpenCommand.parse([input, "-o", out + ".webp"]).run()
        )
    }

    func testNoiseCommandValidationErrors() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")

        await XCTAssertThrowsErrorAsync(
            try await NoiseCommand.parse([input, "-o", out.path, "--level", "0.5"]).run()
        )
        await XCTAssertThrowsErrorAsync(
            try await NoiseCommand.parse([input, "-o", out.path, "--sharpness", "5"]).run()
        )
        await XCTAssertThrowsErrorAsync(
            try await NoiseCommand.parse([input, "-o", out.path + ".webp"]).run()
        )

        FileManager.default.createFile(atPath: out.path, contents: Data())
        await XCTAssertThrowsErrorAsync(
            try await NoiseCommand.parse([input, "-o", out.path]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    // MARK: Adjust 补充 flip/posterize/threshold/vignette

    func testFlipCommandValidationAndDirections() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")

        await XCTAssertThrowsErrorAsync(
            try await FlipCommand.parse([input, "-o", out.path]).run()
        )

        try? FileManager.default.removeItem(atPath: out.path)
        try? await FlipCommand.parse([input, "-o", out.path, "--vertical", "--force"]).run()
        try? await FlipCommand.parse([input, "-o", out.path, "--horizontal", "--vertical", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    func testPosterizeCommandValidationAndExists() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")

        await XCTAssertThrowsErrorAsync(
            try await PosterizeCommand.parse([input, "-o", out.path, "--levels", "40"]).run()
        )

        FileManager.default.createFile(atPath: out.path, contents: Data())
        await XCTAssertThrowsErrorAsync(
            try await PosterizeCommand.parse([input, "-o", out.path]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    func testThresholdCommandValidationAndExists() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")

        await XCTAssertThrowsErrorAsync(
            try await ThresholdCommand.parse([input, "-o", out.path, "--threshold", "2"]).run()
        )

        FileManager.default.createFile(atPath: out.path, contents: Data())
        await XCTAssertThrowsErrorAsync(
            try await ThresholdCommand.parse([input, "-o", out.path]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    func testVignetteCommandValidationAndExists() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")

        await XCTAssertThrowsErrorAsync(
            try await VignetteCommand.parse([input, "-o", out.path, "--intensity", "3"]).run()
        )
        await XCTAssertThrowsErrorAsync(
            try await VignetteCommand.parse([input, "-o", out.path, "--radius", "3"]).run()
        )

        FileManager.default.createFile(atPath: out.path, contents: Data())
        await XCTAssertThrowsErrorAsync(
            try await VignetteCommand.parse([input, "-o", out.path]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    // MARK: Crop 边界与存在性

    func testCropCommandValidationBranches() async {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "png")

        await XCTAssertThrowsErrorAsync(
            try await CropCommand.parse([input, "-o", out.path, "--x", "-1", "--y", "0", "--width", "100", "--height", "100"]).run()
        )

        await XCTAssertThrowsErrorAsync(
            try await CropCommand.parse([input, "-o", out.path, "--x", "0", "--y", "0", "--width", "-10", "--height", "100"]).run()
        )

        await XCTAssertThrowsErrorAsync(
            try await CropCommand.parse([input, "-o", out.path, "--x", "500", "--y", "500", "--width", "100", "--height", "100"]).run()
        )

        FileManager.default.createFile(atPath: out.path, contents: Data())
        await XCTAssertThrowsErrorAsync(
            try await CropCommand.parse([input, "-o", out.path, "--x", "0", "--y", "0", "--width", "100", "--height", "100"]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    // MARK: Cut / Straighten 额外分支

    func testCutCommandFormatAndExistsValidation() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let outNonPng = CommandTestHarness.temporaryFile(ext: "jpg").path
        await XCTAssertThrowsErrorAsync(
            try await CutCommand.parse([input, "-o", outNonPng]).run()
        )

        let out = CommandTestHarness.temporaryFile(ext: "png")
        FileManager.default.createFile(atPath: out.path, contents: Data())
        await XCTAssertThrowsErrorAsync(
            try await CutCommand.parse([input, "-o", out.path]).run()
        )
        CommandTestHarness.cleanup(out)
    }

    func testStraightenCommandManualAngleBranch() async throws {
        let input = CommandTestHarness.fixture("horizon_clear_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "jpg")
        try await StraightenCommand.parse([
            input,
            "-o", out.path,
            "--angle", "5",
            "--force"
        ]).run()
        CommandTestHarness.cleanup(out)
    }
}
