import XCTest
#if !XCODE_BUILD
@testable import AirisCore
#endif

/// 第十批覆盖补齐：Animal 无结果 JSON、Similar 表格、Score 实用性提示。
final class CommandLayerCoverageSprint10Tests: XCTestCase {
    override func tearDown() {
        let envs = [
            "AIRIS_TEST_MODE",
            "AIRIS_SIMILAR_TEST_DISTANCE",
            "AIRIS_SCORE_TEST_VALUE",
            "AIRIS_SCORE_UTILITY_FALSE"
        ]
        envs.forEach { unsetenv($0) }
        super.tearDown()
    }

    func testAnimalNoResultsJSONWithFilterAndThreshold() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        try await AnimalCommand.parse([
            input,
            "--type", "cat",
            "--threshold", "0.5",
            "--format", "json"
        ]).run()
    }

    func testSimilarTableBranchInTestMode() async throws {
        setenv("AIRIS_TEST_MODE", "1", 1)
        setenv("AIRIS_SIMILAR_TEST_DISTANCE", "0.8", 1) // similarity ~0.60
        let img1 = CommandTestHarness.fixture("small_100x100.png").path
        let img2 = CommandTestHarness.fixture("small_100x100_meta.png").path
        try await SimilarCommand.parse([img1, img2]).run()
    }

    func testScoreUtilityHintTable() async throws {
        setenv("AIRIS_TEST_MODE", "1", 1)
        unsetenv("AIRIS_SCORE_UTILITY_FALSE") // 保持 isUtility = true
        setenv("AIRIS_SCORE_TEST_VALUE", "0.12", 1) // 一般评级，仍显示提示
        let input = CommandTestHarness.fixture("small_100x100.png").path
        try await ScoreCommand.parse([input]).run()
    }
}
