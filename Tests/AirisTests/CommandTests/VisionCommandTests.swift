import XCTest
#if !XCODE_BUILD
    @testable import AirisCore
#endif

final class VisionCommandTests: XCTestCase {
    // MARK: - VisionCommand Configuration Tests

    func testVisionCommandHasSubcommands() throws {
        XCTAssertEqual(VisionCommand.configuration.subcommands.count, 4)
        XCTAssertEqual(VisionCommand.configuration.commandName, "vision")
    }

    func testVisionCommandAbstract() throws {
        XCTAssertTrue(VisionCommand.configuration.abstract.contains("vision"))
    }

    func testVisionCommandDiscussionContainsQuickStart() throws {
        let discussion = VisionCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("QUICK START"))
        XCTAssertTrue(discussion.contains("SUBCOMMANDS"))
    }

    // MARK: - FlowCommand Configuration Tests

    func testFlowCommandConfiguration() throws {
        XCTAssertEqual(FlowCommand.configuration.commandName, "flow")
        XCTAssertTrue(FlowCommand.configuration.abstract.contains("optical flow"))
    }

    func testFlowCommandDiscussion() throws {
        let discussion = FlowCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("QUICK START"))
        XCTAssertTrue(discussion.contains("ACCURACY LEVELS"))
        XCTAssertTrue(discussion.contains("EXAMPLES"))
        XCTAssertTrue(discussion.contains("low"))
        XCTAssertTrue(discussion.contains("medium"))
        XCTAssertTrue(discussion.contains("high"))
        XCTAssertTrue(discussion.contains("veryHigh"))
    }

    func testFlowCommandDiscussionContainsOptions() throws {
        let discussion = FlowCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("--accuracy"))
        XCTAssertTrue(discussion.contains("--format"))
    }

    // MARK: - AlignCommand Configuration Tests

    func testAlignCommandConfiguration() throws {
        XCTAssertEqual(AlignCommand.configuration.commandName, "align")
        XCTAssertTrue(AlignCommand.configuration.abstract.contains("alignment") ||
            AlignCommand.configuration.abstract.contains("registration"))
    }

    func testAlignCommandDiscussion() throws {
        let discussion = AlignCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("QUICK START"))
        XCTAssertTrue(discussion.contains("EXAMPLES"))
        XCTAssertTrue(discussion.contains("reference"))
        XCTAssertTrue(discussion.contains("floating"))
    }

    func testAlignCommandDiscussionContainsOptions() throws {
        let discussion = AlignCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("--format"))
    }

    // MARK: - SaliencyCommand Configuration Tests

    func testSaliencyCommandConfiguration() throws {
        XCTAssertEqual(SaliencyCommand.configuration.commandName, "saliency")
        XCTAssertTrue(SaliencyCommand.configuration.abstract.contains("saliency") ||
            SaliencyCommand.configuration.abstract.contains("attention"))
    }

    func testSaliencyCommandDiscussion() throws {
        let discussion = SaliencyCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("QUICK START"))
        XCTAssertTrue(discussion.contains("SALIENCY TYPES"))
        XCTAssertTrue(discussion.contains("EXAMPLES"))
        XCTAssertTrue(discussion.contains("attention"))
        XCTAssertTrue(discussion.contains("objectness"))
    }

    func testSaliencyCommandDiscussionContainsOptions() throws {
        let discussion = SaliencyCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("--type"))
        XCTAssertTrue(discussion.contains("--format"))
    }

    // MARK: - PersonsCommand Configuration Tests

    func testPersonsCommandConfiguration() throws {
        XCTAssertEqual(PersonsCommand.configuration.commandName, "persons")
        XCTAssertTrue(PersonsCommand.configuration.abstract.contains("person") ||
            PersonsCommand.configuration.abstract.contains("segmentation"))
    }

    func testPersonsCommandDiscussion() throws {
        let discussion = PersonsCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("QUICK START"))
        XCTAssertTrue(discussion.contains("QUALITY LEVELS"))
        XCTAssertTrue(discussion.contains("EXAMPLES"))
        XCTAssertTrue(discussion.contains("fast"))
        XCTAssertTrue(discussion.contains("balanced"))
        XCTAssertTrue(discussion.contains("accurate"))
    }

    func testPersonsCommandDiscussionContainsOptions() throws {
        let discussion = PersonsCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("--quality"))
        XCTAssertTrue(discussion.contains("--format"))
    }

    func testPersonsCommandDiscussionContainsOutputInfo() throws {
        let discussion = PersonsCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("OUTPUT FORMATS"))
        XCTAssertTrue(discussion.contains("mask"))
        XCTAssertTrue(discussion.contains("grayscale"))
    }

    // MARK: - VisionService Tests

    func testVisionServiceExists() throws {
        let service = ServiceContainer.shared.visionService
        XCTAssertNotNil(service)
    }

    func testVisionServiceCanBeCreated() throws {
        let service = VisionService()
        XCTAssertNotNil(service)
    }

    // MARK: - VisionService Enum Tests

    func testOpticalFlowAccuracyAllCases() throws {
        let allCases = VisionService.OpticalFlowAccuracy.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.low))
        XCTAssertTrue(allCases.contains(.medium))
        XCTAssertTrue(allCases.contains(.high))
        XCTAssertTrue(allCases.contains(.veryHigh))
    }

    func testSaliencyTypeAllCases() throws {
        let allCases = VisionService.SaliencyType.allCases
        XCTAssertEqual(allCases.count, 2)
        XCTAssertTrue(allCases.contains(.attention))
        XCTAssertTrue(allCases.contains(.objectness))
    }

    func testPersonSegmentationQualityAllCases() throws {
        let allCases = VisionService.PersonSegmentationQuality.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.fast))
        XCTAssertTrue(allCases.contains(.balanced))
        XCTAssertTrue(allCases.contains(.accurate))
    }

    // MARK: - FileUtils Tests for Vision Commands

    func testValidateImageFileThrowsForNonexistent() throws {
        XCTAssertThrowsError(try FileUtils.validateImageFile(at: "/nonexistent/file.jpg")) { error in
            if case AirisError.fileNotFound = error {
                // Expected
            } else {
                XCTFail("Expected fileNotFound error")
            }
        }
    }

    func testValidateImageFileThrowsForUnsupportedFormat() throws {
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

    func testFlowCommandDefaultsInConfiguration() throws {
        let discussion = FlowCommand.configuration.discussion
        // Default accuracy is medium (shown in accuracy levels)
        XCTAssertTrue(discussion.contains("medium"))
        // Has format option
        XCTAssertTrue(discussion.contains("json"))
    }

    func testSaliencyCommandDefaultsInConfiguration() throws {
        let discussion = SaliencyCommand.configuration.discussion
        // Default type is attention
        XCTAssertTrue(discussion.contains("attention"))
    }

    func testPersonsCommandDefaultsInConfiguration() throws {
        let discussion = PersonsCommand.configuration.discussion
        // Default quality is balanced
        XCTAssertTrue(discussion.contains("balanced"))
        // PNG is recommended
        XCTAssertTrue(discussion.contains("PNG"))
    }

    // MARK: - Help Documentation Quality Tests

    func testFlowCommandHelpQuality() throws {
        let discussion = FlowCommand.configuration.discussion
        // Check for comprehensive documentation
        XCTAssertTrue(discussion.contains("QUICK START"))
        XCTAssertTrue(discussion.contains("EXAMPLES"))
        XCTAssertTrue(discussion.contains("OUTPUT EXAMPLE"))
        XCTAssertTrue(discussion.contains("NOTE"))
    }

    func testAlignCommandHelpQuality() throws {
        let discussion = AlignCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("QUICK START"))
        XCTAssertTrue(discussion.contains("EXAMPLES"))
        XCTAssertTrue(discussion.contains("OUTPUT EXAMPLE"))
        XCTAssertTrue(discussion.contains("REQUIREMENTS"))
    }

    func testSaliencyCommandHelpQuality() throws {
        let discussion = SaliencyCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("QUICK START"))
        XCTAssertTrue(discussion.contains("EXAMPLES"))
        XCTAssertTrue(discussion.contains("OUTPUT EXAMPLE"))
        XCTAssertTrue(discussion.contains("USE CASES"))
    }

    func testPersonsCommandHelpQuality() throws {
        let discussion = PersonsCommand.configuration.discussion
        XCTAssertTrue(discussion.contains("QUICK START"))
        XCTAssertTrue(discussion.contains("EXAMPLES"))
        XCTAssertTrue(discussion.contains("OUTPUT EXAMPLE"))
        XCTAssertTrue(discussion.contains("BEST PRACTICES"))
        XCTAssertTrue(discussion.contains("REQUIREMENTS"))
    }
}
