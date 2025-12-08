import XCTest
@testable import Airis

final class GenCommandTests: XCTestCase {

    let keychain = KeychainManager()
    let testProvider = "test-gen-provider"

    override func tearDown() {
        super.tearDown()

        // 清理测试数据
        try? keychain.deleteAPIKey(for: testProvider)
        try? keychain.deleteAPIKey(for: "gemini")
    }

    // MARK: - GenCommand Configuration Tests

    func testGenCommandHasSubcommands() {
        XCTAssertEqual(GenCommand.configuration.subcommands.count, 2)
        XCTAssertEqual(GenCommand.configuration.commandName, "gen")
    }

    // MARK: - ConfigCommand Tests

    func testConfigCommandHasAllSubcommands() {
        // set-key, get-key, delete-key, set, show, reset
        XCTAssertEqual(ConfigCommand.configuration.subcommands.count, 6)
    }

    // MARK: - DrawCommand Configuration Tests

    func testDrawCommandConfiguration() {
        XCTAssertEqual(DrawCommand.configuration.commandName, "draw")
        XCTAssertTrue(DrawCommand.configuration.abstract.contains("Generate"))
    }

    // MARK: - Integration Tests

    func testConfigWorkflow() throws {
        let testKey = "integration-test-key-abc123"

        // 1. 保存 API Key
        try keychain.saveAPIKey(testKey, for: testProvider)

        // 2. 验证存在
        XCTAssertTrue(keychain.hasAPIKey(for: testProvider))

        // 3. 读取
        let retrieved = try keychain.getAPIKey(for: testProvider)
        XCTAssertEqual(retrieved, testKey)

        // 4. 更新
        let updatedKey = "updated-test-key-xyz789"
        try keychain.saveAPIKey(updatedKey, for: testProvider)
        let retrievedUpdated = try keychain.getAPIKey(for: testProvider)
        XCTAssertEqual(retrievedUpdated, updatedKey)

        // 5. 删除
        try keychain.deleteAPIKey(for: testProvider)
        XCTAssertFalse(keychain.hasAPIKey(for: testProvider))
    }

    func testGeminiProviderConfiguration() throws {
        let manager = ConfigManager()
        let config = try manager.getProviderConfig(for: "gemini")

        // 验证默认配置
        XCTAssertNotNil(config.baseURL)
        XCTAssertNotNil(config.model)
    }

    func testDefaultModelConstant() {
        XCTAssertEqual(GeminiProvider.defaultModel, "gemini-3-pro-image-preview")
    }

    func testMultiProviderSupport() throws {
        // 测试可以为不同 provider 配置
        let testKey1 = "test-key-1"
        let testKey2 = "test-key-2"

        try keychain.saveAPIKey(testKey1, for: "provider1")
        try keychain.saveAPIKey(testKey2, for: "provider2")

        XCTAssertEqual(try keychain.getAPIKey(for: "provider1"), testKey1)
        XCTAssertEqual(try keychain.getAPIKey(for: "provider2"), testKey2)

        try keychain.deleteAPIKey(for: "provider1")
        try keychain.deleteAPIKey(for: "provider2")
    }
}
