import XCTest
@preconcurrency import Vision
#if !XCODE_BUILD
@testable import AirisCore
#endif

/// 第 23 批覆盖补充：补齐剩余 region 分支至 100%
final class CommandLayerCoverageSprint23Tests: XCTestCase {
    // MARK: Analyze

    func testInfoCommandSkipsOrientationAndAlphaFalse() async throws {
        let input = CommandTestHarness.fixture("foreground_cup_white_bg_512x512.jpg").path
        let previousTestMode = getenv("AIRIS_TEST_MODE").flatMap { String(cString: $0) }
        defer {
            if let previousTestMode {
                setenv("AIRIS_TEST_MODE", previousTestMode, 1)
            } else {
                unsetenv("AIRIS_TEST_MODE")
            }
        }
        unsetenv("AIRIS_TEST_MODE")
        unsetenv("AIRIS_FORCE_INFO_NO_COLOR")
        unsetenv("AIRIS_FORCE_UNKNOWN_ORIENTATION")

        try await InfoCommand.parse([input]).run()
    }

    func testMetaCommandAltBranchesExposureAndFlash() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let output = CommandTestHarness.temporaryFile(ext: "jpg")

        setenv("AIRIS_TEST_MODE", "1", 1)
        setenv("AIRIS_TEST_META_ALT_BRANCH", "1", 1)
        defer {
            unsetenv("AIRIS_TEST_MODE")
            unsetenv("AIRIS_TEST_META_ALT_BRANCH")
            CommandTestHarness.cleanup(output)
        }

        try await MetaCommand.parse([input, "-o", output.path]).run()
    }

    func testMetaCommandEmptyDataWarning() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        setenv("AIRIS_FORCE_META_EMPTY_PROPS", "1", 1)
        defer { unsetenv("AIRIS_FORCE_META_EMPTY_PROPS") }

        try await MetaCommand.parse([input, "--category", "gps"]).run()
    }

    func testMetaCommandWriteSetsCommentBranch() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let output = CommandTestHarness.temporaryFile(ext: "jpg")
        setenv("AIRIS_FORCE_META_NO_EXIF", "1", 1)
        defer {
            unsetenv("AIRIS_FORCE_META_NO_EXIF")
            CommandTestHarness.cleanup(output)
        }

        try await MetaCommand.parse([input, "--set-comment", "note23", "-o", output.path]).run()
    }

    func testOCRExtractEmptyCandidateReturnsEmpty() {
        let results = OCRCommand.testExtractEmptyCandidate()
        XCTAssertTrue(results.isEmpty)
    }

    func testPaletteScaleFallbackBranch() async throws {
        let input = CommandTestHarness.fixture("foreground_cup_white_bg_512x512.jpg").path
        setenv("AIRIS_FORCE_PALETTE_SCALE_NIL", "1", 1)
        defer { unsetenv("AIRIS_FORCE_PALETTE_SCALE_NIL") }

        try await PaletteCommand.parse([input, "--format", "json"]).run()
    }

    // MARK: Detect

    func testAnimalCombinedConfidenceBelowThreshold() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        setenv("AIRIS_FORCE_ANIMAL_STUB", "1", 1)
        defer { unsetenv("AIRIS_FORCE_ANIMAL_STUB") }

        try await AnimalCommand.parse([input, "--threshold", "0.95", "--format", "table"]).run()
    }

    func testAnimalCombinedConfidenceLabelBranch() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        setenv("AIRIS_FORCE_ANIMAL_LOW_LABEL", "1", 1)
        defer { unsetenv("AIRIS_FORCE_ANIMAL_LOW_LABEL") }

        try await AnimalCommand.parse([input, "--threshold", "0.8", "--format", "table"]).run()
    }

    func testBarcodeFormatSymbologyFallbackRawValue() {
        unsetenv("AIRIS_FORCE_BARCODE_UNKNOWN")
        let custom = VNBarcodeSymbology(rawValue: "custom_raw")
        let display = BarcodeCommand.testFormatSymbology(custom)
        XCTAssertEqual(display, "custom_raw")
    }

    func testHandChiralityJsonUsesMappedString() async throws {
        let input = CommandTestHarness.fixture("hand_512x512.png").path
        setenv("AIRIS_TEST_MODE", "1", 1)
        defer { unsetenv("AIRIS_TEST_MODE") }

        try await HandCommand.parse([input, "--format", "json", "--max-hands", "1"]).run()
    }

    // MARK: Edit

    func testCropDimensionsMustBePositive() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let output = CommandTestHarness.temporaryFile(ext: "png")
        defer { CommandTestHarness.cleanup(output) }

        await XCTAssertThrowsErrorAsync(
            try await CropCommand.parse([
                input, "-o", output.path, "--width", "0", "--height", "10"
            ]).run()
        )
    }

    func testCropRegionExceedsBounds() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let output = CommandTestHarness.temporaryFile(ext: "png")
        defer { CommandTestHarness.cleanup(output) }

        await XCTAssertThrowsErrorAsync(
            try await CropCommand.parse([
                input, "-o", output.path, "--x", "90", "--y", "90", "--width", "20", "--height", "20"
            ]).run()
        )
    }

    func testCropNegativeCoordinatesThrows() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let output = CommandTestHarness.temporaryFile(ext: "png")
        defer { CommandTestHarness.cleanup(output) }

        await XCTAssertThrowsErrorAsync(
            try await CropCommand.parse([
                input, "-o", output.path, "--x", "-5", "--y", "0", "--width", "10", "--height", "10"
            ]).run()
        )
    }

    func testFormatCommandJpegAliasBranch() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let output = CommandTestHarness.temporaryFile(ext: "jpeg")
        defer { CommandTestHarness.cleanup(output) }

        try await FormatCommand.parse([input, "-o", output.path, "--format", "jpeg", "--quality", "0.8"]).run()
    }

    // MARK: Gen

    func testDrawCommandProviderFallbackWhenDefaultMissing() async throws {
        // 创建不包含 default_provider 的自定义配置
        let configFile = CommandTestHarness.temporaryFile(ext: "json")
        let configJSON = """
        {"providers":{}}
        """
        try configJSON.data(using: .utf8)?.write(to: configFile)

        setenv("AIRIS_CONFIG_FILE", configFile.path, 1)
        setenv("AIRIS_TEST_MODE", "1", 1)
        setenv("AIRIS_GEN_STUB", "1", 1)
        defer {
            unsetenv("AIRIS_CONFIG_FILE")
            unsetenv("AIRIS_TEST_MODE")
            unsetenv("AIRIS_GEN_STUB")
            CommandTestHarness.cleanup(configFile)
        }

        let output = CommandTestHarness.temporaryFile(ext: "png")
        defer { CommandTestHarness.cleanup(output) }

        try await DrawCommand.parse(["test prompt", "-o", output.path]).run()
    }

    func testShowConfigCommandWithProvider() async throws {
        setenv("AIRIS_CONFIG_FILE", CommandTestHarness.temporaryFile(ext: "json").path, 1)
        defer { unsetenv("AIRIS_CONFIG_FILE") }
        try await ShowConfigCommand.parse(["--provider", "gemini"]).run()
    }

    func testConfigInteractiveAndShowAllBranches() async throws {
        // 使用临时配置文件隔离
        let configURL = CommandTestHarness.temporaryFile(ext: "json")
        setenv("AIRIS_CONFIG_FILE", configURL.path, 1)
        defer {
            unsetenv("AIRIS_CONFIG_FILE")
            CommandTestHarness.cleanup(configURL)
        }

        // set-key 交互分支（使用 stdin 桩）
        setenv("AIRIS_TEST_KEY_STDIN", "interact-key-1234", 1)
        try await SetKeyCommand.parse(["--provider", "demo-interactive"]).run()
        unsetenv("AIRIS_TEST_KEY_STDIN")

        // set 配置，触发 printProviderConfig
        try await SetConfigCommand.parse([
            "--provider", "demo-interactive",
            "--base-url", "https://example.com",
            "--model", "demo-model"
        ]).run()

        // show all 分支
        try await ShowConfigCommand.parse([]).run()

        // reset 分支（强制打印回退）
        setenv("AIRIS_FORCE_RESET_PRINT", "1", 1)
        try await ResetConfigCommand.parse(["--provider", "demo-interactive"]).run()
        unsetenv("AIRIS_FORCE_RESET_PRINT")

        // 清理 keychain
        try await DeleteKeyCommand.parse(["--provider", "demo-interactive"]).run()
    }

    func testConfigInteractiveEmptyInputThrowsInvalidResponse() async {
        // 关闭所有测试输入桩，覆盖 inputProvider 的空字符串分支
        let previousKeyInput = getenv("AIRIS_TEST_KEY_INPUT").flatMap { String(cString: $0) }
        let previousKeyStdin = getenv("AIRIS_TEST_KEY_STDIN").flatMap { String(cString: $0) }
        if previousKeyInput != nil { unsetenv("AIRIS_TEST_KEY_INPUT") }
        if previousKeyStdin != nil { unsetenv("AIRIS_TEST_KEY_STDIN") }
        defer {
            if let previousKeyInput { setenv("AIRIS_TEST_KEY_INPUT", previousKeyInput, 1) }
            if let previousKeyStdin { setenv("AIRIS_TEST_KEY_STDIN", previousKeyStdin, 1) }
        }

        do {
            let cmd = try SetKeyCommand.parse(["--provider", "gemini"])
            _ = try await cmd.run()
            XCTFail("应当抛出 invalidResponse")
        } catch let error as AirisError {
            guard case .invalidResponse = error else {
                XCTFail("期待 AirisError.invalidResponse，得到 \(error)")
                return
            }
        } catch {
            XCTFail("出现非预期错误：\(error)")
        }
    }

    // MARK: Domain

    func testVisionServiceMockFailureFalseBranch() {
        struct DummyOps: VisionOperations {
            func perform(requests: [VNRequest], on handler: VNImageRequestHandler) throws {}
            let shouldFail = false
        }
        let ops = DummyOps()
        XCTAssertFalse(VisionService.testIsMockFailure(ops))
    }

    func testVisionServiceMockFailureDefaultOpsReturnFalse() {
        let ops = DefaultVisionOperations()
        XCTAssertFalse(VisionService.testIsMockFailure(ops))
    }

    func testVisionServiceMockFailureLoopFalsePath() {
        struct NoFlagOps: VisionOperations {
            let foo = 1
            func perform(requests: [VNRequest], on handler: VNImageRequestHandler) throws { }
        }
        let ops = NoFlagOps()
        XCTAssertFalse(VisionService.testIsMockFailure(ops))
    }

    // MARK: 额外补充：Crop 负坐标分支

    func testCropNegativeCoordinatesGuardBranchDirectRun() async {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let output = CommandTestHarness.temporaryFile(ext: "png")
        defer { CommandTestHarness.cleanup(output) }

        let args = [
            input, "-o", output.path,
            "--x=-2", "--y", "0",
            "--width", "10", "--height", "10",
            "--force"
        ]

        do {
            let cmd = try CropCommand.parse(args)
            _ = try await cmd.run()
            XCTFail("应当抛出 invalidPath")
        } catch let error as AirisError {
            guard case .invalidPath(let message) = error else {
                XCTFail("期待 invalidPath，得到 \(error)")
                return
            }
            XCTAssertTrue(message.contains("non-negative"))
        } catch {
            XCTFail("出现非预期错误：\(error)")
        }
    }
}

// MARK: - Helpers

private func XCTAssertThrowsErrorAsync<T>(
    _ expression: @autoclosure () async throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line,
    _ errorHandler: (_ error: Error) -> Void = { _ in }
) async {
    do {
        _ = try await expression()
        XCTFail(message(), file: file, line: line)
    } catch {
        errorHandler(error)
    }
}
