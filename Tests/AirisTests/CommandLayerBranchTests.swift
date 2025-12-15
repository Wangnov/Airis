import XCTest
import ArgumentParser
@testable import Airis

/// 覆盖命令层剩余分支，配合 smoke 覆盖冲刺 100%。
final class CommandLayerBranchTests: XCTestCase {
    override func setUp() {
        super.setUp()
        setenv("AIRIS_CONFIG_FILE", CommandTestHarness.temporaryFile(ext: "json").path, 1)
        setenv("AIRIS_TEST_MODE", "1", 1)
    }

    override func tearDown() {
        unsetenv("AIRIS_CONFIG_FILE")
        unsetenv("AIRIS_TEST_MODE")
        unsetenv("AIRIS_FORCE_SCORE_FALLBACK")
        unsetenv("AIRIS_SAFE_POLICY_DISABLED")
        unsetenv("AIRIS_SAFE_FORCE_SENSITIVE")
        unsetenv("AIRIS_SCORE_UTILITY_FALSE")
        unsetenv("AIRIS_SCORE_TEST_VALUE")
        unsetenv("AIRIS_SIMILAR_TEST_DISTANCE")
        super.tearDown()
    }

    // MARK: Analyze - Meta / Safe / Score / OCR / Similar / Tag

    func testMetaReadWriteBranches() async throws {
        let jpg = CommandTestHarness.fixture("medium_512x512.jpg").path
        let png = CommandTestHarness.fixture("small_100x100.png").path

        // 读取分支：table + json + 分类过滤
        try await MetaCommand.parse([jpg, "--format", "table", "--category", "exif"]).run()
        try await MetaCommand.parse([jpg, "--format", "json", "--category", "gps"]).run()
        // 读取分支：表格 all，覆盖 EXIF/GPS/TIFF/IPTC/基本信息
        try await MetaCommand.parse([jpg, "--format", "table"]).run()
        // 读取分支：JSON all
        try await MetaCommand.parse([jpg, "--format", "json"]).run()

        // 写入分支：clear-all，默认输出路径 + png 格式
        try await MetaCommand.parse([png, "--clear-all"]).run()

        // 写入分支：set-comment + bmp 扩展，覆盖默认格式分支
        let bmpCopy = CommandTestHarness.temporaryFile(ext: "bmp")
        try FileManager.default.copyItem(atPath: png, toPath: bmpCopy.path)
        try await MetaCommand.parse([bmpCopy.path, "--set-comment", "branch", "--format", "json"]).run()
        CommandTestHarness.cleanup(bmpCopy)
    }

    func testSafeCommandTableAndDisabledPolicy() async throws {
        let image = CommandTestHarness.fixture("medium_512x512.jpg").path

        // 正常测试模式（table）
        try await SafeCommand.parse([image]).run()

        // 覆盖 policy disabled 分支
        setenv("AIRIS_SAFE_POLICY_DISABLED", "1", 1)
        try await SafeCommand.parse([image, "--format", "json"]).run()
        try await SafeCommand.parse([image, "--format", "table"]).run()
        unsetenv("AIRIS_SAFE_POLICY_DISABLED")

        // 覆盖敏感结果分支
        setenv("AIRIS_SAFE_FORCE_SENSITIVE", "1", 1)
        try await SafeCommand.parse([image, "--format", "table"]).run()
        unsetenv("AIRIS_SAFE_FORCE_SENSITIVE")
    }

    func testSafeCommandQuietSkipsHumanOutput() async throws {
        let image = CommandTestHarness.fixture("medium_512x512.jpg").path
        let originalQuiet = AirisRuntime.isQuiet
        defer { AirisRuntime.isQuiet = originalQuiet }

        AirisRuntime.isQuiet = true
        try await SafeCommand.parse([image]).run()
    }

    func testSafeCommandDebugStubWithoutTestMode() async throws {
        let image = CommandTestHarness.fixture("medium_512x512.jpg").path
        unsetenv("AIRIS_TEST_MODE") // 走 DEBUG 桩路径
        try await SafeCommand.parse([image, "--format", "table"]).run()
        setenv("AIRIS_TEST_MODE", "1", 1)
    }

    func testScoreCommandTableAndFallback() async throws {
        let image = CommandTestHarness.fixture("medium_512x512.jpg").path
        setenv("AIRIS_FORCE_SCORE_FALLBACK", "1", 1)
        try await ScoreCommand.parse([image]).run() // 默认 table + fallback 提示
    }

    func testScoreCommandJSONUtilityFalse() async throws {
        let image = CommandTestHarness.fixture("medium_512x512.jpg").path
        setenv("AIRIS_SCORE_UTILITY_FALSE", "1", 1)
        try await ScoreCommand.parse([image, "--format", "json"]).run()
    }

    func testScoreCommandTablePoorRating() async throws {
        let image = CommandTestHarness.fixture("medium_512x512.jpg").path
        setenv("AIRIS_SCORE_TEST_VALUE", "-0.6", 1)
        try await ScoreCommand.parse([image]).run()
        unsetenv("AIRIS_SCORE_TEST_VALUE")
    }

    func testScoreCommandTableFairRating() async throws {
        let image = CommandTestHarness.fixture("medium_512x512.jpg").path
        setenv("AIRIS_SCORE_TEST_VALUE", "-0.2", 1)
        setenv("AIRIS_SCORE_UTILITY_FALSE", "1", 1)
        try await ScoreCommand.parse([image]).run()
        unsetenv("AIRIS_SCORE_TEST_VALUE")
    }

    func testScoreCommandTableGoodRating() async throws {
        let image = CommandTestHarness.fixture("medium_512x512.jpg").path
        setenv("AIRIS_SCORE_TEST_VALUE", "0.30", 1) // 覆盖“良好”分支
        setenv("AIRIS_SCORE_UTILITY_FALSE", "1", 1)
        try await ScoreCommand.parse([image]).run()
        unsetenv("AIRIS_SCORE_TEST_VALUE")
        unsetenv("AIRIS_SCORE_UTILITY_FALSE")
    }

    func testScoreCommandDebugFallbackWithoutTestMode() async throws {
        let image = CommandTestHarness.fixture("medium_512x512.jpg").path
        unsetenv("AIRIS_TEST_MODE") // 走 DEBUG 降级提示分支
        try await ScoreCommand.parse([image]).run()
        setenv("AIRIS_TEST_MODE", "1", 1) // 恢复
    }

    func testScoreCommandDebugFallbackWithoutTestModeJSON() async throws {
        let image = CommandTestHarness.fixture("medium_512x512.jpg").path
        unsetenv("AIRIS_TEST_MODE") // 走 DEBUG 降级 JSON 分支
        try await ScoreCommand.parse([image, "--format", "json"]).run()
        setenv("AIRIS_TEST_MODE", "1", 1) // 恢复
    }

    func testOCRCommandJSONWithBounds() async throws {
        let image = CommandTestHarness.fixture("document_text_512x512.png").path
        try await OCRCommand.parse([image, "--format", "json", "--show-bounds", "--languages", "en"]).run()
    }

    func testOCRCommandPlainText() async throws {
        let image = CommandTestHarness.fixture("document_text_512x512.png").path
        try await OCRCommand.parse([image, "--format", "text", "--level", "fast"]).run()
    }

    func testOCRCommandNoResultsTableBranch() async throws {
        let image = CommandTestHarness.fixture("rectangle_512x512.png").path
        try await OCRCommand.parse([image, "--format", "table", "--level", "fast"]).run()
    }

    func testSimilarCommandTable() async throws {
        let img1 = CommandTestHarness.fixture("small_100x100.png").path
        let img2 = CommandTestHarness.fixture("medium_512x512.jpg").path
        try await SimilarCommand.parse([img1, img2, "--format", "table"]).run()
    }

    func testSimilarCommandRatingsViaStub() async throws {
        let img1 = CommandTestHarness.fixture("small_100x100.png").path
        let img2 = CommandTestHarness.fixture("medium_512x512.jpg").path

        // 非常相似
        setenv("AIRIS_SIMILAR_TEST_DISTANCE", "0.10", 1)
        try await SimilarCommand.parse([img1, img2, "--format", "json"]).run()

        // 相似
        setenv("AIRIS_SIMILAR_TEST_DISTANCE", "0.50", 1)
        try await SimilarCommand.parse([img1, img2, "--format", "table"]).run()

        // 有些相似
        setenv("AIRIS_SIMILAR_TEST_DISTANCE", "1.00", 1)
        try await SimilarCommand.parse([img1, img2]).run()

        // 不同
        setenv("AIRIS_SIMILAR_TEST_DISTANCE", "1.60", 1)
        try await SimilarCommand.parse([img1, img2, "--format", "json"]).run()

        unsetenv("AIRIS_SIMILAR_TEST_DISTANCE")
    }

    func testTagCommandTableLimit() async throws {
        let image = CommandTestHarness.fixture("medium_512x512.jpg").path
        try await TagCommand.parse([image, "--format", "table", "--limit", "1", "--threshold", "0.0"]).run()
    }

    // MARK: Detect
    func testPoseCommandsTableAndPixels() async throws {
        let person = CommandTestHarness.fixture("foreground_person_indoor_512x512.jpg").path
        try await PoseCommand.parse([person, "--format", "table", "--pixels", "--threshold", "0.0"]).run()
    }

    func testPose3DAndPetPoseTable() async throws {
        let person = CommandTestHarness.fixture("foreground_person_indoor_512x512.jpg").path
        let cat = CommandTestHarness.fixture("cat_512x512.png").path
        try await Pose3DCommand.parse([person, "--format", "table", "--threshold", "0.0"]).run()
        try await PetPoseCommand.parse([cat, "--format", "table", "--threshold", "0.0"]).run()
    }

    func testHandCommandTableAndEmptyBranch() async throws {
        let hand = CommandTestHarness.fixture("hand_512x512.png").path
        try await HandCommand.parse([hand, "--format", "table", "--threshold", "0.0"]).run()
        // 高阈值触发空结果打印
        try await HandCommand.parse([hand, "--threshold", "1.0"]).run()
    }

    func testPoseCommandEmptyBranch() async throws {
        let person = CommandTestHarness.fixture("foreground_person_indoor_512x512.jpg").path
        try await PoseCommand.parse([person, "--threshold", "1.0"]).run()
    }

    func testAnimalCommandTableAndNoResults() async throws {
        let cat = CommandTestHarness.fixture("cat_512x512.png").path
        // 有结果 + 类型过滤 + 阈值提示
        try await AnimalCommand.parse([cat, "--type", "cat", "--format", "table", "--threshold", "0.1"]).run()

        // 高阈值触发空结果分支
        try await AnimalCommand.parse([cat, "--threshold", "1.0"]).run()
    }

    func testBarcodeCommandTypeFilterTable() async throws {
        let qr = CommandTestHarness.fixture("qrcode_512x512.png").path
        try await BarcodeCommand.parse([qr, "--type", "qr", "--format", "table"]).run()
    }

    // MARK: Vision

    func testVisionCommandsTableBranches() async throws {
        let img1 = CommandTestHarness.fixture("medium_512x512.jpg").path
        let img2 = CommandTestHarness.fixture("rectangle_512x512.png").path
        let person = CommandTestHarness.fixture("foreground_person_indoor_512x512.jpg").path

        try await AlignCommand.parse([img1, img2, "--format", "table"]).run()
        try await FlowCommand.parse([img1, img2, "--format", "table"]).run()
        try await PersonsCommand.parse([person, "--format", "json"]).run() // json 分支覆盖
    }

    func testSaliencyCommandTable() async throws {
        let image = CommandTestHarness.fixture("medium_512x512.jpg").path
        try await SaliencyCommand.parse([image, "--type", "objectness", "--format", "table"]).run()
    }

    func testVisionOutputSavingBranches() async throws {
        let img1 = CommandTestHarness.fixture("medium_512x512.jpg").path
        let img2 = CommandTestHarness.fixture("rectangle_512x512.png").path
        let alignOut = CommandTestHarness.temporaryFile(ext: "png").path
        let flowOut = CommandTestHarness.temporaryFile(ext: "png").path
        try await AlignCommand.parse([img1, img2, "--format", "json", "-o", alignOut]).run()
        try await FlowCommand.parse([img1, img2, "--format", "json", "--output", flowOut]).run()
        CommandTestHarness.cleanup(URL(fileURLWithPath: alignOut))
        CommandTestHarness.cleanup(URL(fileURLWithPath: flowOut))
    }

    func testPersonsCommandTableDefaultQuality() async throws {
        let person = CommandTestHarness.fixture("foreground_person_indoor_512x512.jpg").path
        try await PersonsCommand.parse([person, "--format", "table"]).run()
    }

    // MARK: Gen

    func testGenDrawCommandRevealWithRef() async throws {
        let ref = CommandTestHarness.fixture("small_100x100.png").path
        let output = CommandTestHarness.temporaryFile(ext: "png").path
        // 测试模式下使用 GeminiProvider stub（避免网络），同时覆盖 ref 校验与 reveal/open 路径
        try await DrawCommand.parse([
            "test reveal prompt",
            "--ref", ref,
            "--reveal",
            "--output", output
        ]).run()
        CommandTestHarness.cleanup(URL(fileURLWithPath: output))
    }

    func testGenDrawCommandAutoOutputAndOpen() async throws {
        let outputEnv = CommandTestHarness.temporaryFile(ext: "png")
        // 不指定 --output 触发自动路径，开启 open 分支
        try await DrawCommand.parse([
            "auto output prompt",
            "--open"
        ]).run()
        CommandTestHarness.cleanup(outputEnv)
    }

    func testGenDrawCommandProviderOptionBranch() async throws {
        let output = CommandTestHarness.temporaryFile(ext: "png")
        defer { CommandTestHarness.cleanup(output) }
        try await DrawCommand.parse([
            "provider option prompt",
            "--provider", "gemini",
            "--output", output.path
        ]).run()
    }

    func testGenDrawCommandFallbackProviderWhenConfigHasNoDefaultProvider() async throws {
        let configPath = try XCTUnwrap(ProcessInfo.processInfo.environment["AIRIS_CONFIG_FILE"])
        let configURL = URL(fileURLWithPath: configPath)

        // 写入一个不包含 default_provider 的配置，覆盖 provider ?? nil ?? "gemini" 的最后兜底分支
        let json = #"{"providers":{}}"#
        let data = try XCTUnwrap(json.data(using: .utf8))
        try data.write(to: configURL, options: [.atomic])
        defer { try? FileManager.default.removeItem(at: configURL) }

        let output = CommandTestHarness.temporaryFile(ext: "png")
        defer { CommandTestHarness.cleanup(output) }
        try await DrawCommand.parse([
            "fallback provider prompt",
            "--output", output.path
        ]).run()
    }

    func testGenDrawCommandOpenAndRevealForceFailBranches() throws {
        setenv("AIRIS_FORCE_DRAW_OPEN_FAIL", "1", 1)
        setenv("AIRIS_FORCE_DRAW_REVEAL_FAIL", "1", 1)
        defer {
            unsetenv("AIRIS_FORCE_DRAW_OPEN_FAIL")
            unsetenv("AIRIS_FORCE_DRAW_REVEAL_FAIL")
        }

        let cmd = try DrawCommand.parse(["open fail prompt"])
        let dummyURL = URL(fileURLWithPath: "/tmp/airis_draw_dummy.png")
        cmd.testOpenWithDefaultApp(dummyURL, isTestMode: true)
        cmd.testOpenInFinder(dummyURL, isTestMode: true)
    }

    // MARK: Edit

    func testEnhanceVerboseNoRedeyeOpen() async throws {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "jpg").path
        try await EnhanceCommand.parse([input, "-o", out, "--no-redeye", "--verbose", "--open", "--force"]).run()
        CommandTestHarness.cleanup(URL(fileURLWithPath: out))
    }
}
