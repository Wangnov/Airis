import XCTest
@testable import Airis

final class AnalyzeCommandTests: XCTestCase {

    // MARK: - AnalyzeCommand Configuration Tests

    func testAnalyzeCommandHasSubcommands() throws {
        XCTAssertEqual(AnalyzeCommand.configuration.subcommands.count, 8)
        XCTAssertEqual(AnalyzeCommand.configuration.commandName, "analyze")
    }

    func testAnalyzeCommandAbstract() throws {
        XCTAssertTrue(AnalyzeCommand.configuration.abstract.contains("Analyze"))
    }

    // MARK: - InfoCommand Configuration Tests

    func testInfoCommandConfiguration() throws {
        XCTAssertEqual(InfoCommand.configuration.commandName, "info")
        XCTAssertTrue(InfoCommand.configuration.abstract.contains("image information"))
    }

    func testInfoCommandDiscussionContainsQuickStart() throws {
        let discussion = InfoCommand.configuration.discussion ?? ""
        XCTAssertTrue(discussion.contains("QUICK START"))
        XCTAssertTrue(discussion.contains("EXAMPLES"))
        XCTAssertTrue(discussion.contains("OUTPUT FORMAT"))
    }

    // MARK: - TagCommand Configuration Tests

    func testTagCommandConfiguration() throws {
        XCTAssertEqual(TagCommand.configuration.commandName, "tag")
        XCTAssertTrue(TagCommand.configuration.abstract.contains("Classify"))
    }

    func testTagCommandDiscussionContainsExamples() throws {
        let discussion = TagCommand.configuration.discussion ?? ""
        XCTAssertTrue(discussion.contains("QUICK START"))
        XCTAssertTrue(discussion.contains("EXAMPLES"))
        XCTAssertTrue(discussion.contains("OPTIONS"))
    }

    // MARK: - ScoreCommand Configuration Tests

    func testScoreCommandConfiguration() throws {
        XCTAssertEqual(ScoreCommand.configuration.commandName, "score")
        XCTAssertTrue(ScoreCommand.configuration.abstract.contains("aesthetic"))
    }

    func testScoreCommandDiscussionContainsRequirements() throws {
        let discussion = ScoreCommand.configuration.discussion ?? ""
        XCTAssertTrue(discussion.contains("macOS 15.0"))
        XCTAssertTrue(discussion.contains("SCORE INTERPRETATION"))
    }

    // MARK: - OCRCommand Configuration Tests

    func testOCRCommandConfiguration() throws {
        XCTAssertEqual(OCRCommand.configuration.commandName, "ocr")
        XCTAssertTrue(OCRCommand.configuration.abstract.contains("text"))
    }

    func testOCRCommandDiscussionContainsLanguages() throws {
        let discussion = OCRCommand.configuration.discussion ?? ""
        XCTAssertTrue(discussion.contains("SUPPORTED LANGUAGES"))
        XCTAssertTrue(discussion.contains("zh-Hans"))
        XCTAssertTrue(discussion.contains("en"))
    }

    // MARK: - Service Integration Tests

    func testVisionServiceAccessible() throws {
        let service = ServiceContainer.shared.visionService
        XCTAssertNotNil(service)
    }

    func testImageIOServiceAccessible() throws {
        let service = ServiceContainer.shared.imageIOService
        XCTAssertNotNil(service)
    }

    // MARK: - ScoreCommand Result Structure Tests

    func testAestheticsResultStructure() throws {
        let result = ScoreCommand.AestheticsResult(
            overallScore: 0.75,
            isUtility: false
        )

        XCTAssertEqual(result.overallScore, 0.75)
        XCTAssertFalse(result.isUtility)
    }

    func testAestheticsResultNegativeScore() throws {
        let result = ScoreCommand.AestheticsResult(
            overallScore: -0.5,
            isUtility: true
        )

        XCTAssertEqual(result.overallScore, -0.5)
        XCTAssertTrue(result.isUtility)
    }

    // MARK: - OCRCommand Result Structure Tests

    func testOCRTextResultStructure() throws {
        let result = OCRCommand.TextResult(
            text: "Hello World",
            confidence: 0.95,
            boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4)
        )

        XCTAssertEqual(result.text, "Hello World")
        XCTAssertEqual(result.confidence, 0.95)
        XCTAssertEqual(result.boundingBox.origin.x, 0.1)
        XCTAssertEqual(result.boundingBox.origin.y, 0.2)
        XCTAssertEqual(result.boundingBox.width, 0.3)
        XCTAssertEqual(result.boundingBox.height, 0.4)
    }

    // MARK: - Localization Tests

    func testAnalyzeStringsExist() throws {
        XCTAssertFalse(Strings.get("analyze.processing").isEmpty)
        XCTAssertFalse(Strings.get("analyze.tag.found", 5).isEmpty)
        XCTAssertFalse(Strings.get("analyze.ocr.found", 3).isEmpty)
    }

    func testScoreRatingStringsExist() throws {
        XCTAssertFalse(Strings.get("analyze.score.excellent").isEmpty)
        XCTAssertFalse(Strings.get("analyze.score.good").isEmpty)
        XCTAssertFalse(Strings.get("analyze.score.fair").isEmpty)
        XCTAssertFalse(Strings.get("analyze.score.poor").isEmpty)
    }

    func testInfoStringsExist() throws {
        XCTAssertFalse(Strings.get("info.dimension", 1920, 1080).isEmpty)
        XCTAssertFalse(Strings.get("info.dpi", 72).isEmpty)
        XCTAssertFalse(Strings.get("info.file_size", "2.3 MB").isEmpty)
    }

    // MARK: - FileUtils Integration Tests

    func testSupportedImageFormatsIncludesCommonFormats() throws {
        XCTAssertTrue(FileUtils.isSupportedImageFormat("test.jpg"))
        XCTAssertTrue(FileUtils.isSupportedImageFormat("test.jpeg"))
        XCTAssertTrue(FileUtils.isSupportedImageFormat("test.png"))
        XCTAssertTrue(FileUtils.isSupportedImageFormat("test.heic"))
        XCTAssertTrue(FileUtils.isSupportedImageFormat("test.webp"))
    }

    func testUnsupportedFormatRejected() throws {
        XCTAssertFalse(FileUtils.isSupportedImageFormat("test.txt"))
        XCTAssertFalse(FileUtils.isSupportedImageFormat("test.pdf"))
        XCTAssertFalse(FileUtils.isSupportedImageFormat("test.doc"))
    }
}
