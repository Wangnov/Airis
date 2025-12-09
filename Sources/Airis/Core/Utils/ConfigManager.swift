import Foundation

/// Provider 配置模型
struct ProviderConfig: Codable, Sendable {
    var baseURL: String?
    var model: String?
    var customHeaders: [String: String]?

    enum CodingKeys: String, CodingKey {
        case baseURL = "base_url"
        case model
        case customHeaders = "custom_headers"
    }
}

/// 全局配置模型
struct AppConfig: Codable, Sendable {
    var providers: [String: ProviderConfig]
    var defaultProvider: String?

    enum CodingKeys: String, CodingKey {
        case providers
        case defaultProvider = "default_provider"
    }

    init() {
        self.providers = [:]
        self.defaultProvider = "gemini"
    }
}

/// 配置文件管理器（支持依赖注入，测试隔离）
final class ConfigManager: Sendable {
    /// 默认配置目录
    static let defaultConfigDirectory: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".config/airis")
    }()

    /// 默认配置文件路径
    static let defaultConfigFile: URL = {
        defaultConfigDirectory.appendingPathComponent("config.json")
    }()

    /// 默认 Provider 配置
    static let defaultConfigs: [String: ProviderConfig] = [
        "gemini": ProviderConfig(
            baseURL: "https://generativelanguage.googleapis.com",
            model: "gemini-3-pro-image-preview",
            customHeaders: nil
        )
    ]

    // MARK: - Instance Properties

    private let configFile: URL
    private let configDirectory: URL

    /// 初始化
    /// - Parameter configFile: 自定义配置文件路径（默认使用 ~/.config/airis/config.json）
    init(configFile: URL? = nil) {
        if let customFile = configFile {
            self.configFile = customFile
            self.configDirectory = customFile.deletingLastPathComponent()
        } else {
            self.configFile = Self.defaultConfigFile
            self.configDirectory = Self.defaultConfigDirectory
        }
    }

    /// 加载配置
    func loadConfig() throws -> AppConfig {
        // 如果文件不存在，返回默认配置
        guard FileManager.default.fileExists(atPath: configFile.path) else {
            var config = AppConfig()
            config.providers = Self.defaultConfigs
            return config
        }

        let data = try Data(contentsOf: configFile)
        let decoder = JSONDecoder()
        var config = try decoder.decode(AppConfig.self, from: data)

        // 合并默认配置（确保新 provider 有默认值）
        for (name, defaultConfig) in Self.defaultConfigs where config.providers[name] == nil {
            config.providers[name] = defaultConfig
        }

        return config
    }

    /// 保存配置
    func saveConfig(_ config: AppConfig) throws {
        // 确保目录存在
        try FileManager.default.createDirectory(
            at: configDirectory,
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)

        try data.write(to: configFile)
    }

    /// 获取 Provider 配置
    func getProviderConfig(for provider: String) throws -> ProviderConfig {
        let config = try loadConfig()
        if let providerConfig = config.providers[provider] {
            return providerConfig
        }
        // 返回默认配置或空配置
        return Self.defaultConfigs[provider] ?? ProviderConfig()
    }

    /// 更新 Provider 配置
    func updateProviderConfig(
        for provider: String,
        baseURL: String? = nil,
        model: String? = nil
    ) throws {
        var config = try loadConfig()
        var providerConfig = config.providers[provider] ?? Self.defaultConfigs[provider] ?? ProviderConfig()

        if let baseURL = baseURL {
            providerConfig.baseURL = baseURL
        }
        if let model = model {
            providerConfig.model = model
        }

        config.providers[provider] = providerConfig
        try saveConfig(config)
    }

    /// 重置 Provider 配置为默认值
    func resetProviderConfig(for provider: String) throws {
        var config = try loadConfig()
        config.providers[provider] = Self.defaultConfigs[provider]
        try saveConfig(config)
    }

    /// 获取配置文件路径（用于显示）
    func getConfigFilePath() -> String {
        configFile.path
    }
}
