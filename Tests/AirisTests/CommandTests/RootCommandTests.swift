import XCTest
@testable import Airis

final class RootCommandTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Language.current = .en
    }

    // MARK: - Language Resolution Tests

    func testLanguageResolveWithExplicitEnglish() throws {
        Language.current = Language.resolve(explicit: .en)
        XCTAssertEqual(Language.current, .en)
    }

    func testLanguageResolveWithExplicitChinese() throws {
        Language.current = Language.resolve(explicit: .cn)
        XCTAssertEqual(Language.current, .cn)
    }

    func testLanguageResolveWithNil() throws {
        Language.current = Language.resolve(explicit: nil)
        // 应该是系统语言或环境变量
        XCTAssertTrue([Language.en, Language.cn].contains(Language.current))
    }

    // MARK: - Command Configuration Tests

    func testRootCommandConfiguration() throws {
        XCTAssertEqual(Airis.configuration.commandName, "airis")
        XCTAssertEqual(Airis.configuration.version, "1.0.0")
        XCTAssertEqual(Airis.configuration.subcommands.count, 5)
    }

    func testGenCommandConfiguration() throws {
        XCTAssertEqual(GenCommand.configuration.commandName, "gen")
        XCTAssertTrue(GenCommand.configuration.abstract.contains("Generate"))
    }

    func testAnalyzeCommandConfiguration() throws {
        XCTAssertEqual(AnalyzeCommand.configuration.commandName, "analyze")
        XCTAssertTrue(AnalyzeCommand.configuration.abstract.contains("Analyze"))
    }

    func testDetectCommandConfiguration() throws {
        XCTAssertEqual(DetectCommand.configuration.commandName, "detect")
        XCTAssertTrue(DetectCommand.configuration.abstract.contains("Detect"))
    }

    func testVisionCommandConfiguration() throws {
        XCTAssertEqual(VisionCommand.configuration.commandName, "vision")
        XCTAssertTrue(VisionCommand.configuration.abstract.contains("vision"))
    }

    func testEditCommandConfiguration() throws {
        XCTAssertEqual(EditCommand.configuration.commandName, "edit")
        XCTAssertTrue(EditCommand.configuration.abstract.contains("Edit"))
        XCTAssertEqual(EditCommand.configuration.subcommands.count, 2)
    }

    func testFilterCommandConfiguration() throws {
        XCTAssertEqual(FilterCommand.configuration.commandName, "filter")
        XCTAssertTrue(FilterCommand.configuration.abstract.contains("filter"))
    }

    func testAdjustCommandConfiguration() throws {
        XCTAssertEqual(AdjustCommand.configuration.commandName, "adjust")
        XCTAssertTrue(AdjustCommand.configuration.abstract.contains("Adjust"))
    }
}
