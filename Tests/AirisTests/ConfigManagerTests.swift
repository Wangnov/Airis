import XCTest
@testable import Airis

final class ConfigManagerTests: XCTestCase {

    var tempConfigFile: URL!
    var manager: ConfigManager!

    override func setUp() {
        super.setUp()

        // 创建临时配置文件路径
        let tempDir = FileManager.default.temporaryDirectory
        tempConfigFile = tempDir.appendingPathComponent("test_config_\(UUID().uuidString).json")

        // 使用临时路径初始化 ConfigManager
        manager = ConfigManager(configFile: tempConfigFile)
    }

    override func tearDown() {
        super.tearDown()

        // 清理临时文件
        if let tempFile = tempConfigFile {
            try? FileManager.default.removeItem(at: tempFile)
        }
    }

    // MARK: - Load/Save Tests

    func testLoadDefaultConfig() throws {
        let config = try manager.loadConfig()

        // 应包含默认的 gemini provider
        XCTAssertNotNil(config.providers["gemini"])
        XCTAssertEqual(config.defaultProvider, "gemini")
    }

    func testLoadConfigWithDefaults() throws {
        let config = try manager.loadConfig()

        let geminiConfig = config.providers["gemini"]
        XCTAssertNotNil(geminiConfig?.baseURL)
        XCTAssertNotNil(geminiConfig?.model)
        XCTAssertTrue(geminiConfig?.baseURL?.contains("googleapis") ?? false)
    }

    // MARK: - Update Config Tests

    func testUpdateProviderConfig() throws {
        // 更新配置
        try manager.updateProviderConfig(
            for: "gemini",
            baseURL: "https://test.example.com",
            model: "test-model"
        )

        // 验证更新
        let config = try manager.getProviderConfig(for: "gemini")
        XCTAssertEqual(config.baseURL, "https://test.example.com")
        XCTAssertEqual(config.model, "test-model")
    }

    func testUpdateOnlyBaseURL() throws {
        // 只更新 baseURL
        try manager.updateProviderConfig(
            for: "gemini",
            baseURL: "https://new-base.example.com",
            model: nil
        )

        let config = try manager.getProviderConfig(for: "gemini")
        XCTAssertEqual(config.baseURL, "https://new-base.example.com")
        XCTAssertNotNil(config.model)  // 应保留原有值
    }

    func testUpdateOnlyModel() throws {
        // 只更新 model
        try manager.updateProviderConfig(
            for: "gemini",
            baseURL: nil,
            model: "new-model"
        )

        let config = try manager.getProviderConfig(for: "gemini")
        XCTAssertNotNil(config.baseURL)  // 应保留原有值
        XCTAssertEqual(config.model, "new-model")
    }

    // MARK: - Reset Tests

    func testResetProviderConfig() throws {
        // 先修改配置
        try manager.updateProviderConfig(
            for: "gemini",
            baseURL: "https://custom.example.com",
            model: "custom-model"
        )

        // 重置
        try manager.resetProviderConfig(for: "gemini")

        // 验证已重置为默认值
        let config = try manager.getProviderConfig(for: "gemini")
        XCTAssertEqual(config.baseURL, ConfigManager.defaultConfigs["gemini"]?.baseURL)
        XCTAssertEqual(config.model, ConfigManager.defaultConfigs["gemini"]?.model)
    }

    // MARK: - Provider Config Tests

    func testGetProviderConfigForUnknownProvider() throws {
        // 获取不存在的 provider 应返回空配置
        let config = try manager.getProviderConfig(for: "unknown-provider")
        XCTAssertNil(config.baseURL)
        XCTAssertNil(config.model)
    }

    // MARK: - Config File Path Tests

    func testGetConfigFilePath() throws {
        let path = manager.getConfigFilePath()

        // 应该是临时文件路径
        XCTAssertTrue(path.contains("test_config"))
        XCTAssertTrue(path.hasSuffix(".json"))
    }

    // MARK: - Default Configs Tests

    func testDefaultConfigsExist() throws {
        XCTAssertFalse(ConfigManager.defaultConfigs.isEmpty)
        XCTAssertNotNil(ConfigManager.defaultConfigs["gemini"])
    }

    func testDefaultGeminiConfig() throws {
        guard let geminiConfig = ConfigManager.defaultConfigs["gemini"] else {
            XCTFail("Gemini default config not found")
            return
        }

        XCTAssertNotNil(geminiConfig.baseURL)
        XCTAssertNotNil(geminiConfig.model)
        XCTAssertTrue(geminiConfig.baseURL?.contains("googleapis") ?? false)
    }

    // MARK: - Isolation Tests

    func testTestsUseIsolatedConfig() throws {
        // 验证测试不会影响真实配置文件
        XCTAssertNotEqual(tempConfigFile.path, ConfigManager.defaultConfigFile.path)

        // 修改测试配置
        try manager.updateProviderConfig(for: "test", baseURL: "https://test.com")

        // 真实配置应该不受影响
        let realManager = ConfigManager()  // 使用默认路径
        let realConfig = try realManager.loadConfig()

        // 真实配置中不应该有 test provider
        XCTAssertNil(realConfig.providers["test"])
    }

    // MARK: - Default Path Computation Tests

    func testComputeDefaultConfigDirectory_NoEnvUsesHomeConfigDir() {
        let dir = ConfigManager.computeDefaultConfigDirectory(environment: [:])
        let expected = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/airis")
        XCTAssertEqual(dir.path, expected.path)
    }

    func testComputeDefaultConfigDirectory_UsesEnvOverride() {
        let customConfigFile = "/tmp/airis_custom/config.json"
        let dir = ConfigManager.computeDefaultConfigDirectory(environment: [
            "AIRIS_CONFIG_FILE": customConfigFile
        ])
        let expected = URL(fileURLWithPath: customConfigFile).deletingLastPathComponent()
        XCTAssertEqual(dir.path, expected.path)
    }

    func testComputeDefaultConfigFile_NoEnvUsesConfigJsonUnderDefaultDir() {
        let file = ConfigManager.computeDefaultConfigFile(environment: [:])
        let expectedDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/airis")
        let expected = expectedDir.appendingPathComponent("config.json")
        XCTAssertEqual(file.path, expected.path)
    }

    func testComputeDefaultConfigFile_UsesEnvOverride() {
        let customConfigFile = "/tmp/airis_custom/config.json"
        let file = ConfigManager.computeDefaultConfigFile(environment: [
            "AIRIS_CONFIG_FILE": customConfigFile
        ])
        XCTAssertEqual(file.path, URL(fileURLWithPath: customConfigFile).path)
    }

}
