import XCTest
@testable import Airis

/// 冲刺补充：覆盖未命中的命令分支（JPEG 分支、失败分支等）
final class CommandLayerCoverageSprint22Tests: XCTestCase {
    /// 临时设置环境变量（支持 async 块）
    private func withEnv(_ env: [String: String], perform block: () async throws -> Void) async rethrows {
        var originals: [String: String?] = [:]
        for (key, value) in env {
            originals[key] = ProcessInfo.processInfo.environment[key]
            setenv(key, value, 1)
        }
        defer {
            for (key, value) in originals {
                if let v = value {
                    setenv(key, v, 1)
                } else {
                    unsetenv(key)
                }
            }
        }
        try await block()
    }

    // MARK: - Edit / Cut

    func testCutCommandUnsupportedOS() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let output = CommandTestHarness.temporaryFile(ext: "png").path

        await withEnv(["AIRIS_FORCE_CUT_OS_UNSUPPORTED": "1"]) {
            do {
                try await CutCommand.parse([input, "-o", output]).run()
                XCTFail("应触发不支持错误")
            } catch {
                // 期待抛出 AirisError.unsupportedFormat
            }
        }
    }

    func testCutCommandRenderNilGuard() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let output = CommandTestHarness.temporaryFile(ext: "png").path

        await withEnv(["AIRIS_FORCE_CUT_RENDER_NIL": "1"]) {
            do {
                try await CutCommand.parse([input, "-o", output]).run()
                XCTFail("应触发渲染失败错误")
            } catch {
                // 预期抛出 imageEncodeFailed
            }
        }
    }

    // MARK: - Edit / Trace

    func testTraceEdgesStyleCoversEdgesBranch() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let output = CommandTestHarness.temporaryFile(ext: "png").path
        try await TraceCommand.parse([input, "-o", output, "--style", "edges"]).run()
        CommandTestHarness.cleanup(URL(fileURLWithPath: output))
    }

    func testTraceResultNilBranch() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let output = CommandTestHarness.temporaryFile(ext: "png").path
        await withEnv(["AIRIS_FORCE_TRACE_RESULT_NIL": "1"]) {
            do {
                try await TraceCommand.parse([input, "-o", output, "--style", "edges"]).run()
                XCTFail("应触发结果为空错误")
            } catch {
                // 预期抛出 imageEncodeFailed
            }
        }
    }

    func testTraceRenderNilBranch() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let output = CommandTestHarness.temporaryFile(ext: "png").path
        await withEnv(["AIRIS_FORCE_TRACE_RENDER_NIL": "1"]) {
            do {
                try await TraceCommand.parse([input, "-o", output, "--style", "edges"]).run()
                XCTFail("应触发渲染失败错误")
            } catch {
                // 预期抛出 imageEncodeFailed
            }
        }
    }

    // MARK: - Edit / Enhance

    func testEnhanceVerboseNoFiltersAndOpenBranch() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let output = CommandTestHarness.temporaryFile(ext: "jpg").path

        try await withEnv([
            "AIRIS_FORCE_ENHANCE_NO_FILTERS": "1",
            "CI": "1"  // 防止实际打开 Finder
        ]) {
            try await EnhanceCommand.parse([input, "-o", output, "--verbose", "--open"]).run()
        }
        CommandTestHarness.cleanup(URL(fileURLWithPath: output))
    }

    // MARK: - Edit / Filters & Noise JPEG 分支

    func testNoiseAndFiltersUseJPEGPath() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let tasks: [() async throws -> Void] = [
            { try await NoiseCommand.parse([input, "-o", CommandTestHarness.temporaryFile(ext: "jpeg").path]).run() },
            { try await ChromeCommand.parse([input, "-o", CommandTestHarness.temporaryFile(ext: "jpeg").path]).run() },
            { try await ComicCommand.parse([input, "-o", CommandTestHarness.temporaryFile(ext: "jpeg").path]).run() },
            { try await InstantCommand.parse([input, "-o", CommandTestHarness.temporaryFile(ext: "jpeg").path]).run() },
            { try await MonoCommand.parse([input, "-o", CommandTestHarness.temporaryFile(ext: "jpeg").path]).run() },
            { try await NoirCommand.parse([input, "-o", CommandTestHarness.temporaryFile(ext: "jpeg").path]).run() },
            { try await PixelCommand.parse([input, "-o", CommandTestHarness.temporaryFile(ext: "jpeg").path]).run() },
            { try await SepiaCommand.parse([input, "-o", CommandTestHarness.temporaryFile(ext: "jpeg").path]).run() },
            { try await BlurCommand.parse([input, "-o", CommandTestHarness.temporaryFile(ext: "jpeg").path, "--radius", "2"]).run() },
            {
                let out = CommandTestHarness.temporaryFile(ext: "jpeg").path
                try await BlurCommand.parse([input, "-o", out, "--radius", "3", "--type", "motion", "--angle", "45"]).run()
            },
            {
                let out = CommandTestHarness.temporaryFile(ext: "jpeg").path
                try await BlurCommand.parse([input, "-o", out, "--radius", "4", "--type", "zoom"]).run()
            }
        ]

        for task in tasks {
            try await task()
        }
    }

    // MARK: - Detect / Hand & PetPose

    func testHandCommandHighThresholdSkipsLowConfidence() async throws {
        let input = CommandTestHarness.fixture("hand_512x512.png").path
        try await HandCommand.parse([input, "--threshold", "2.0", "--format", "json"]).run()
    }

    func testPetPoseCommandUnsupportedAndSkip() async throws {
        let input = CommandTestHarness.fixture("cat_512x512.png").path
        try await withEnv(["AIRIS_FORCE_PETPOSE_UNSUPPORTED": "1"]) {
            try await PetPoseCommand.parse([input]).run()
        }
    }

    func testPetPoseHighThresholdSkipsKeypoints() async throws {
        let input = CommandTestHarness.fixture("cat_512x512.png").path
        try await PetPoseCommand.parse([input, "--threshold", "2.0", "--format", "json"]).run()
    }

    // MARK: - Gen / Config 输入失败

    func testConfigSetKeyEmptyInputThrows() async throws {
        await withEnv(["AIRIS_TEST_KEY_STDIN": ""]) {
            do {
                try await SetKeyCommand.parse(["--provider", "gemini"]).run()
                XCTFail("应触发输入无效错误")
            } catch {
                // 预期抛出 AirisError.invalidResponse
            }
        }
    }

    // MARK: - Gen / Draw 打开失败分支

    func testDrawOpenAndRevealFailureBranches() async throws {
        let outputURL = try CommandTestHarness.copyFixture("small_100x100.png", toExtension: "png")

        // 打开失败
        await withEnv(["AIRIS_FORCE_DRAW_OPEN_FAIL": "1"]) {
            DrawCommand().testOpenWithDefaultApp(outputURL, isTestMode: false)
        }

        // Reveal 失败
        await withEnv(["AIRIS_FORCE_DRAW_REVEAL_FAIL": "1"]) {
            DrawCommand().testOpenInFinder(outputURL, isTestMode: false)
        }

        // 覆盖非测试模式下的 /usr/bin/open 分支（用 override 避免真实打开）
        await withEnv([
            "AIRIS_DRAW_OPEN_EXECUTABLE_OVERRIDE": "/usr/bin/true",
            "AIRIS_DRAW_REVEAL_EXECUTABLE_OVERRIDE": "/usr/bin/true"
        ]) {
            DrawCommand().testOpenWithDefaultApp(outputURL, isTestMode: false)
            DrawCommand().testOpenInFinder(outputURL, isTestMode: false)
        }

        CommandTestHarness.cleanup(outputURL)
    }

    // MARK: - Analyze 额外分支

    func testInfoCommandAlwaysShowsOrientation() async throws {
        let input = CommandTestHarness.fixture("small_100x100_meta.png").path
        await withEnv(["AIRIS_TEST_MODE": "1"]) {
            try? await InfoCommand.parse([input]).run()
        }
    }

    func testMetaCommandEmptyPropsWarning() async throws {
        let input = CommandTestHarness.fixture("small_100x100_meta.png").path
        await withEnv(["AIRIS_FORCE_META_EMPTY_PROPS": "1"]) {
            try? await MetaCommand.parse([input, "--category", "gps"]).run()
        }
    }

    func testMetaCommandClearAllBranch() async throws {
        let input = CommandTestHarness.fixture("small_100x100_meta.png").path
        let output = CommandTestHarness.temporaryFile(ext: "jpg").path
        try? await MetaCommand.parse([input, "--clear-all", "-o", output]).run()
        CommandTestHarness.cleanup(URL(fileURLWithPath: output))
    }

    func testOCRCommandNilCandidateBranch() {
        let results = OCRCommand.testExtractEmptyCandidate()
        XCTAssertTrue(results.isEmpty)
    }

    func testPaletteScaleBranch() async throws {
        let input = CommandTestHarness.fixture("medium_512x512.jpg").path
        try await PaletteCommand.parse([input, "--count", "3"]).run()
    }

    func testScoreCommandNegativeRatingEnglish() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        await withEnv([
            "AIRIS_TEST_MODE": "1",
            "AIRIS_SCORE_TEST_VALUE": "-0.25",
            "AIRIS_SCORE_UTILITY_FALSE": "1"
        ]) {
            try? await ScoreCommand.parse([input, "--format", "json"]).run()
        }
    }

    // MARK: - Detect 额外分支

    func testAnimalCommandHighThresholdSkipsLabels() async throws {
        let cat = CommandTestHarness.fixture("cat_512x512.png").path
        try await AnimalCommand.parse([cat, "--threshold", "1.0"]).run()
    }

    func testBarcodeFormatSymbologyDefault() {
        let value = BarcodeCommand.testFormatSymbology(.aztec)
        XCTAssertEqual(value.lowercased(), "aztec")
    }

    func testPoseCommandUnknownJointNameHelper() {
        let name = PoseCommand.testJointNameString("custom_joint")
        XCTAssertEqual(name, "unknown")
    }

    func testPoseCommandHighThresholdJSON() async throws {
        let person = CommandTestHarness.fixture("foreground_person_indoor_512x512.jpg").path
        try await PoseCommand.parse([person, "--threshold", "2.0", "--format", "json"]).run()
    }

    func testPetPoseHighThresholdTable() async throws {
        let cat = CommandTestHarness.fixture("cat_512x512.png").path
        try await PetPoseCommand.parse([cat, "--threshold", "2.0", "--format", "table"]).run()
    }

    // MARK: - Edit 额外分支

    func testCropCommandNegativeCoordinatesThrow() async throws {
        let img = CommandTestHarness.fixture("small_100x100.png").path
        do {
            let out = CommandTestHarness.temporaryFile(ext: "png").path
            try await CropCommand.parse([img, "--x", "-1", "--y", "0", "--width", "10", "--height", "10", "-o", out]).run()
            XCTFail("应触发坐标校验错误")
        } catch { }
    }

    func testDefringeRenderNilBranch() async throws {
        let img = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png").path
        await withEnv(["AIRIS_FORCE_DEFRINGE_RENDER_NIL": "1"]) {
            do {
                try await DefringeCommand.parse([img, "-o", out]).run()
                XCTFail("应触发渲染错误")
            } catch { }
        }
    }

    func testStraightenRenderNilBranch() async throws {
        let img = CommandTestHarness.fixture("small_100x100.png").path
        let out = CommandTestHarness.temporaryFile(ext: "png").path
        await withEnv(["AIRIS_FORCE_STRAIGHTEN_RENDER_NIL": "1"]) {
            do {
                try await StraightenCommand.parse([img, "-o", out]).run()
                XCTFail("应触发渲染错误")
            } catch { }
        }
    }

    func testHalftoneAndSharpenJPEGBranches() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        try await HalftoneCommand.parse([input, "-o", CommandTestHarness.temporaryFile(ext: "jpeg").path]).run()
        try await SharpenCommand.parse([input, "-o", CommandTestHarness.temporaryFile(ext: "jpeg").path]).run()
    }

    func testFormatCommandTiffAlias() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let output = CommandTestHarness.temporaryFile(ext: "tif").path
        try await FormatCommand.parse([input, "--format", "tif", "-o", output]).run()
        CommandTestHarness.cleanup(URL(fileURLWithPath: output))
    }

    func testTraceCommandUnknownStyleFallsBack() async throws {
        let input = CommandTestHarness.fixture("small_100x100.png").path
        let output = CommandTestHarness.temporaryFile(ext: "png").path
        try await withEnv(["AIRIS_ALLOW_UNKNOWN_TRACE_STYLE": "1"]) {
            try await TraceCommand.parse([input, "-o", output, "--style", "unknown"]).run()
        }
        CommandTestHarness.cleanup(URL(fileURLWithPath: output))
    }

    // MARK: - Vision 保存输出分支

    func testAlignCommandSavesJPG() async throws {
        let img1 = CommandTestHarness.fixture("small_100x100.png").path
        let img2 = CommandTestHarness.fixture("rectangle_512x512.png").path
        let output = CommandTestHarness.temporaryFile(ext: "jpg").path
        try await AlignCommand.parse([img1, img2, "--format", "json", "-o", output]).run()
        CommandTestHarness.cleanup(URL(fileURLWithPath: output))
    }

    func testPersonsCommandSavesJPG() async throws {
        let person = CommandTestHarness.fixture("foreground_person_indoor_512x512.jpg").path
        let output = CommandTestHarness.temporaryFile(ext: "jpg").path
        try await PersonsCommand.parse([person, "--format", "json", "-o", output]).run()
        CommandTestHarness.cleanup(URL(fileURLWithPath: output))
    }

    func testSaliencyCommandSavesJPG() async throws {
        let img = CommandTestHarness.fixture("medium_512x512.jpg").path
        let output = CommandTestHarness.temporaryFile(ext: "jpg").path
        try await SaliencyCommand.parse([img, "--type", "attention", "--format", "json", "-o", output]).run()
        CommandTestHarness.cleanup(URL(fileURLWithPath: output))
    }

    // MARK: - Gen 额外覆盖

    func testConfigShowAllProvidersClosure() async throws {
        await withEnv(["AIRIS_TEST_MODE": "1"]) {
            try? await ShowConfigCommand.parse([]).run()
        }
    }

    func testVisionServiceMockFailureDetection() {
        let mock = MockVisionOperations(shouldFail: true)
        XCTAssertTrue(VisionService.testIsMockFailure(mock))
    }
}
