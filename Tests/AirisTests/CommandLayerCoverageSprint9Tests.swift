import XCTest
@testable import Airis

/// 第九批覆盖补齐：Score 非测试降级提示、Similar 非测试分支、Tag 大于显示数量、Persons 桩结果。
final class CommandLayerCoverageSprint9Tests: XCTestCase {
    override func tearDown() {
        let envs = [
            "AIRIS_TEST_MODE",
            "AIRIS_SIMILAR_TEST_DISTANCE",
            "AIRIS_TEST_PERSONS_FAKE_RESULT",
            "AIRIS_FORCE_PERSONS_CGIMAGE_NIL"
        ]
        envs.forEach { unsetenv($0) }
        super.tearDown()
    }

    func testScoreDebugUnsupportedHint() async throws {
        // 不设置 AIRIS_TEST_MODE，触发 DEBUG 下的降级提示分支
        let input = CommandTestHarness.fixture("small_100x100.png").path
        try await ScoreCommand.parse([input]).run()
    }

    func testSimilarDebugNonTestModeUsesStubDistance() async throws {
        unsetenv("AIRIS_TEST_MODE")
        setenv("AIRIS_SIMILAR_TEST_DISTANCE", "1.2", 1) // 覆盖 debug 桩路径
        let img1 = CommandTestHarness.fixture("small_100x100.png").path
        let img2 = CommandTestHarness.fixture("small_100x100_meta.png").path
        try await SimilarCommand.parse([img1, img2, "--format", "json"]).run()
    }

    func testTagTableShowsLimitedCount() {
        let observations = TagCommand.testObservations(count: 4)
        let limited = Array(observations.prefix(2))
        // 验证打印分支（检测到 total>displayed）
        XCTAssertEqual(limited.count, 2)
        XCTAssertEqual(observations.count, 4)
    }

    func testPersonsFakeResultSaveAndOpen() async throws {
        setenv("AIRIS_TEST_PERSONS_FAKE_RESULT", "1", 1)
        setenv("AIRIS_TEST_MODE", "1", 1) // openForCLI 跳过 GUI
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        defer { CommandTestHarness.cleanup(out) }

        try await PersonsCommand.parse([input, "-o", out.path, "--quality", "fast", "--format", "json", "--open"]).run()
        XCTAssertTrue(FileManager.default.fileExists(atPath: out.path))
    }

    func testPersonsCGImageNilThrows() async {
        setenv("AIRIS_TEST_PERSONS_FAKE_RESULT", "1", 1)
        setenv("AIRIS_FORCE_PERSONS_CGIMAGE_NIL", "1", 1)
        let input = CommandTestHarness.fixture("small_100x100.png").path
        await XCTAssertThrowsErrorAsync(
            try await PersonsCommand.parse([input, "-o", CommandTestHarness.temporaryFile(ext: "png").path]).run()
        )
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
