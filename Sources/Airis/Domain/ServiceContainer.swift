import Foundation

/// 服务容器（单例模式，集中管理服务实例）
final class ServiceContainer: @unchecked Sendable {
    static let shared = ServiceContainer()

    // MARK: - Vision 和 Image 服务

    /// Vision 框架服务
    lazy var visionService = VisionService()

    /// ImageIO 服务
    lazy var imageIOService = ImageIOService()

    // MARK: - 网络和存储服务

    /// HTTP 客户端
    lazy var httpClient = HTTPClient()

    /// Keychain 管理器
    lazy var keychainManager = KeychainManager()

    /// 配置管理器
    lazy var configManager = ConfigManager()

    // MARK: - Provider 服务

    /// Gemini Provider（使用默认 gemini）
    lazy var geminiProvider: GeminiProvider = {
        GeminiProvider(
            providerName: "gemini",
            httpClient: httpClient,
            keychainManager: keychainManager,
            configManager: configManager
        )
    }()

    /// 获取指定 provider
    func getProvider(name: String) -> GeminiProvider {
        GeminiProvider(
            providerName: name,
            httpClient: httpClient,
            keychainManager: keychainManager,
            configManager: configManager
        )
    }

    // MARK: - 图像编辑服务

    /// CoreImage 服务（图像编辑）
    lazy var coreImageService = CoreImageService()

    // MARK: - 未来扩展的服务（占位）

    // lazy var sensitiveContentService = SensitiveContentService()

    private init() {}
}
