import XCTest
@testable import Airis

final class LocalesTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // 重置为默认语言
        Language.current = .en
        // 清理环境变量
        unsetenv("AIRIS_LANG")
    }

    override func tearDown() {
        unsetenv("AIRIS_LANG")
        Language.current = .en
        super.tearDown()
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

        unsetenv("AIRIS_LANG")
    }

    func testLanguageFromSystem() throws {
        // 验证不崩溃，因为依赖系统设置
        let systemLang = Language.fromSystem
        XCTAssertTrue([Language.en, Language.cn].contains(systemLang))
    }

    func testFromSystemLanguages_EmptyList() throws {
        // 测试空列表回退到 "en"
        XCTAssertEqual(Language.fromSystemLanguages([]), .en)
    }

    func testFromSystemLanguages_EnglishPrimary() throws {
        // 测试英文为主语言
        XCTAssertEqual(Language.fromSystemLanguages(["en-US", "zh-CN"]), .en)
    }

    func testFromSystemLanguages_ChinesePrimary() throws {
        // 测试中文为主语言
        XCTAssertEqual(Language.fromSystemLanguages(["zh-Hans-CN", "en-US"]), .cn)
        XCTAssertEqual(Language.fromSystemLanguages(["zh-Hant-TW"]), .cn)
        XCTAssertEqual(Language.fromSystemLanguages(["zh"]), .cn)
    }

    func testFromSystemLanguages_FallbackToEnglish() throws {
        // 测试其他语言回退到英文
        XCTAssertEqual(Language.fromSystemLanguages(["ja-JP"]), .en)
        XCTAssertEqual(Language.fromSystemLanguages(["fr-FR"]), .en)
    }

    func testExplicitOverridesEnvironment() throws {
        setenv("AIRIS_LANG", "cn", 1)
        XCTAssertEqual(Language.resolve(explicit: .en), .en)
        unsetenv("AIRIS_LANG")
    }

    func testFromEnvironmentWithNoEnv() throws {
        unsetenv("AIRIS_LANG")
        XCTAssertNil(Language.fromEnvironment)
    }

    func testFromEnvironmentWithInvalidValue() throws {
        setenv("AIRIS_LANG", "invalid", 1)
        XCTAssertNil(Language.fromEnvironment)
        unsetenv("AIRIS_LANG")
    }

    func testFromEnvironmentCaseInsensitive() throws {
        setenv("AIRIS_LANG", "CN", 1)
        XCTAssertEqual(Language.fromEnvironment, .cn)

        setenv("AIRIS_LANG", "EN", 1)
        XCTAssertEqual(Language.fromEnvironment, .en)

        unsetenv("AIRIS_LANG")
    }

    func testResolveWithoutExplicitOrEnv() throws {
        unsetenv("AIRIS_LANG")
        let resolved = Language.resolve(explicit: nil)
        // 应该回退到系统语言
        XCTAssertTrue([Language.en, Language.cn].contains(resolved))
    }

    func testResolveAllBranches() throws {
        // 分支 1: explicit 优先
        XCTAssertEqual(Language.resolve(explicit: .cn), .cn)

        // 分支 2: 环境变量
        setenv("AIRIS_LANG", "cn", 1)
        XCTAssertEqual(Language.resolve(explicit: nil), .cn)
        unsetenv("AIRIS_LANG")

        // 分支 3: 系统语言
        unsetenv("AIRIS_LANG")
        let systemResolved = Language.resolve(explicit: nil)
        XCTAssertNotNil(systemResolved)
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

    // MARK: - ExpressibleByArgument Tests

    func testLanguageFromRawValue() throws {
        XCTAssertEqual(Language(rawValue: "en"), .en)
        XCTAssertEqual(Language(rawValue: "cn"), .cn)
        XCTAssertNil(Language(rawValue: "invalid"))
    }

    func testLanguageAllCases() throws {
        XCTAssertEqual(Language.allCases.count, 2)
        XCTAssertTrue(Language.allCases.contains(.en))
        XCTAssertTrue(Language.allCases.contains(.cn))
    }

    func testLanguageRawValue() throws {
        XCTAssertEqual(Language.en.rawValue, "en")
        XCTAssertEqual(Language.cn.rawValue, "cn")
    }

    func testLanguageCurrentGetterSetter() throws {
        // 测试 current 的 getter/setter
        Language.current = .en
        XCTAssertEqual(Language.current, .en)

        Language.current = .cn
        XCTAssertEqual(Language.current, .cn)

        // 恢复默认
        Language.current = .en
    }
}

