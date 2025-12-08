import XCTest
@testable import Airis

final class VisionCommandTests: XCTestCase {

    // MARK: - VisionCommand Configuration Tests

    func testVisionCommandHasSubcommands() {
        XCTAssertEqual(VisionCommand.configuration.subcommands.count, 4)
        XCTAssertEqual(VisionCommand.configuration.commandName, "vision")
    }

    func testVisionCommandAbstract() {
        XCTAssertTrue(VisionCommand.configuration.abstract.contains("vision"))
    }

    func testVisionCommandDiscussionContainsQuickStart() {
        let discussion = VisionCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("QUICK START"))
        XCTAssertTrue(discussion.contains("SUBCOMMANDS"))
    }

    // MARK: - FlowCommand Configuration Tests

    func testFlowCommandConfiguration() {
        XCTAssertEqual(FlowCommand.configuration.commandName, "flow")
        XCTAssertTrue(FlowCommand.configuration.abstract.contains("optical flow"))
    }

    func testFlowCommandDiscussion() {
        let discussion = FlowCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("QUICK START"))
        XCTAssertTrue(discussion.contains("ACCURACY LEVELS"))
        XCTAssertTrue(discussion.contains("EXAMPLES"))
        XCTAssertTrue(discussion.contains("low"))
        XCTAssertTrue(discussion.contains("medium"))
        XCTAssertTrue(discussion.contains("high"))
        XCTAssertTrue(discussion.contains("veryHigh"))
    }

    func testFlowCommandDiscussionContainsOptions() {
        let discussion = FlowCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("--accuracy"))
        XCTAssertTrue(discussion.contains("--format"))
    }

    // MARK: - AlignCommand Configuration Tests

    func testAlignCommandConfiguration() {
        XCTAssertEqual(AlignCommand.configuration.commandName, "align")
        XCTAssertTrue(AlignCommand.configuration.abstract.contains("alignment") ||
                     AlignCommand.configuration.abstract.contains("registration"))
    }

    func testAlignCommandDiscussion() {
        let discussion = AlignCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("QUICK START"))
        XCTAssertTrue(discussion.contains("EXAMPLES"))
        XCTAssertTrue(discussion.contains("reference"))
        XCTAssertTrue(discussion.contains("floating"))
    }

    func testAlignCommandDiscussionContainsOptions() {
        let discussion = AlignCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("--format"))
    }

    // MARK: - SaliencyCommand Configuration Tests

    func testSaliencyCommandConfiguration() {
        XCTAssertEqual(SaliencyCommand.configuration.commandName, "saliency")
        XCTAssertTrue(SaliencyCommand.configuration.abstract.contains("saliency") ||
                     SaliencyCommand.configuration.abstract.contains("attention"))
    }

    func testSaliencyCommandDiscussion() {
        let discussion = SaliencyCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("QUICK START"))
        XCTAssertTrue(discussion.contains("SALIENCY TYPES"))
        XCTAssertTrue(discussion.contains("EXAMPLES"))
        XCTAssertTrue(discussion.contains("attention"))
        XCTAssertTrue(discussion.contains("objectness"))
    }

    func testSaliencyCommandDiscussionContainsOptions() {
        let discussion = SaliencyCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("--type"))
        XCTAssertTrue(discussion.contains("--format"))
    }

    // MARK: - PersonsCommand Configuration Tests

    func testPersonsCommandConfiguration() {
        XCTAssertEqual(PersonsCommand.configuration.commandName, "persons")
        XCTAssertTrue(PersonsCommand.configuration.abstract.contains("person") ||
                     PersonsCommand.configuration.abstract.contains("segmentation"))
    }

    func testPersonsCommandDiscussion() {
        let discussion = PersonsCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("QUICK START"))
        XCTAssertTrue(discussion.contains("QUALITY LEVELS"))
        XCTAssertTrue(discussion.contains("EXAMPLES"))
        XCTAssertTrue(discussion.contains("fast"))
        XCTAssertTrue(discussion.contains("balanced"))
        XCTAssertTrue(discussion.contains("accurate"))
    }

    func testPersonsCommandDiscussionContainsOptions() {
        let discussion = PersonsCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("--quality"))
        XCTAssertTrue(discussion.contains("--format"))
    }

    func testPersonsCommandDiscussionContainsOutputInfo() {
        let discussion = PersonsCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("OUTPUT FORMATS"))
        XCTAssertTrue(discussion.contains("mask"))
        XCTAssertTrue(discussion.contains("grayscale"))
    }

    // MARK: - VisionService Tests

    func testVisionServiceExists() {
        let service = ServiceContainer.shared.visionService
        XCTAssertNotNil(service)
    }

    func testVisionServiceCanBeCreated() {
        let service = VisionService()
        XCTAssertNotNil(service)
    }

    // MARK: - VisionService Enum Tests

    func testOpticalFlowAccuracyAllCases() {
        let allCases = VisionService.OpticalFlowAccuracy.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.low))
        XCTAssertTrue(allCases.contains(.medium))
        XCTAssertTrue(allCases.contains(.high))
        XCTAssertTrue(allCases.contains(.veryHigh))
    }

    func testSaliencyTypeAllCases() {
        let allCases = VisionService.SaliencyType.allCases
        XCTAssertEqual(allCases.count, 2)
        XCTAssertTrue(allCases.contains(.attention))
        XCTAssertTrue(allCases.contains(.objectness))
    }

    func testPersonSegmentationQualityAllCases() {
        let allCases = VisionService.PersonSegmentationQuality.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.fast))
        XCTAssertTrue(allCases.contains(.balanced))
        XCTAssertTrue(allCases.contains(.accurate))
    }

    // MARK: - FileUtils Tests for Vision Commands

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
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("test-\(UUID().uuidString).txt")
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

    func testFlowCommandDefaultsInConfiguration() {
        let discussion = FlowCommand.configuration.discussion
        // Default accuracy is medium (shown in accuracy levels)
        XCTAssertTrue(discussion.contains("medium"))
        // Has format option
        XCTAssertTrue(discussion.contains("json"))
    }

    func testSaliencyCommandDefaultsInConfiguration() {
        let discussion = SaliencyCommand.configuration.discussion
        // Default type is attention
        XCTAssertTrue(discussion.contains("attention"))
    }

    func testPersonsCommandDefaultsInConfiguration() {
        let discussion = PersonsCommand.configuration.discussion
        // Default quality is balanced
        XCTAssertTrue(discussion.contains("balanced"))
        // PNG is recommended
        XCTAssertTrue(discussion.contains("PNG"))
    }

    // MARK: - Help Documentation Quality Tests

    func testFlowCommandHelpQuality() {
        let discussion = FlowCommand.configuration.discussion
        // Check for comprehensive documentation
        XCTAssertTrue(discussion.contains("QUICK START"))
        XCTAssertTrue(discussion.contains("EXAMPLES"))
        XCTAssertTrue(discussion.contains("OUTPUT EXAMPLE"))
        XCTAssertTrue(discussion.contains("NOTE"))
    }

    func testAlignCommandHelpQuality() {
        let discussion = AlignCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("QUICK START"))
        XCTAssertTrue(discussion.contains("EXAMPLES"))
        XCTAssertTrue(discussion.contains("OUTPUT EXAMPLE"))
        XCTAssertTrue(discussion.contains("REQUIREMENTS"))
    }

    func testSaliencyCommandHelpQuality() {
        let discussion = SaliencyCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("QUICK START"))
        XCTAssertTrue(discussion.contains("EXAMPLES"))
        XCTAssertTrue(discussion.contains("OUTPUT EXAMPLE"))
        XCTAssertTrue(discussion.contains("USE CASES"))
    }

    func testPersonsCommandHelpQuality() {
        let discussion = PersonsCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("QUICK START"))
        XCTAssertTrue(discussion.contains("EXAMPLES"))
        XCTAssertTrue(discussion.contains("OUTPUT EXAMPLE"))
        XCTAssertTrue(discussion.contains("BEST PRACTICES"))
        XCTAssertTrue(discussion.contains("REQUIREMENTS"))
    }
}
