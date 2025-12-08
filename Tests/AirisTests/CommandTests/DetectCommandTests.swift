import XCTest
@testable import Airis

final class DetectCommandTests: XCTestCase {

    // MARK: - DetectCommand Configuration Tests

    func testDetectCommandHasSubcommands() {
        XCTAssertEqual(DetectCommand.configuration.subcommands.count, 3)
        XCTAssertEqual(DetectCommand.configuration.commandName, "detect")
    }

    func testDetectCommandAbstract() {
        XCTAssertTrue(DetectCommand.configuration.abstract.contains("Detect"))
    }

    func testDetectCommandDiscussionContainsQuickStart() {
        let discussion = DetectCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("QUICK START"))
        XCTAssertTrue(discussion.contains("AVAILABLE DETECTORS"))
    }

    // MARK: - BarcodeCommand Configuration Tests

    func testBarcodeCommandConfiguration() {
        XCTAssertEqual(BarcodeCommand.configuration.commandName, "barcode")
        XCTAssertTrue(BarcodeCommand.configuration.abstract.contains("barcode"))
    }

    func testBarcodeCommandDiscussion() {
        let discussion = BarcodeCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("QUICK START"))
        XCTAssertTrue(discussion.contains("SUPPORTED BARCODE TYPES"))
        XCTAssertTrue(discussion.contains("EXAMPLES"))
        XCTAssertTrue(discussion.contains("QR"))
        XCTAssertTrue(discussion.contains("EAN-13"))
    }

    func testBarcodeCommandDiscussionContainsOptions() {
        let discussion = BarcodeCommand.configuration.discussion
        // OPTIONS section should list type and format options
        XCTAssertTrue(discussion.contains("--type"))
        XCTAssertTrue(discussion.contains("--format"))
    }

    // MARK: - FaceCommand Configuration Tests

    func testFaceCommandConfiguration() {
        XCTAssertEqual(FaceCommand.configuration.commandName, "face")
        XCTAssertTrue(FaceCommand.configuration.abstract.contains("face"))
    }

    func testFaceCommandDiscussion() {
        let discussion = FaceCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("QUICK START"))
        XCTAssertTrue(discussion.contains("DETECTION MODES"))
        XCTAssertTrue(discussion.contains("landmarks"))
    }

    func testFaceCommandDiscussionContainsOptions() {
        let discussion = FaceCommand.configuration.discussion
        // OPTIONS section should list fast, threshold, format options
        XCTAssertTrue(discussion.contains("--fast"))
        XCTAssertTrue(discussion.contains("--threshold"))
        XCTAssertTrue(discussion.contains("--format"))
    }

    // MARK: - AnimalCommand Configuration Tests

    func testAnimalCommandConfiguration() {
        XCTAssertEqual(AnimalCommand.configuration.commandName, "animal")
        XCTAssertTrue(AnimalCommand.configuration.abstract.contains("animal"))
    }

    func testAnimalCommandDiscussion() {
        let discussion = AnimalCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("QUICK START"))
        XCTAssertTrue(discussion.contains("SUPPORTED ANIMALS"))
        XCTAssertTrue(discussion.contains("Cat"))
        XCTAssertTrue(discussion.contains("Dog"))
    }

    func testAnimalCommandDiscussionContainsOptions() {
        let discussion = AnimalCommand.configuration.discussion
        // OPTIONS section should list type, threshold, format options
        XCTAssertTrue(discussion.contains("--type"))
        XCTAssertTrue(discussion.contains("--threshold"))
        XCTAssertTrue(discussion.contains("--format"))
    }

    // MARK: - VisionService Integration Tests

    func testVisionServiceExists() {
        let service = ServiceContainer.shared.visionService
        XCTAssertNotNil(service)
    }

    func testVisionServiceCanBeCreated() {
        let service = VisionService()
        XCTAssertNotNil(service)
    }

    // MARK: - FileUtils Tests for Detect Commands

    func testValidateImageFileThrowsForNonexistent() {
        XCTAssertThrowsError(try FileUtils.validateImageFile(at: "/nonexistent/file.jpg")) { error in
            if case AirisError.fileNotFound = error {
                // Expected
            } else {
                XCTFail("Expected fileNotFound error")
            }
        }
    }

    func testValidateImageFileThrowsForUnsupportedFormat() {
        // 创建临时文件
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("test.txt")
        try? "test content".write(to: tempFile, atomically: true, encoding: .utf8)

        defer {
            try? FileManager.default.removeItem(at: tempFile)
        }

        XCTAssertThrowsError(try FileUtils.validateImageFile(at: tempFile.path)) { error in
            if case AirisError.unsupportedFormat = error {
                // Expected
            } else {
                XCTFail("Expected unsupportedFormat error")
            }
        }
    }

    // MARK: - Default Values Tests
    // Note: Default values are tested through configuration, not instance creation,
    // because @Argument and @Option properties require parsing to be initialized.

    func testBarcodeCommandFormatDefaultInConfiguration() {
        // Default format is "table" - verified through discussion text
        let discussion = BarcodeCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("table (default)"))
    }

    func testFaceCommandDefaultsInConfiguration() {
        let discussion = FaceCommand.configuration.discussion
        // Default format is table
        XCTAssertTrue(discussion.contains("table (default)"))
        // Default threshold is 0.0
        XCTAssertTrue(discussion.contains("0.0-1.0"))
    }

    func testAnimalCommandDefaultsInConfiguration() {
        let discussion = AnimalCommand.configuration.discussion
        // Default format is table
        XCTAssertTrue(discussion.contains("table (default)"))
        // Default threshold is 0.0
        XCTAssertTrue(discussion.contains("0.0-1.0"))
    }
}
