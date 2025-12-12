import XCTest
@testable import Airis

/// 第二轮命令层覆盖冲刺：补齐 Palette/Format/Resize 及 Face/Hand/PetPose 等分支。
final class CommandLayerCoverageSprint2Tests: XCTestCase {
    override func setUp() {
        super.setUp()
        setenv("AIRIS_TEST_MODE", "1", 1)
        setenv("AIRIS_CONFIG_FILE", CommandTestHarness.temporaryFile(ext: "json").path, 1)
    }

    /// 轻量级异步抛错断言，避免重复样板。
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

    override func tearDown() {
        unsetenv("AIRIS_TEST_MODE")
        unsetenv("AIRIS_CONFIG_FILE")
        super.tearDown()
    }

    // MARK: - Analyze

    func testPaletteJSONWithAverageAndClamp() async throws {
        let image = CommandTestHarness.fixture("medium_512x512.jpg").path
        // count>16 触发 clamp，同时 include-average + json 分支
        try await PaletteCommand.parse([
            image,
            "--count", "20",
            "--format", "json",
            "--include-average"
        ]).run()
    }

    func testPaletteSmallImageNoScaleBranch() async throws {
        let image = CommandTestHarness.fixture("small_100x100.png").path
        try await PaletteCommand.parse([
            image,
            "--count", "3"
        ]).run()
    }

    func testPaletteDecodeFailureThrows() async throws {
        // 创建空文件以触发 CIImage 解码失败分支
        let temp = CommandTestHarness.temporaryFile(ext: "png")
        FileManager.default.createFile(atPath: temp.path, contents: Data())
        await XCTAssertThrowsErrorAsync(
            try await PaletteCommand.parse([temp.path]).run()
        )
        CommandTestHarness.cleanup(temp)
    }

    // MARK: - Edit - Format

    func testFormatInvalidFormatAndQualityThrows() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "jpg").path

        await XCTAssertThrowsErrorAsync(
            try await FormatCommand.parse([input, "-o", out, "--format", "bmpx"]).run()
        )

        await XCTAssertThrowsErrorAsync(
            try await FormatCommand.parse([input, "-o", out, "--format", "jpg", "--quality", "1.5"]).run()
        )
    }

    func testFormatOutputExistsWithoutForce() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        // 预先创建输出文件
        FileManager.default.createFile(atPath: out.path, contents: Data([0x00]))

        await XCTAssertThrowsErrorAsync(
            try await FormatCommand.parse([input, "-o", out.path, "--format", "png"]).run()
        )

        CommandTestHarness.cleanup(out)
    }

    func testFormatJPGCompressionShowsQualityAndRatio() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "jpg")

        try await FormatCommand.parse([
            input,
            "-o", out.path,
            "--format", "jpg",
            "--quality", "0.8",
            "--force"
        ]).run()

        CommandTestHarness.cleanup(out)
    }

    func testFormatTIFFExpansionRatio() async throws {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "tiff")

        try await FormatCommand.parse([
            input,
            "-o", out.path,
            "--format", "tiff",
            "--force"
        ]).run()

        CommandTestHarness.cleanup(out)
    }

    // MARK: - Edit - Resize

    func testResizeMustSpecifyDimension() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png").path

        await XCTAssertThrowsErrorAsync(
            try await ResizeCommand.parse([input, "-o", out]).run()
        )
    }

    func testResizeScaleBranch() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")

        try await ResizeCommand.parse([
            input,
            "-o", out.path,
            "--scale", "0.5",
            "--force"
        ]).run()

        CommandTestHarness.cleanup(out)
    }

    func testResizeWidthHeightStretch() async throws {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "jpg")

        try await ResizeCommand.parse([
            input,
            "-o", out.path,
            "--width", "200",
            "--height", "150",
            "--stretch",
            "--force"
        ]).run()

        CommandTestHarness.cleanup(out)
    }

    func testResizeOutputExistsWithoutForce() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        FileManager.default.createFile(atPath: out.path, contents: Data([0x00]))

        await XCTAssertThrowsErrorAsync(
            try await ResizeCommand.parse([
                input,
                "-o", out.path,
                "--width", "50"
            ]).run()
        )

        CommandTestHarness.cleanup(out)
    }

    // MARK: - Detect

    func testFaceCommandFastJSONWithThreshold() async throws {
        let face = CommandTestHarness.fixture("face_512x512.png").path
        try await FaceCommand.parse([
            face,
            "--fast",
            "--format", "json",
            "--threshold", "0.2"
        ]).run()
    }

    func testFaceCommandNoResultsBranch() async throws {
        let none = CommandTestHarness.fixture("rectangle_512x512.png").path
        try await FaceCommand.parse([none, "--threshold", "0.0"]).run()
    }

    func testHandCommandJSONPixels() async throws {
        let hand = CommandTestHarness.fixture("hand_512x512.png").path
        try await HandCommand.parse([
            hand,
            "--format", "json",
            "--pixels",
            "--max-hands", "1",
            "--threshold", "0.0"
        ]).run()
    }

    func testHandCommandNoResultsBranch() async throws {
        let none = CommandTestHarness.fixture("rectangle_512x512.png").path
        try await HandCommand.parse([none, "--threshold", "0.0"]).run()
    }

    func testPetPoseCommandPixelsJSON() async throws {
        let cat = CommandTestHarness.fixture("cat_512x512.png").path
        try await PetPoseCommand.parse([
            cat,
            "--pixels",
            "--format", "json",
            "--threshold", "0.0"
        ]).run()
    }

    func testPetPoseCommandNoResultsBranch() async throws {
        let none = CommandTestHarness.fixture("rectangle_512x512.png").path
        try await PetPoseCommand.parse([none]).run()
    }

    // Face landmarks & Pose 补充分支

    func testFaceCommandLandmarksTable() async throws {
        let face = CommandTestHarness.fixture("face_512x512.png").path
        try await FaceCommand.parse([face]).run()
    }

    func testFaceCommandLandmarksJSON() async throws {
        let face = CommandTestHarness.fixture("face_512x512.png").path
        try await FaceCommand.parse([face, "--format", "json"]).run()
    }

    func testPoseCommandNormalizedTable() async throws {
        let person = CommandTestHarness.fixture("foreground_person_indoor_512x512.jpg").path
        try await PoseCommand.parse([person, "--threshold", "0.0"]).run()
    }

    func testPoseCommandJSONWithPixelsAndSize() async throws {
        let person = CommandTestHarness.fixture("foreground_person_indoor_512x512.jpg").path
        try await PoseCommand.parse([person, "--pixels", "--format", "json", "--threshold", "0.0"]).run()
    }

    func testPoseCommandNoResultsBranch() async throws {
        let none = CommandTestHarness.fixture("rectangle_512x512.png").path
        try await PoseCommand.parse([none]).run()
    }
}
