import XCTest
@testable import Airis

/// 第七批覆盖补齐：聚焦 Vision 命令与高风险输出路径。
final class CommandLayerCoverageSprint7Tests: XCTestCase {
    override func tearDown() {
        let envs = [
            "AIRIS_TEST_FLOW_FAKE_RESULT",
            "AIRIS_FORCE_FLOW_CGIMAGE_NIL",
            "AIRIS_TEST_ALIGN_FAKE_RESULT",
            "AIRIS_FORCE_ALIGN_RENDER_NIL",
            "AIRIS_TEST_SALIENCY_FAKE_RESULT",
            "AIRIS_TEST_SALIENCY_EMPTY",
            "AIRIS_FORCE_SALIENCY_CGIMAGE_NIL",
            "AIRIS_FORCE_SCAN_NO_RECT",
            "AIRIS_FORCE_SCAN_PERSPECTIVE_NIL",
            "AIRIS_FORCE_SCAN_RENDER_NIL",
            "AIRIS_FORCE_THUMB_SOURCE_NIL",
            "AIRIS_FORCE_THUMB_THUMB_NIL",
            "AIRIS_FORCE_POSE3D_UNSUPPORTED",
            "AIRIS_FORCE_POSE3D_EMPTY",
            "AIRIS_FORCE_POSE3D_MISSING_JOINT"
        ]
        envs.forEach { unsetenv($0) }
        super.tearDown()
    }

    // MARK: Flow
    func testFlowHighAccuracySavesOutput() async throws {
        setenv("AIRIS_TEST_FLOW_FAKE_RESULT", "1", 1)
        let input1 = CommandTestHarness.fixture("small_100x100.png").path
        let input2 = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        defer { CommandTestHarness.cleanup(out) }

        try await FlowCommand.parse([input1, input2, "--accuracy", "high", "-o", out.path]).run()
        XCTAssertTrue(FileManager.default.fileExists(atPath: out.path))
    }

    func testFlowVeryHighAccuracyJSON() async throws {
        setenv("AIRIS_TEST_FLOW_FAKE_RESULT", "1", 1)
        let input1 = CommandTestHarness.fixture("small_100x100.png").path
        let input2 = CommandTestHarness.fixture("small_100x100.png").path

        try await FlowCommand.parse([input1, input2, "--accuracy", "veryHigh", "--format", "json"]).run()
    }

    func testFlowInvalidAccuracyFallsBack() async throws {
        setenv("AIRIS_TEST_FLOW_FAKE_RESULT", "1", 1)
        let input1 = CommandTestHarness.fixture("small_100x100.png").path
        let input2 = CommandTestHarness.fixture("small_100x100.png").path

        try await FlowCommand.parse([input1, input2, "--accuracy", "unknown"]).run()
    }

    func testFlowVisualizationCGImageNilThrows() async {
        setenv("AIRIS_TEST_FLOW_FAKE_RESULT", "1", 1)
        setenv("AIRIS_FORCE_FLOW_CGIMAGE_NIL", "1", 1)
        let input1 = CommandTestHarness.fixture("small_100x100.png").path
        let input2 = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        defer { CommandTestHarness.cleanup(out) }

        await XCTAssertThrowsErrorAsync(
            try await FlowCommand.parse([input1, input2, "-o", out.path]).run()
        )
    }

    // MARK: Align
    func testAlignTableWithOutput() async throws {
        setenv("AIRIS_TEST_ALIGN_FAKE_RESULT", "1", 1)
        let ref = CommandTestHarness.fixture("small_100x100.png").path
        let floating = CommandTestHarness.fixture("small_100x100_meta.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        defer { CommandTestHarness.cleanup(out) }

        try await AlignCommand.parse([ref, floating, "-o", out.path]).run()
        XCTAssertTrue(FileManager.default.fileExists(atPath: out.path))
    }

    func testAlignRenderNilThrows() async {
        setenv("AIRIS_TEST_ALIGN_FAKE_RESULT", "1", 1)
        setenv("AIRIS_FORCE_ALIGN_RENDER_NIL", "1", 1)
        let ref = CommandTestHarness.fixture("small_100x100.png").path
        let floating = CommandTestHarness.fixture("small_100x100_meta.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        defer { CommandTestHarness.cleanup(out) }

        await XCTAssertThrowsErrorAsync(
            try await AlignCommand.parse([ref, floating, "-o", out.path]).run()
        )
    }

    func testAlignJSONWithOutput() async throws {
        setenv("AIRIS_TEST_ALIGN_FAKE_RESULT", "1", 1)
        let ref = CommandTestHarness.fixture("small_100x100.png").path
        let floating = CommandTestHarness.fixture("small_100x100_meta.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        defer { CommandTestHarness.cleanup(out) }

        try await AlignCommand.parse([ref, floating, "--format", "json", "-o", out.path]).run()
    }

    func testAlignWithoutOutputBranch() async throws {
        setenv("AIRIS_TEST_ALIGN_FAKE_RESULT", "1", 1)
        let ref = CommandTestHarness.fixture("small_100x100.png").path
        let floating = CommandTestHarness.fixture("small_100x100_meta.png").path
        try await AlignCommand.parse([ref, floating]).run()
    }

    // MARK: Saliency
    func testSaliencyInvalidTypeFallsBack() async throws {
        setenv("AIRIS_TEST_SALIENCY_FAKE_RESULT", "1", 1)
        let input = CommandTestHarness.fixture("small_100x100.png").path
        try await SaliencyCommand.parse([input, "--type", "invalid"]).run()
    }

    func testSaliencySaveHeatmapPrints() async throws {
        setenv("AIRIS_TEST_SALIENCY_FAKE_RESULT", "1", 1)
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        defer { CommandTestHarness.cleanup(out) }

        try await SaliencyCommand.parse([input, "--type", "attention", "-o", out.path]).run()
        XCTAssertTrue(FileManager.default.fileExists(atPath: out.path))
    }

    func testSaliencyHeatmapCGImageNilThrows() async {
        setenv("AIRIS_TEST_SALIENCY_FAKE_RESULT", "1", 1)
        setenv("AIRIS_FORCE_SALIENCY_CGIMAGE_NIL", "1", 1)
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        defer { CommandTestHarness.cleanup(out) }

        await XCTAssertThrowsErrorAsync(
            try await SaliencyCommand.parse([input, "-o", out.path]).run()
        )
    }

    func testSaliencyObjectnessJSON() async throws {
        setenv("AIRIS_TEST_SALIENCY_FAKE_RESULT", "1", 1)
        let input = CommandTestHarness.fixture("small_100x100.png").path
        try await SaliencyCommand.parse([input, "--type", "objectness", "--format", "json"]).run()
    }

    func testSaliencyJSONWithOutput() async throws {
        setenv("AIRIS_TEST_SALIENCY_FAKE_RESULT", "1", 1)
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        defer { CommandTestHarness.cleanup(out) }
        try await SaliencyCommand.parse([input, "--format", "json", "-o", out.path]).run()
        XCTAssertTrue(FileManager.default.fileExists(atPath: out.path))
    }

    func testSaliencyEmptyRegionsBranch() async throws {
        setenv("AIRIS_TEST_SALIENCY_FAKE_RESULT", "1", 1)
        setenv("AIRIS_TEST_SALIENCY_EMPTY", "1", 1)
        let input = CommandTestHarness.fixture("small_100x100.png").path
        try await SaliencyCommand.parse([input]).run()
    }

    // MARK: Scan
    func testScanNoRectThrows() async {
        setenv("AIRIS_FORCE_SCAN_NO_RECT", "1", 1)
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        defer { CommandTestHarness.cleanup(out) }

        await XCTAssertThrowsErrorAsync(
            try await ScanCommand.parse([input, "-o", out.path]).run()
        )
    }

    func testScanPerspectiveNilThrows() async {
        setenv("AIRIS_FORCE_SCAN_PERSPECTIVE_NIL", "1", 1)
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        defer { CommandTestHarness.cleanup(out) }

        await XCTAssertThrowsErrorAsync(
            try await ScanCommand.parse([input, "-o", out.path]).run()
        )
    }

    func testScanRenderNilThrows() async {
        setenv("AIRIS_FORCE_SCAN_RENDER_NIL", "1", 1)
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        defer { CommandTestHarness.cleanup(out) }

        await XCTAssertThrowsErrorAsync(
            try await ScanCommand.parse([input, "-o", out.path]).run()
        )
    }

    // MARK: Thumb
    func testThumbInvalidSizeThrows() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        defer { CommandTestHarness.cleanup(out) }

        await XCTAssertThrowsErrorAsync(
            try await ThumbCommand.parse([input, "-o", out.path, "--size", "0"]).run()
        )
    }

    func testThumbInvalidQualityThrows() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        defer { CommandTestHarness.cleanup(out) }

        await XCTAssertThrowsErrorAsync(
            try await ThumbCommand.parse([input, "-o", out.path, "--quality", "1.5"]).run()
        )
    }

    func testThumbSourceNilThrows() async {
        setenv("AIRIS_FORCE_THUMB_SOURCE_NIL", "1", 1)
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        defer { CommandTestHarness.cleanup(out) }

        await XCTAssertThrowsErrorAsync(
            try await ThumbCommand.parse([input, "-o", out.path]).run()
        )
    }

    func testThumbThumbnailNilThrows() async {
        setenv("AIRIS_FORCE_THUMB_THUMB_NIL", "1", 1)
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        defer { CommandTestHarness.cleanup(out) }

        await XCTAssertThrowsErrorAsync(
            try await ThumbCommand.parse([input, "-o", out.path]).run()
        )
    }

    // MARK: Pose3D
    func testPose3DUnsupportedBranch() async throws {
        setenv("AIRIS_FORCE_POSE3D_UNSUPPORTED", "1", 1)
        let input = CommandTestHarness.fixture("small_100x100.png").path
        try await Pose3DCommand.parse([input]).run()
    }

    func testPose3DEmptyResultsBranch() async throws {
        setenv("AIRIS_FORCE_POSE3D_EMPTY", "1", 1)
        let input = CommandTestHarness.fixture("small_100x100.png").path
        try await Pose3DCommand.parse([input]).run()
    }

    func testPose3DUnknownJointHelper() {
        let name = Pose3DCommand._testJointNameString("custom_pose3d_joint")
        XCTAssertEqual(name, "unknown")
    }

    func testPose3DMissingJointBranch() async throws {
        setenv("AIRIS_FORCE_POSE3D_MISSING_JOINT", "1", 1)
        let input = CommandTestHarness.fixture("foreground_person_indoor_512x512.jpg").path
        try await Pose3DCommand.parse([input, "--format", "json"]).run()
    }

    func testPose3DMissingJointTableBranch() async throws {
        setenv("AIRIS_FORCE_POSE3D_MISSING_JOINT", "1", 1)
        let input = CommandTestHarness.fixture("foreground_person_indoor_512x512.jpg").path
        try await Pose3DCommand.parse([input]).run()
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
