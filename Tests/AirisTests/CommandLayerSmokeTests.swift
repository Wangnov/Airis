import XCTest
import ArgumentParser
#if !XCODE_BUILD
@testable import AirisCore
#endif

/// 轻量级命令层冒烟测试，覆盖核心子命令主路径。
final class CommandLayerSmokeTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // 隔离配置文件与测试模式
        setenv("AIRIS_CONFIG_FILE", CommandTestHarness.temporaryFile(ext: "json").path, 1)
        setenv("AIRIS_TEST_MODE", "1", 1)
    }

    override func tearDown() {
        unsetenv("AIRIS_CONFIG_FILE")
        unsetenv("AIRIS_TEST_MODE")
        super.tearDown()
    }

    // MARK: Analyze

    func testAnalyzePaletteCommandJSON() async throws {
        let image = CommandTestHarness.fixture("medium_512x512.jpg").path
        let cmd = try PaletteCommand.parse([image, "--count", "3", "--format", "json"])
        try await cmd.run()
    }

    func testAnalyzePaletteCommandTableWithAverage() async throws {
        let image = CommandTestHarness.fixture("medium_512x512.jpg").path
        let cmd = try PaletteCommand.parse([image, "--count", "4", "--include-average"])
        try await cmd.run()
    }

    func testAnalyzeSafeCommandTestMode() async throws {
        let image = CommandTestHarness.fixture("medium_512x512.jpg").path
        let cmd = try SafeCommand.parse([image, "--format", "json"])
        try await cmd.run()
    }

    func testAnalyzeInfoCommandTable() async throws {
        let image = CommandTestHarness.fixture("small_100x100.png").path
        let cmd = try InfoCommand.parse([image, "--format", "table"])
        try await cmd.run() // 确保默认表格输出路径可执行
    }

    func testAnalyzeInfoCommandJSON() async throws {
        let image = CommandTestHarness.fixture("medium_512x512.jpg").path
        let cmd = try InfoCommand.parse([image, "--format", "json"])
        try await cmd.run() // 覆盖 JSON 分支
    }

    func testAnalyzeTagCommandJSON() async throws {
        let image = CommandTestHarness.fixture("medium_512x512.jpg").path
        let cmd = try TagCommand.parse([image, "--limit", "5", "--threshold", "0.0", "--format", "json"])
        try await cmd.run()
    }

    func testGenConfigCommands() async throws {
        try await runCommand(SetKeyCommand.self, args: ["--provider", "testp", "--key", "TEST_API_KEY"])
        try await runCommand(GetKeyCommand.self, args: ["--provider", "testp"])
        try await runCommand(SetConfigCommand.self, args: ["--provider", "testp", "--base-url", "https://example.com", "--model", "m1"])
        try await runCommand(ShowConfigCommand.self, args: ["--provider", "testp"])
        try await runCommand(SetDefaultCommand.self, args: ["--provider", "testp"])
        try await runCommand(ResetConfigCommand.self, args: ["--provider", "testp"])
        try await runCommand(DeleteKeyCommand.self, args: ["--provider", "testp"])
    }

    func testShowConfigWithoutDefaultProviderSet() async throws {
        // 创建一个配置文件，其中没有设置 defaultProvider 字段
        let configFile = CommandTestHarness.temporaryFile(ext: "json")
        let configWithoutDefault = """
        {
            "providers": {
                "gemini": {
                    "base_url": "https://example.com",
                    "model": "test-model"
                }
            }
        }
        """
        try configWithoutDefault.data(using: .utf8)?.write(to: configFile)
        setenv("AIRIS_CONFIG_FILE", configFile.path, 1)

        // 运行 ShowConfigCommand，验证 defaultProvider 为 nil 时的 fallback 分支
        try await runCommand(ShowConfigCommand.self, args: [])

        CommandTestHarness.cleanup(configFile)
    }

    func testGenDrawCommandTestMode() async throws {
        let outPath = CommandTestHarness.temporaryFile(ext: "png").path
        let cmd = try DrawCommand.parse(["test prompt", "--aspect-ratio", "1:1", "--image-size", "1K", "--output", outPath])
        try await cmd.run()
    }

    func testAnalyzeSimilarCommandJSON() async throws {
        let image1 = CommandTestHarness.fixture("small_100x100.png").path
        let image2 = CommandTestHarness.fixture("medium_512x512.jpg").path
        let cmd = try SimilarCommand.parse([image1, image2, "--format", "json"])
        try await cmd.run()
    }

    func testAnalyzeMetaCommandJSON() async throws {
        let image = CommandTestHarness.fixture("medium_512x512.jpg").path
        let tmp = CommandTestHarness.temporaryFile(ext: "jpg")
        let cmd = try MetaCommand.parse([image, "--format", "json", "--set-comment", "hello", "-o", tmp.path])
        try await cmd.run()
        CommandTestHarness.cleanup(tmp)
    }

    func testAnalyzeMetaCommandTableClearGps() async throws {
        let image = CommandTestHarness.fixture("medium_512x512.jpg").path
        let tmp = CommandTestHarness.temporaryFile(ext: "jpg")
        let cmd = try MetaCommand.parse([image, "--format", "table", "--clear-gps", "-o", tmp.path])
        try await cmd.run()
        CommandTestHarness.cleanup(tmp)
    }

    func testAnalyzeOCRCommandAccurateTableBounds() async throws {
        let image = CommandTestHarness.fixture("document_text_512x512.png").path
        let cmd = try OCRCommand.parse([image, "--level", "accurate", "--languages", "en", "--format", "text", "--show-bounds"])
        try await cmd.run()
    }

    func testAnalyzeOCRCommandTable() async throws {
        let image = CommandTestHarness.fixture("document_text_512x512.png").path
        let cmd = try OCRCommand.parse([image, "--format", "table"])
        try await cmd.run()
    }

    func testAnalyzeOCRCommandFast() async throws {
        let image = CommandTestHarness.fixture("document_text_512x512.png").path
        let cmd = try OCRCommand.parse([image, "--level", "fast", "--languages", "en", "--format", "json"])
        try await cmd.run()
    }

    func testAnalyzeScoreCommandFallbackOrRun() async throws {
        // macOS 14 会走 fallback 提示，macOS 15+ 会实际评分，两者都应不抛错
        let image = CommandTestHarness.fixture("medium_512x512.jpg").path
        let cmd = try ScoreCommand.parse([image, "--format", "json"])
        try await cmd.run()
    }

    // MARK: Edit

    func testEditResizeCommandCreatesOutput() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let outputURL = CommandTestHarness.temporaryFile(ext: "png")

        let cmd = try ResizeCommand.parse([
            input,
            "-o", outputURL.path,
            "--width", "64",
            "--height", "64",
            "--stretch",
            "--quality", "0.8",
            "--force"
        ])

        defer { CommandTestHarness.cleanup(outputURL) }

        try await cmd.run()

        // 验证输出文件存在且尺寸符合预期
        let imageIO = ServiceContainer.shared.imageIOService
        let info = try imageIO.getImageInfo(at: outputURL)
        XCTAssertEqual(info.width, 64)
        XCTAssertEqual(info.height, 64)
    }

    func testEditAdjustCommands() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path

        // Color
        let colorOut = CommandTestHarness.temporaryFile(ext: "png")
        let colorCmd = try ColorCommand.parse([input, "-o", colorOut.path, "--brightness", "0.1", "--force"])
        try await colorCmd.run()
        CommandTestHarness.cleanup(colorOut)

        // Exposure
        let exposureOut = CommandTestHarness.temporaryFile(ext: "png")
        let exposureCmd = try ExposureCommand.parse([input, "-o", exposureOut.path, "--ev", "0.5", "--force"])
        try await exposureCmd.run()
        CommandTestHarness.cleanup(exposureOut)

        // Invert
        let invertOut = CommandTestHarness.temporaryFile(ext: "png")
        let invertCmd = try InvertCommand.parse([input, "-o", invertOut.path, "--force"])
        try await invertCmd.run()
        CommandTestHarness.cleanup(invertOut)

        // Rotate
        let rotateOut = CommandTestHarness.temporaryFile(ext: "png")
        let rotateCmd = try RotateCommand.parse([input, "-o", rotateOut.path, "--angle", "45", "--force"])
        try await rotateCmd.run()
        CommandTestHarness.cleanup(rotateOut)

        // Threshold
        let thresholdOut = CommandTestHarness.temporaryFile(ext: "png")
        let thresholdCmd = try ThresholdCommand.parse([input, "-o", thresholdOut.path, "--threshold", "0.4", "--force"])
        try await thresholdCmd.run()
        CommandTestHarness.cleanup(thresholdOut)

        // Flip
        let flipOut = CommandTestHarness.temporaryFile(ext: "png")
        let flipCmd = try FlipCommand.parse([input, "-o", flipOut.path, "--horizontal", "--force"])
        try await flipCmd.run()
        CommandTestHarness.cleanup(flipOut)

        // Posterize
        let posterOut = CommandTestHarness.temporaryFile(ext: "png")
        let posterCmd = try PosterizeCommand.parse([input, "-o", posterOut.path, "--levels", "4", "--force"])
        try await posterCmd.run()
        CommandTestHarness.cleanup(posterOut)

        // Temperature
        let tempOut = CommandTestHarness.temporaryFile(ext: "png")
        let tempCmd = try TemperatureCommand.parse([input, "-o", tempOut.path, "--temp", "500", "--tint", "10", "--force"])
        try await tempCmd.run()
        CommandTestHarness.cleanup(tempOut)

        // Vignette
        let vignetteOut = CommandTestHarness.temporaryFile(ext: "png")
        let vignetteCmd = try VignetteCommand.parse([input, "-o", vignetteOut.path, "--intensity", "0.8", "--radius", "1.2", "--force"])
        try await vignetteCmd.run()
        CommandTestHarness.cleanup(vignetteOut)
    }

    func testFilterCommandsMinimal() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path

        try await runCommand(BlurCommand.self, args: [input, "-o", CommandTestHarness.temporaryFile(ext: "png").path, "--radius", "5", "--force"])
        try await runCommand(NoiseCommand.self, args: [input, "-o", CommandTestHarness.temporaryFile(ext: "png").path, "--force"])
        try await runCommand(PixelCommand.self, args: [input, "-o", CommandTestHarness.temporaryFile(ext: "png").path, "--force"])
        try await runCommand(SepiaCommand.self, args: [input, "-o", CommandTestHarness.temporaryFile(ext: "png").path, "--force"])
        try await runCommand(MonoCommand.self, args: [input, "-o", CommandTestHarness.temporaryFile(ext: "png").path, "--force"])
        try await runCommand(NoirCommand.self, args: [input, "-o", CommandTestHarness.temporaryFile(ext: "png").path, "--force"])
        try await runCommand(ChromeCommand.self, args: [input, "-o", CommandTestHarness.temporaryFile(ext: "png").path, "--force"])
        try await runCommand(ComicCommand.self, args: [input, "-o", CommandTestHarness.temporaryFile(ext: "png").path, "--force"])
        try await runCommand(HalftoneCommand.self, args: [input, "-o", CommandTestHarness.temporaryFile(ext: "png").path, "--force"])
        try await runCommand(InstantCommand.self, args: [input, "-o", CommandTestHarness.temporaryFile(ext: "png").path, "--force"])
        try await runCommand(SharpenCommand.self, args: [input, "-o", CommandTestHarness.temporaryFile(ext: "png").path, "--force"])
    }

    // MARK: Detect

    func testDetectFaceCommandFastAndFull() async throws {
        let faceImage = CommandTestHarness.fixture("face_512x512.png").path

        // fast 路径
        let fastCmd = try FaceCommand.parse([
            faceImage,
            "--fast",
            "--format", "table"
        ])
        try await fastCmd.run()

        // 全量 landmarks 路径 + threshold 分支
        let fullCmd = try FaceCommand.parse([
            faceImage,
            "--threshold", "0.1",
            "--format", "json"
        ])
        try await fullCmd.run()
    }

    func testDetectBarcodeAnimalHandPoseCommands() async throws {
        let qr = CommandTestHarness.fixture("qrcode_512x512.png").path
        let barcodeCmd = try BarcodeCommand.parse([qr, "--format", "json"])
        try await barcodeCmd.run()

        let cat = CommandTestHarness.fixture("cat_512x512.png").path
        let animalCmd = try AnimalCommand.parse([cat, "--format", "json"])
        try await animalCmd.run()

        let hand = CommandTestHarness.fixture("hand_512x512.png").path
        let handCmd = try HandCommand.parse([hand, "--format", "json", "--threshold", "0.0"])
        try await handCmd.run()

        let person = CommandTestHarness.fixture("foreground_person_indoor_512x512.jpg").path
        let poseCmd = try PoseCommand.parse([person, "--format", "json", "--threshold", "0.0"])
        try await poseCmd.run()
    }

    // MARK: Vision

    func testVisionSaliencyCommandJSON() async throws {
        let image = CommandTestHarness.fixture("medium_512x512.jpg").path
        let out = CommandTestHarness.temporaryFile(ext: "png").path
        let cmd = try SaliencyCommand.parse([image, "--type", "attention", "--format", "json", "--output", out])
        try await cmd.run()
    }

    func testVisionAlignFlowPersonsCommands() async throws {
        let img1 = CommandTestHarness.fixture("medium_512x512.jpg").path
        let img2 = CommandTestHarness.fixture("rectangle_512x512.png").path
        let out1 = CommandTestHarness.temporaryFile(ext: "png").path

        // Align (使用相同尺寸图像，json 输出)
        try await runCommand(AlignCommand.self, args: [img1, img2, "--format", "json", "-o", out1])

        // Optical flow（同尺寸，低精度，json 输出）
        let out2 = CommandTestHarness.temporaryFile(ext: "png").path
        try await runCommand(FlowCommand.self, args: [img1, img2, "--accuracy", "low", "--format", "json", "--output", out2])

        // Person segmentation
        let person = CommandTestHarness.fixture("foreground_person_indoor_512x512.jpg").path
        let out3 = CommandTestHarness.temporaryFile(ext: "png").path
        try await runCommand(PersonsCommand.self, args: [person, "--format", "table", "--quality", "accurate", "--output", out3])
    }

    func testDetectPetPoseAndPose3DCommands() async throws {
        let cat = CommandTestHarness.fixture("cat_512x512.png").path
        try await runCommand(PetPoseCommand.self, args: [cat, "--threshold", "0.0", "--format", "json"])

        let person = CommandTestHarness.fixture("foreground_person_indoor_512x512.jpg").path
        try await runCommand(Pose3DCommand.self, args: [person, "--threshold", "0.0", "--format", "json"])
    }

    func testEditDefringeCommand() async throws {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        try await runCommand(DefringeCommand.self, args: [input, "-o", CommandTestHarness.temporaryFile(ext: "png").path, "--force"])
    }

    func testEditAdvancedCommands() async throws {
        // 使用不同资产验证各高级编辑命令主路径
        let small = CommandTestHarness.fixture("small_100x100.png").path
        let doc = CommandTestHarness.fixture("document_1024x1024.png").path
        let line = CommandTestHarness.fixture("line_art_512x512.png").path
        let person = CommandTestHarness.fixture("foreground_person_beach_512x512.jpg").path
        let horizon = CommandTestHarness.fixture("horizon_clear_512x512.jpg").path

        // crop 50x50
        let out1 = CommandTestHarness.temporaryFile(ext: "png").path
        try await runCommand(CropCommand.self, args: [small, "-o", out1, "--width", "50", "--height", "50", "--force"])

        // cut background
        let out2 = CommandTestHarness.temporaryFile(ext: "png").path
        try await runCommand(CutCommand.self, args: [person, "-o", out2, "--force"])

        // enhance
        let out3 = CommandTestHarness.temporaryFile(ext: "png").path
        try await runCommand(EnhanceCommand.self, args: [small, "-o", out3, "--force"])

        // format convert to jpg
        let out4 = CommandTestHarness.temporaryFile(ext: "jpg").path
        try await runCommand(FormatCommand.self, args: [small, "-o", out4, "--format", "jpg", "--force"])

        // scan document
        let out5 = CommandTestHarness.temporaryFile(ext: "png").path
        try await runCommand(ScanCommand.self, args: [doc, "-o", out5, "--force"])

        // straighten horizon
        let out6 = CommandTestHarness.temporaryFile(ext: "png").path
        try await runCommand(StraightenCommand.self, args: [horizon, "-o", out6, "--force"])

        // thumbnail
        let out7 = CommandTestHarness.temporaryFile(ext: "png").path
        try await runCommand(ThumbCommand.self, args: [small, "-o", out7, "--size", "64", "--force"])

        // trace line art
        let out8 = CommandTestHarness.temporaryFile(ext: "png").path
        try await runCommand(TraceCommand.self, args: [line, "-o", out8, "--force"])
    }

    // MARK: Helpers

    private func runCommand<C: AsyncParsableCommand>(_ type: C.Type, args: [String]) async throws {
        // 反射调用 parse + run，便于批量覆盖命令
        // 强制输出文件清理以避免临时文件堆积
        let finalArgs = args
        var outputURL: URL?
        if let outputIndex = finalArgs.firstIndex(of: "-o").map({ $0 + 1 }) ?? finalArgs.firstIndex(of: "--output").map({ $0 + 1 }),
           outputIndex < finalArgs.count {
            outputURL = URL(fileURLWithPath: finalArgs[outputIndex])
        }

        var cmd = try type.parse(finalArgs)
        try await cmd.run()

        if let url = outputURL {
            CommandTestHarness.cleanup(url)
        }
    }
}
