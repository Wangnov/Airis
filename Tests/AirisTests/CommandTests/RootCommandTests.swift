import XCTest
#if !XCODE_BUILD
    @testable import AirisCore
#endif

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
        XCTAssertEqual(AirisCommand.configuration.commandName, "airis")
        XCTAssertEqual(AirisCommand.configuration.version, "1.0.0")
        XCTAssertEqual(AirisCommand.configuration.subcommands.count, 5)
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
        // 包含: cut, resize, crop, enhance, scan, straighten, trace, defringe, fmt, thumb, filter, adjust
        XCTAssertEqual(EditCommand.configuration.subcommands.count, 12)
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
