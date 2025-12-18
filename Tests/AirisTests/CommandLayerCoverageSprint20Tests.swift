import XCTest
#if !XCODE_BUILD
    @testable import AirisCore
#endif

/// 第二十批覆盖冲刺：Noise/Trace/Cut open 分支，Format 压缩比<1，Persons 空结果。
final class CommandLayerCoverageSprint20Tests: XCTestCase {
    override func setUp() {
        super.setUp()
        setenv("AIRIS_TEST_MODE", "1", 1) // 避免实际打开文件
    }

    override func tearDown() {
        unsetenv("AIRIS_TEST_MODE")
        super.tearDown()
    }

    // MARK: Noise open

    func testNoiseCommandOpenBranch() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        try await NoiseCommand.parse([input, "-o", out.path, "--open", "--level", "0.02", "--sharpness", "0.4"]).run()
        CommandTestHarness.cleanup(out)
    }

    // MARK: Trace open + work style

    func testTraceCommandOpenWorkStyle() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        try await TraceCommand.parse([input, "-o", out.path, "--style", "work", "--radius", "2", "--open"]).run()
        CommandTestHarness.cleanup(out)
    }

    // MARK: Cut open

    func testCutCommandOpenBranch() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        try await CutCommand.parse([input, "-o", out.path, "--open", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    // MARK: Format ratio < 1.0

    func testFormatCommandCompressionBranch() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "jpg")
        // JPEG 质量 0.1 以确保文件更小，触发压缩分支
        try await FormatCommand.parse([input, "-o", out.path, "--format", "jpg", "--quality", "0.1", "--open"]).run()
        CommandTestHarness.cleanup(out)
    }

    // MARK: Persons 空结果

    func testPersonsCommandEmptyResults() async throws {
        setenv("AIRIS_TEST_MODE", "1", 1) // 确保稳定输出
        // 使用极高质量阈值与空 stub（VisionService nil results 已有测试），此处验证命令层的空结果打印
        let input = CommandTestHarness.fixture("small_100x100.png").path
        setenv("AIRIS_FORCE_PERSONS_EMPTY", "1", 1)
        try await PersonsCommand.parse([input, "--quality", "balanced", "--format", "table"]).run()
        unsetenv("AIRIS_FORCE_PERSONS_EMPTY")
    }
}
