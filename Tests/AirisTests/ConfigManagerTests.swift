import XCTest
@testable import Airis

final class ConfigManagerTests: XCTestCase {

    var tempConfigFile: URL!
    var originalConfigFile: URL!

    override func setUp() {
        super.setUp()

        // 保存原始配置文件路径
        originalConfigFile = ConfigManager.configFile

        // 创建临时配置文件
        let tempDir = FileManager.default.temporaryDirectory
        tempConfigFile = tempDir.appendingPathComponent("test_config_\(UUID().uuidString).json")

        // 替换配置文件路径（需要修改 ConfigManager 支持）
        // 这里先测试默认行为
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
        let manager = ConfigManager()
        let config = try manager.loadConfig()

        // 应包含默认的 gemini provider
        XCTAssertNotNil(config.providers["gemini"])
        XCTAssertEqual(config.defaultProvider, "gemini")
    }

    func testLoadConfigWithDefaults() throws {
        let manager = ConfigManager()
        let config = try manager.loadConfig()

        let geminiConfig = config.providers["gemini"]
        XCTAssertNotNil(geminiConfig?.baseURL)
        XCTAssertNotNil(geminiConfig?.model)
        XCTAssertTrue(geminiConfig?.baseURL?.contains("googleapis") ?? false)
    }

    // MARK: - Update Config Tests

    func testUpdateProviderConfig() throws {
        let manager = ConfigManager()

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
        let manager = ConfigManager()

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
        let manager = ConfigManager()

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
        let manager = ConfigManager()

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
        let manager = ConfigManager()

        // 获取不存在的 provider 应返回空配置
        let config = try manager.getProviderConfig(for: "unknown-provider")
        XCTAssertNil(config.baseURL)
        XCTAssertNil(config.model)
    }

    // MARK: - Config File Path Tests

    func testGetConfigFilePath() {
        let manager = ConfigManager()
        let path = manager.getConfigFilePath()

        XCTAssertTrue(path.contains(".config/airis"))
        XCTAssertTrue(path.hasSuffix("config.json"))
    }

    // MARK: - Default Configs Tests

    func testDefaultConfigsExist() {
        XCTAssertFalse(ConfigManager.defaultConfigs.isEmpty)
        XCTAssertNotNil(ConfigManager.defaultConfigs["gemini"])
    }

    func testDefaultGeminiConfig() {
        guard let geminiConfig = ConfigManager.defaultConfigs["gemini"] else {
            XCTFail("Gemini default config not found")
            return
        }

        XCTAssertNotNil(geminiConfig.baseURL)
        XCTAssertNotNil(geminiConfig.model)
        XCTAssertTrue(geminiConfig.baseURL?.contains("googleapis") ?? false)
    }
}
