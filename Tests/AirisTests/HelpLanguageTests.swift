import XCTest
#if !XCODE_BUILD
@testable import AirisCore
#endif

final class HelpLanguageTests: XCTestCase {
    private var originalLanguage: Language = .en
    private var originalEnvLang: String?

    override func setUp() {
        super.setUp()
        originalLanguage = Language.current
        originalEnvLang = ProcessInfo.processInfo.environment["AIRIS_LANG"]
    }

    override func tearDown() {
        // 恢复全局状态，避免影响其它并发测试。
        Language.current = originalLanguage

        if let originalEnvLang {
            setenv("AIRIS_LANG", originalEnvLang, 1)
        } else {
            unsetenv("AIRIS_LANG")
        }

        super.tearDown()
    }

    func testArgumentPreparserParsesLangSpaceSeparated() {
        let lang = ArgumentPreparser.parseLang(from: ["airis", "--lang", "cn"])
        XCTAssertEqual(lang, .cn)
    }

    func testArgumentPreparserParsesLangEqualsForm() {
        let lang = ArgumentPreparser.parseLang(from: ["airis", "--lang=en"])
        XCTAssertEqual(lang, .en)
    }

    func testArgumentPreparserInvalidValueReturnsNil() {
        let lang = ArgumentPreparser.parseLang(from: ["airis", "--lang", "zh-Hans"])
        XCTAssertNil(lang)
    }

    func testArgumentPreparserLangWithoutValueReturnsNil() {
        let lang = ArgumentPreparser.parseLang(from: ["airis", "--lang"])
        XCTAssertNil(lang)
    }

    func testHelpRespectsAIRIS_LANG_CN() {
        setenv("AIRIS_LANG", "cn", 1)
        let help = AirisCommand.helpMessage()
        XCTAssertTrue(help.contains("AI 驱动的图像处理 CLI 工具"))
        XCTAssertTrue(help.contains("输出语言"))
    }

    func testHelpRespectsAIRIS_LANG_EN() {
        setenv("AIRIS_LANG", "en", 1)
        let help = AirisCommand.helpMessage()
        XCTAssertTrue(help.contains("The AI-Native Messenger for Image Operations"))
        XCTAssertTrue(help.contains("Output language"))
    }
}
