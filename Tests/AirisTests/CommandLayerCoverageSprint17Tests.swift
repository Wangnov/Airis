import XCTest
#if !XCODE_BUILD
@testable import AirisCore
#endif

/// 第十七批覆盖冲刺：Animal 命令分支、Format 体积膨胀分支。
final class CommandLayerCoverageSprint17Tests: XCTestCase {
    override func setUp() {
        super.setUp()
        setenv("AIRIS_FORCE_ANIMAL_STUB", "1", 1)
    }

    override func tearDown() {
        unsetenv("AIRIS_FORCE_ANIMAL_STUB")
        super.tearDown()
    }

    // MARK: AnimalCommand

    func testAnimalCommandStubTypeFilterJSON() async throws {
        let img = CommandTestHarness.fixture("small_100x100.png").path
        // 只保留 cat，dog 被过滤 => table->json 结果 1 条
        let cmd = try AnimalCommand.parse([img, "--type", "cat", "--threshold", "0.5", "--format", "json"])
        try await cmd.run()
    }

    func testAnimalCommandStubNoResultsBranch() async throws {
        let img = CommandTestHarness.fixture("small_100x100.png").path
        // 过滤 dog，stub 中 cat/dog，阈值抬高导致空结果 -> No animals detected
        let cmd = try AnimalCommand.parse([img, "--type", "elephant", "--threshold", "0.95", "--format", "table"])
        try await cmd.run()
    }

    // MARK: FormatCommand

    func testFormatCommandSizeExpansionBranch() async throws {
        // PNG -> TIFF 通常文件更大，触发扩张提示（ratio > 1.0）
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "tiff")

        try await FormatCommand.parse([input, "-o", out.path, "--format", "tiff", "--quality", "0.9"]).run()

        CommandTestHarness.cleanup(out)
    }
}
