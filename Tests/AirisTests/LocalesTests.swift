import XCTest
@testable import Airis

final class LocalesTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // 重置为默认语言
        Language.current = .en
    }

    // MARK: - Language Tests

    func testLanguageResolutionWithExplicit() throws {
        XCTAssertEqual(Language.resolve(explicit: .en), .en)
        XCTAssertEqual(Language.resolve(explicit: .cn), .cn)
    }

    func testLanguageResolutionWithEnvironment() throws {
        // 设置环境变量
        setenv("AIRIS_LANG", "cn", 1)
        XCTAssertEqual(Language.resolve(explicit: nil), .cn)

        setenv("AIRIS_LANG", "en", 1)
        XCTAssertEqual(Language.resolve(explicit: nil), .en)

        // 清理
        unsetenv("AIRIS_LANG")
    }

    func testLanguageFromSystem() throws {
        // 仅验证不崩溃，因为依赖系统设置
        let systemLang = Language.fromSystem
        XCTAssertTrue([Language.en, Language.cn].contains(systemLang))
    }

    func testExplicitOverridesEnvironment() throws {
        setenv("AIRIS_LANG", "cn", 1)
        XCTAssertEqual(Language.resolve(explicit: .en), .en)
        unsetenv("AIRIS_LANG")
    }

    // MARK: - Strings Tests

    func testStringsGetEnglish() throws {
        Language.current = .en
        XCTAssertEqual(
            Strings.get("error.file_not_found", "/test.jpg"),
            "File not found: /test.jpg"
        )
    }

    func testStringsGetChinese() throws {
        Language.current = .cn
        XCTAssertEqual(
            Strings.get("error.file_not_found", "/test.jpg"),
            "文件未找到：/test.jpg"
        )
    }

    func testStringsGetMultipleArgs() throws {
        Language.current = .en
        let result = Strings.get("info.dimension", 1920, 1080)
        XCTAssertEqual(result, "Dimensions: 1920 × 1080 px")
    }

    func testStringsGetUnknownKey() throws {
        // 未知 key 应返回 key 本身
        let unknownKey = "unknown.key.test"
        XCTAssertEqual(Strings.get(unknownKey), unknownKey)
    }

    func testStringsLanguageSwitching() throws {
        Language.current = .en
        let enResult = Strings.get("info.success")
        XCTAssertEqual(enResult, "Success")

        Language.current = .cn
        let cnResult = Strings.get("info.success")
        XCTAssertEqual(cnResult, "成功")
    }
}
