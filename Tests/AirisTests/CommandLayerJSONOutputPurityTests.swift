import XCTest
#if !XCODE_BUILD
    @testable import AirisCore
#endif
import Darwin
import Foundation

final class CommandLayerJSONOutputPurityTests: XCTestCase {
    private var originalAllowStdout: String?
    private var originalTagStub: String?
    private var originalTestMode: String?

    override func setUp() {
        super.setUp()
        originalAllowStdout = getenv("AIRIS_TEST_ALLOW_STDOUT").flatMap { String(cString: $0) }
        originalTagStub = getenv("AIRIS_FORCE_TAG_STUB").flatMap { String(cString: $0) }
        originalTestMode = getenv("AIRIS_TEST_MODE").flatMap { String(cString: $0) }
    }

    override func tearDown() {
        if let originalAllowStdout {
            setenv("AIRIS_TEST_ALLOW_STDOUT", originalAllowStdout, 1)
        } else {
            unsetenv("AIRIS_TEST_ALLOW_STDOUT")
        }
        if let originalTagStub {
            setenv("AIRIS_FORCE_TAG_STUB", originalTagStub, 1)
        } else {
            unsetenv("AIRIS_FORCE_TAG_STUB")
        }
        if let originalTestMode {
            setenv("AIRIS_TEST_MODE", originalTestMode, 1)
        } else {
            unsetenv("AIRIS_TEST_MODE")
        }
        super.tearDown()
    }

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

    private func withCapturedStdoutAsync(_ work: () async throws -> Void) async rethrows -> String {
        fflush(stdout)

        let originalStdout = dup(STDOUT_FILENO)
        let pipe = Pipe()
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)

        try await work()

        fflush(stdout)
        pipe.fileHandleForWriting.closeFile()
        dup2(originalStdout, STDOUT_FILENO)
        close(originalStdout)

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }

    private func assertPureJSON(_ output: String, disallowContains disallowed: [String] = ["━━━━━━━━"]) throws {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertFalse(trimmed.isEmpty)
        XCTAssertTrue(trimmed.hasPrefix("{") || trimmed.hasPrefix("["))
        for token in disallowed {
            XCTAssertFalse(trimmed.contains(token))
        }

        let data = try XCTUnwrap(trimmed.data(using: .utf8))
        _ = try JSONSerialization.jsonObject(with: data, options: [])
    }

    func testInfoCommandJSONOutputIsPureJSON() async throws {
        let img = CommandTestHarness.fixture("small_100x100.png").path
        var output = ""
        try await withEnv(["AIRIS_TEST_ALLOW_STDOUT": "1"]) {
            output = try await withCapturedStdoutAsync {
                let cmd = try InfoCommand.parse([img, "--format", "json"])
                try await cmd.run()
            }
        }

        try assertPureJSON(output)
    }

    func testTagCommandJSONOutputIsPureJSON() async throws {
        let img = CommandTestHarness.fixture("medium_512x512.jpg").path
        var output = ""
        try await withEnv([
            "AIRIS_TEST_ALLOW_STDOUT": "1",
            "AIRIS_FORCE_TAG_STUB": "1",
        ]) {
            output = try await withCapturedStdoutAsync {
                let cmd = try TagCommand.parse([img, "--threshold", "0.0", "--limit", "10", "--format", "json"])
                try await cmd.run()
            }
        }

        try assertPureJSON(output, disallowContains: ["━━━━━━━━", "🏷️"])
    }

    func testMetaCommandJSONOutputIsPureJSON() async throws {
        let img = CommandTestHarness.fixture("small_100x100_meta.png").path
        var output = ""
        try await withEnv(["AIRIS_TEST_ALLOW_STDOUT": "1"]) {
            output = try await withCapturedStdoutAsync {
                let cmd = try MetaCommand.parse([img, "--format", "json"])
                try await cmd.run()
            }
        }

        try assertPureJSON(output)
    }

    func testOCRCommandJSONOutputIsPureJSON() async throws {
        let img = CommandTestHarness.fixture("document_text_512x512.png").path
        var output = ""
        try await withEnv([
            "AIRIS_TEST_ALLOW_STDOUT": "1",
            "AIRIS_FORCE_OCR_FAKE": "1",
        ]) {
            output = try await withCapturedStdoutAsync {
                let cmd = try OCRCommand.parse([img, "--format", "json", "--show-bounds"])
                try await cmd.run()
            }
        }

        try assertPureJSON(output, disallowContains: ["━━━━━━━━", "📝"])
    }

    func testPaletteCommandJSONOutputIsPureJSON() async throws {
        let img = CommandTestHarness.fixture("medium_512x512.jpg").path
        var output = ""
        try await withEnv(["AIRIS_TEST_ALLOW_STDOUT": "1"]) {
            output = try await withCapturedStdoutAsync {
                let cmd = try PaletteCommand.parse([img, "--format", "json", "--count", "3"])
                try await cmd.run()
            }
        }

        try assertPureJSON(output)
    }

    func testSafeCommandJSONOutputIsPureJSON() async throws {
        let img = CommandTestHarness.fixture("medium_512x512.jpg").path
        var output = ""
        try await withEnv([
            "AIRIS_TEST_ALLOW_STDOUT": "1",
            "AIRIS_TEST_MODE": "1",
        ]) {
            output = try await withCapturedStdoutAsync {
                let cmd = try SafeCommand.parse([img, "--format", "json"])
                try await cmd.run()
            }
        }

        try assertPureJSON(output)
    }

    func testScoreCommandJSONOutputIsPureJSON() async throws {
        let img = CommandTestHarness.fixture("small_100x100.png").path
        var output = ""
        try await withEnv([
            "AIRIS_TEST_ALLOW_STDOUT": "1",
            "AIRIS_TEST_MODE": "1",
            "AIRIS_SCORE_TEST_VALUE": "0.62",
            "AIRIS_SCORE_UTILITY_FALSE": "1",
        ]) {
            output = try await withCapturedStdoutAsync {
                let cmd = try ScoreCommand.parse([img, "--format", "json"])
                try await cmd.run()
            }
        }

        try assertPureJSON(output)
    }

    func testSimilarCommandJSONOutputIsPureJSON() async throws {
        let img1 = CommandTestHarness.fixture("small_100x100.png").path
        let img2 = CommandTestHarness.fixture("medium_512x512.jpg").path
        var output = ""
        try await withEnv([
            "AIRIS_TEST_ALLOW_STDOUT": "1",
            "AIRIS_TEST_MODE": "1",
            "AIRIS_SIMILAR_TEST_DISTANCE": "0.55",
        ]) {
            output = try await withCapturedStdoutAsync {
                let cmd = try SimilarCommand.parse([img1, img2, "--format", "json"])
                try await cmd.run()
            }
        }

        try assertPureJSON(output)
    }

    func testAnimalCommandJSONOutputIsPureJSON() async throws {
        let img = CommandTestHarness.fixture("small_100x100.png").path
        var output = ""
        try await withEnv([
            "AIRIS_TEST_ALLOW_STDOUT": "1",
            "AIRIS_FORCE_ANIMAL_STUB": "1",
        ]) {
            output = try await withCapturedStdoutAsync {
                let cmd = try AnimalCommand.parse([img, "--format", "json"])
                try await cmd.run()
            }
        }

        try assertPureJSON(output)
    }

    func testBarcodeCommandJSONOutputIsPureJSON() async throws {
        let img = CommandTestHarness.fixture("qrcode_512x512.png").path
        var output = ""
        try await withEnv(["AIRIS_TEST_ALLOW_STDOUT": "1"]) {
            output = try await withCapturedStdoutAsync {
                let cmd = try BarcodeCommand.parse([img, "--type", "qr", "--format", "json"])
                try await cmd.run()
            }
        }

        try assertPureJSON(output)
    }

    func testFaceCommandJSONOutputIsPureJSON() async throws {
        let img = CommandTestHarness.fixture("face_512x512.png").path
        var output = ""
        try await withEnv(["AIRIS_TEST_ALLOW_STDOUT": "1"]) {
            output = try await withCapturedStdoutAsync {
                let cmd = try FaceCommand.parse([img, "--fast", "--format", "json", "--threshold", "0.0"])
                try await cmd.run()
            }
        }

        try assertPureJSON(output)
    }

    func testHandCommandJSONOutputIsPureJSON() async throws {
        let img = CommandTestHarness.fixture("hand_512x512.png").path
        var output = ""
        try await withEnv(["AIRIS_TEST_ALLOW_STDOUT": "1"]) {
            output = try await withCapturedStdoutAsync {
                let cmd = try HandCommand.parse([img, "--format", "json", "--threshold", "0.0", "--max-hands", "1"])
                try await cmd.run()
            }
        }

        try assertPureJSON(output)
    }

    func testPetPoseCommandJSONOutputIsPureJSON() async throws {
        let img = CommandTestHarness.fixture("cat_512x512.png").path
        var output = ""
        try await withEnv([
            "AIRIS_TEST_ALLOW_STDOUT": "1",
            "AIRIS_FORCE_PETPOSE_UNSUPPORTED": "1",
        ]) {
            output = try await withCapturedStdoutAsync {
                let cmd = try PetPoseCommand.parse([img, "--format", "json"])
                try await cmd.run()
            }
        }

        try assertPureJSON(output)
    }

    func testPoseCommandJSONOutputIsPureJSON() async throws {
        let img = CommandTestHarness.fixture("rectangle_512x512.png").path
        var output = ""
        try await withEnv(["AIRIS_TEST_ALLOW_STDOUT": "1"]) {
            output = try await withCapturedStdoutAsync {
                let cmd = try PoseCommand.parse([img, "--format", "json"])
                try await cmd.run()
            }
        }

        try assertPureJSON(output)
    }

    func testPose3DCommandJSONOutputIsPureJSON() async throws {
        let img = CommandTestHarness.fixture("foreground_person_indoor_512x512.jpg").path
        var output = ""
        try await withEnv([
            "AIRIS_TEST_ALLOW_STDOUT": "1",
            "AIRIS_FORCE_POSE3D_EMPTY": "1",
        ]) {
            output = try await withCapturedStdoutAsync {
                let cmd = try Pose3DCommand.parse([img, "--format", "json"])
                try await cmd.run()
            }
        }

        try assertPureJSON(output)
    }

    func testAlignCommandJSONOutputIsPureJSON() async throws {
        let img1 = CommandTestHarness.fixture("medium_512x512.jpg").path
        let img2 = CommandTestHarness.fixture("rectangle_512x512.png").path
        var output = ""
        try await withEnv([
            "AIRIS_TEST_ALLOW_STDOUT": "1",
            "AIRIS_TEST_ALIGN_FAKE_RESULT": "1",
        ]) {
            output = try await withCapturedStdoutAsync {
                let cmd = try AlignCommand.parse([img1, img2, "--format", "json"])
                try await cmd.run()
            }
        }

        try assertPureJSON(output)
    }

    func testFlowCommandJSONOutputIsPureJSON() async throws {
        let img1 = CommandTestHarness.fixture("medium_512x512.jpg").path
        let img2 = CommandTestHarness.fixture("rectangle_512x512.png").path
        var output = ""
        try await withEnv([
            "AIRIS_TEST_ALLOW_STDOUT": "1",
            "AIRIS_TEST_FLOW_FAKE_RESULT": "1",
        ]) {
            output = try await withCapturedStdoutAsync {
                let cmd = try FlowCommand.parse([img1, img2, "--format", "json"])
                try await cmd.run()
            }
        }

        try assertPureJSON(output)
    }

    func testPersonsCommandJSONOutputIsPureJSON() async throws {
        let img = CommandTestHarness.fixture("foreground_person_indoor_512x512.jpg").path
        var output = ""
        try await withEnv([
            "AIRIS_TEST_ALLOW_STDOUT": "1",
            "AIRIS_TEST_PERSONS_FAKE_RESULT": "1",
        ]) {
            output = try await withCapturedStdoutAsync {
                let cmd = try PersonsCommand.parse([img, "--format", "json"])
                try await cmd.run()
            }
        }

        try assertPureJSON(output)
    }

    func testSaliencyCommandJSONOutputIsPureJSON() async throws {
        let img = CommandTestHarness.fixture("foreground_cup_white_bg_512x512.jpg").path
        var output = ""
        try await withEnv([
            "AIRIS_TEST_ALLOW_STDOUT": "1",
            "AIRIS_TEST_SALIENCY_FAKE_RESULT": "1",
        ]) {
            output = try await withCapturedStdoutAsync {
                let cmd = try SaliencyCommand.parse([img, "--format", "json"])
                try await cmd.run()
            }
        }

        try assertPureJSON(output)
    }
}
