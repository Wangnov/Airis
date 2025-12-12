import XCTest
@testable import Airis

/// 覆盖各命令的 --open / 成功路径，借助 openForCLI 在测试模式跳过实际打开。
final class CommandLayerCoverageOpenPathsTests: XCTestCase {
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

    // MARK: Adjust / Temperature / Rotate / Invert
    func testTemperatureCommandOpenPath() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "jpg")
        try await TemperatureCommand.parse([input, "-o", out.path, "--temp", "500", "--tint", "20", "--open", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    func testRotateCommandOpenPath() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        try await RotateCommand.parse([input, "-o", out.path, "--angle", "45", "--open", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    func testInvertCommandOpenPath() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        try await InvertCommand.parse([input, "-o", out.path, "--open", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    // MARK: Filters success + open
    func testFilterChromeOpen() async throws {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "jpg")
        try await ChromeCommand.parse([input, "-o", out.path, "--open", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    func testFilterComicOpen() async throws {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        try await ComicCommand.parse([input, "-o", out.path, "--open", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    func testFilterInstantOpen() async throws {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        try await InstantCommand.parse([input, "-o", out.path, "--open", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    func testFilterMonoOpen() async throws {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        try await MonoCommand.parse([input, "-o", out.path, "--open", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    func testFilterNoirOpen() async throws {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        try await NoirCommand.parse([input, "-o", out.path, "--open", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    func testFilterHalftoneOpen() async throws {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        try await HalftoneCommand.parse([input, "-o", out.path, "--width", "6", "--angle", "15", "--open", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    func testFilterPixelOpen() async throws {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        try await PixelCommand.parse([input, "-o", out.path, "--scale", "12", "--open", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    func testFilterSepiaOpen() async throws {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        try await SepiaCommand.parse([input, "-o", out.path, "--intensity", "0.8", "--open", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    func testFilterBlurOpen() async throws {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        try await BlurCommand.parse([input, "-o", out.path, "--radius", "8", "--type", "gaussian", "--open", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    func testFilterSharpenOpen() async throws {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        try await SharpenCommand.parse([input, "-o", out.path, "--intensity", "1.0", "--open", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    // MARK: 基础编辑
    func testCutCommandOpen() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        try await CutCommand.parse([input, "-o", out.path, "--open", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    func testDefringeCommandOpen() async throws {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "jpg")
        try await DefringeCommand.parse([input, "-o", out.path, "--amount", "0.6", "--open", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    func testScanCommandOpen() async throws {
        let input = CommandTestHarness.fixture("rectangle_512x512.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        try await ScanCommand.parse([input, "-o", out.path, "--open", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    func testStraightenCommandOpen() async throws {
        let input = CommandTestHarness.fixture("horizon_clear_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "jpg")
        try await StraightenCommand.parse([input, "-o", out.path, "--open", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    func testThumbCommandOpen() async throws {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "jpg")
        try await ThumbCommand.parse([input, "-o", out.path, "--size", "128", "--open", "--force"]).run()
        CommandTestHarness.cleanup(out)
    }

    func testTraceCommandOpen() async throws {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        try await TraceCommand.parse([input, "-o", out.path, "--open", "--force", "--style", "work", "--radius", "5"]).run()
        CommandTestHarness.cleanup(out)
    }

    // MARK: Vision 输出保存 + openForCLI（仅跳过实际打开）
    func testAlignCommandOutputOpen() async throws {
        let img1 = CommandTestHarness.fixture("medium_512x512.jpg").path
        let img2 = CommandTestHarness.fixture("rectangle_512x512.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        try await AlignCommand.parse([img1, img2, "--format", "json", "-o", out.path]).run()
        CommandTestHarness.cleanup(out)
    }

    func testFlowCommandOutputOpen() async throws {
        let img1 = CommandTestHarness.fixture("medium_512x512.jpg").path
        let img2 = CommandTestHarness.fixture("rectangle_512x512.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        try await FlowCommand.parse([img1, img2, "--format", "json", "--output", out.path]).run()
        CommandTestHarness.cleanup(out)
    }

    func testPersonsCommandOutputOpen() async throws {
        let person = CommandTestHarness.fixture("foreground_person_indoor_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "png")
        try await PersonsCommand.parse([person, "--format", "json", "--output", out.path, "--open"]).run()
        CommandTestHarness.cleanup(out)
    }

    // MARK: Gen Config 补充
    func testGenConfigShowAllOpen() async throws {
        let out = CommandTestHarness.temporaryFile(ext: "txt")
        _ = out // 保持输出变量使用，避免未使用警告
        // show --all 本身不写文件，但覆盖 run 分支
        try await ShowConfigCommand.parse([]).run()
        CommandTestHarness.cleanup(out)
    }
}
