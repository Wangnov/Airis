import Foundation

/// 服务容器（单例模式，集中管理服务实例）
/// 线程安全：所有服务在初始化时创建，使用 let 确保并发安全
final class ServiceContainer: Sendable {
    static let shared = ServiceContainer()

    // MARK: - Vision 和 Image 服务

    /// Vision 框架服务
    let visionService: VisionService

    /// ImageIO 服务
    let imageIOService: ImageIOService

    /// CoreImage 服务（图像编辑）
    let coreImageService: CoreImageService

    // MARK: - 网络和存储服务

    /// HTTP 客户端
    let httpClient: HTTPClient

    /// Keychain 管理器
    let keychainManager: KeychainManager

    /// 配置管理器
    let configManager: ConfigManager

    // MARK: - Provider 服务

    /// Gemini Provider（使用默认 gemini）
    let geminiProvider: GeminiProvider

    // MARK: - 初始化

    private init() {
        // 基础服务
        self.visionService = VisionService()
        self.imageIOService = ImageIOService()
        self.coreImageService = CoreImageService()

        // 网络和存储
        self.httpClient = HTTPClient()
        self.keychainManager = KeychainManager()
        self.configManager = ConfigManager()

        // Provider（依赖其他服务）
        self.geminiProvider = GeminiProvider(
            providerName: "gemini",
            httpClient: httpClient,
            keychainManager: keychainManager,
            configManager: configManager
        )
    }

    /// 获取指定 provider
    func getProvider(name: String) -> GeminiProvider {
        GeminiProvider(
            providerName: name,
            httpClient: httpClient,
            keychainManager: keychainManager,
            configManager: configManager
        )
    }
}
