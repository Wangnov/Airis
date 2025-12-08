import XCTest
@testable import Airis

final class KeychainManagerTests: XCTestCase {

    let keychain = KeychainManager()
    let testProvider = "test-provider-\(UUID().uuidString)"

    override func tearDown() {
        super.tearDown()

        // 清理测试数据
        try? keychain.deleteAPIKey(for: testProvider)
    }

    // MARK: - Save/Get Tests

    func testSaveAndGetAPIKey() throws {
        let testKey = "test-api-key-12345"

        // 保存
        try keychain.saveAPIKey(testKey, for: testProvider)

        // 读取
        let retrievedKey = try keychain.getAPIKey(for: testProvider)
        XCTAssertEqual(retrievedKey, testKey)
    }

    func testSaveOverwritesExistingKey() throws {
        let firstKey = "first-key-12345"
        let secondKey = "second-key-67890"

        // 保存第一个 key
        try keychain.saveAPIKey(firstKey, for: testProvider)
        let retrieved1 = try keychain.getAPIKey(for: testProvider)
        XCTAssertEqual(retrieved1, firstKey)

        // 覆盖第二个 key（测试 SecItemUpdate 路径）
        try keychain.saveAPIKey(secondKey, for: testProvider)
        let retrieved2 = try keychain.getAPIKey(for: testProvider)
        XCTAssertEqual(retrieved2, secondKey)
    }

    // MARK: - Delete Tests

    func testDeleteAPIKey() throws {
        let testKey = "key-to-delete-12345"

        // 保存
        try keychain.saveAPIKey(testKey, for: testProvider)
        XCTAssertTrue(keychain.hasAPIKey(for: testProvider))

        // 删除
        try keychain.deleteAPIKey(for: testProvider)
        XCTAssertFalse(keychain.hasAPIKey(for: testProvider))
    }

    func testDeleteNonExistentKeyDoesNotThrow() throws {
        // 删除不存在的 key 应该不抛出错误
        XCTAssertNoThrow(try keychain.deleteAPIKey(for: "non-existent-provider"))
    }

    // MARK: - HasAPIKey Tests

    func testHasAPIKey() throws {
        XCTAssertFalse(keychain.hasAPIKey(for: testProvider))

        try keychain.saveAPIKey("test-key", for: testProvider)
        XCTAssertTrue(keychain.hasAPIKey(for: testProvider))
    }

    // MARK: - Error Tests

    func testGetNonExistentKeyThrows() {
        XCTAssertThrowsError(try keychain.getAPIKey(for: "non-existent-provider")) { error in
            guard case AirisError.apiKeyNotFound = error else {
                XCTFail("Expected apiKeyNotFound error")
                return
            }
        }
    }

    // MARK: - Special Characters Tests

    func testSaveKeyWithSpecialCharacters() throws {
        let specialKey = "key-with-!@#$%^&*()_+-=[]{}|;':\",./<>?"

        try keychain.saveAPIKey(specialKey, for: testProvider)
        let retrieved = try keychain.getAPIKey(for: testProvider)
        XCTAssertEqual(retrieved, specialKey)
    }

    func testSaveKeyWithUnicode() throws {
        let unicodeKey = "密钥-🔑-key-测试"

        try keychain.saveAPIKey(unicodeKey, for: testProvider)
        let retrieved = try keychain.getAPIKey(for: testProvider)
        XCTAssertEqual(retrieved, unicodeKey)
    }

    // MARK: - Long Key Tests

    func testSaveLongAPIKey() throws {
        let longKey = String(repeating: "a", count: 1000)

        try keychain.saveAPIKey(longKey, for: testProvider)
        let retrieved = try keychain.getAPIKey(for: testProvider)
        XCTAssertEqual(retrieved, longKey)
    }
}
