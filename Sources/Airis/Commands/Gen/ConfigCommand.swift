import ArgumentParser
import Foundation

/// 测试友好：支持通过环境变量覆盖配置文件路径，避免污染真实用户配置
private func makeConfigManagerFromEnv() -> ConfigManager {
    if let custom = ProcessInfo.processInfo.environment["AIRIS_CONFIG_FILE"] {
        return ConfigManager(configFile: URL(fileURLWithPath: custom))
    }
    return ConfigManager()
}

struct ConfigCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "config",
        abstract: HelpTextFactory.text(
            en: "Manage API keys and configuration",
            cn: "管理 API Key 与配置"
        ),
        discussion: helpDiscussion(
            en: """
                Configure API keys and settings for AI providers.

                QUICK START:
                  1. Set API key:
                     airis gen config set-key --provider gemini --key "YOUR_API_KEY"

                  2. (Optional) Configure base URL:
                     airis gen config set --provider gemini --base-url "https://api.example.com"

                  3. (Optional) Configure default model:
                     airis gen config set --provider gemini --model "gemini-3-pro-image-preview"

                  4. View configuration:
                     airis gen config show --provider gemini

                STORAGE:
                  - API keys: Stored securely in macOS Keychain
                  - Settings: Stored in ~/.config/airis/config.json

                SUPPORTED PROVIDERS:
                  - gemini: Google Gemini Image Generation API
                            Get API key from: https://aistudio.google.com/apikey

                CONFIGURABLE SETTINGS (via 'set' command):
                  - base-url: API endpoint (default: https://generativelanguage.googleapis.com)
                  - model: Default model name (default: gemini-3-pro-image-preview)
                """,
            cn: """
                配置 AI Provider 的 API Key 与默认参数。

                QUICK START:
                  1) 设置 API key：
                     airis gen config set-key --provider gemini --key "YOUR_API_KEY"

                  2)（可选）设置 base URL：
                     airis gen config set --provider gemini --base-url "https://api.example.com"

                  3)（可选）设置默认模型：
                     airis gen config set --provider gemini --model "gemini-3-pro-image-preview"

                  4) 查看配置：
                     airis gen config show --provider gemini

                STORAGE:
                  - API key：安全存储在 macOS Keychain
                  - 配置：~/.config/airis/config.json

                SUPPORTED PROVIDERS:
                  - gemini：Google Gemini Image API
                            获取 API key：https://aistudio.google.com/apikey
                """
        ),
        subcommands: [
            SetKeyCommand.self,
            GetKeyCommand.self,
            DeleteKeyCommand.self,
            SetConfigCommand.self,
            ShowConfigCommand.self,
            ResetConfigCommand.self,
            SetDefaultCommand.self
        ]
    )
}

// MARK: - set-key

struct SetKeyCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "set-key",
        abstract: HelpTextFactory.text(
            en: "Set API key for a provider",
            cn: "设置 Provider 的 API Key"
        ),
        discussion: helpDiscussion(
            en: """
                Store an API key securely in macOS Keychain.

                Examples:
                  airis gen config set-key --provider gemini --key "your-api-key"
                  airis gen config set-key --provider gemini  # prompts for key
                """,
            cn: """
                将 API Key 安全写入 macOS Keychain（钥匙串）。

                EXAMPLES:
                  airis gen config set-key --provider gemini --key "your-api-key"
                  airis gen config set-key --provider gemini  # 交互式输入
                """
        )
    )

    @Option(name: .long, help: HelpTextFactory.help(en: "Provider name (e.g., gemini)", cn: "Provider 名称（例如：gemini）"))
    var provider: String

    @Option(name: .long, help: HelpTextFactory.help(en: "API key value (omit to enter interactively)", cn: "API Key（留空则交互输入）"))
    var key: String?

    func run() async throws {
        let apiKey: String
        if let providedKey = key {
            apiKey = providedKey
        } else {
            #if DEBUG
            let testInput = ProcessInfo.processInfo.environment["AIRIS_TEST_KEY_INPUT"]
            #else
            let testInput: String? = nil
            #endif

            if let forced = testInput, !forced.isEmpty {
                apiKey = forced
            } else {
                print(Strings.get("config.enter_key", provider), terminator: "")

                // 可替换的输入提供者（测试环境用环境变量返回，生产用 readLine）
                let inputProvider: () -> String? = {
                    #if DEBUG
                    if let stub = ProcessInfo.processInfo.environment["AIRIS_TEST_KEY_STDIN"] {
                        return stub
                    }
                    // 避免测试阻塞 stdin，未提供桩时返回空字符串以触发错误分支
                    return ""
                    #else
                    return readLine(strippingNewline: true)
                    #endif
                }

                guard let input = inputProvider(), !input.isEmpty else {
                    throw AirisError.invalidResponse
                }
                apiKey = input
            }
        }

        let keychain = KeychainManager()
        try keychain.saveAPIKey(apiKey, for: provider)

        print(Strings.get("config.key_saved", provider))
    }
}

// MARK: - get-key

struct GetKeyCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get-key",
        abstract: HelpTextFactory.text(
            en: "Get API key for a provider (masked)",
            cn: "查看 Provider 的 API Key（脱敏显示）"
        ),
        discussion: helpDiscussion(
            en: """
                Retrieve and display an API key (partially masked for security).

                Example:
                  airis gen config get-key --provider gemini
                """,
            cn: """
                从 macOS Keychain 读取 API Key，并以脱敏方式显示（仅显示首尾部分）。

                EXAMPLES:
                  airis gen config get-key --provider gemini
                """
        )
    )

    @Option(name: .long, help: HelpTextFactory.help(en: "Provider name", cn: "Provider 名称"))
    var provider: String

    func run() async throws {
        let keychain = KeychainManager()
        let key = try keychain.getAPIKey(for: provider)

        let masked = maskAPIKey(key)
        print(Strings.get("config.key_display", provider, masked))
    }

    private func maskAPIKey(_ key: String) -> String {
        guard key.count > 8 else {
            return String(repeating: "*", count: key.count)
        }
        let prefix = key.prefix(4)
        let suffix = key.suffix(4)
        let masked = String(repeating: "*", count: key.count - 8)
        return "\(prefix)\(masked)\(suffix)"
    }
}

// MARK: - delete-key

struct DeleteKeyCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete-key",
        abstract: HelpTextFactory.text(
            en: "Delete API key for a provider",
            cn: "删除 Provider 的 API Key"
        ),
        discussion: helpDiscussion(
            en: """
                Remove an API key from macOS Keychain.

                Example:
                  airis gen config delete-key --provider gemini
                """,
            cn: """
                从 macOS Keychain 删除指定 Provider 的 API Key。

                EXAMPLES:
                  airis gen config delete-key --provider gemini
                """
        )
    )

    @Option(name: .long, help: HelpTextFactory.help(en: "Provider name", cn: "Provider 名称"))
    var provider: String

    func run() async throws {
        let keychain = KeychainManager()
        try keychain.deleteAPIKey(for: provider)
        print(Strings.get("config.key_deleted", provider))
    }
}

// MARK: - set (config settings)

struct SetConfigCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "set",
        abstract: HelpTextFactory.text(
            en: "Set provider configuration",
            cn: "设置 Provider 配置"
        ),
        discussion: helpDiscussion(
            en: """
                Configure provider settings (stored in ~/.config/airis/config.json).

                AVAILABLE SETTINGS:
                  --base-url <url>     Custom API endpoint (default: https://generativelanguage.googleapis.com)
                  --model <name>       Default model name (default: gemini-3-pro-image-preview)

                EXAMPLES:
                  # Set custom API endpoint (e.g., proxy server)
                  airis gen config set --provider gemini --base-url "https://proxy.example.com"

                  # Set default model
                  airis gen config set --provider gemini --model "gemini-3-pro-image-preview"

                  # Set both at once
                  airis gen config set --provider gemini \\
                    --base-url "https://api.example.com" \\
                    --model "custom-model"

                NOTE: You can omit --provider if only one provider is configured.
                """,
            cn: """
                设置 Provider 的默认参数（写入 ~/.config/airis/config.json）。

                可配置项：
                  --base-url <url>   API Endpoint（默认：https://generativelanguage.googleapis.com）
                  --model <name>     默认模型名（默认：gemini-3-pro-image-preview）

                EXAMPLES:
                  # 设置自定义 API Endpoint（例如代理）
                  airis gen config set --provider gemini --base-url "https://proxy.example.com"

                  # 设置默认模型
                  airis gen config set --provider gemini --model "gemini-3-pro-image-preview"

                  # 同时设置
                  airis gen config set --provider gemini \\
                    --base-url "https://api.example.com" \\
                    --model "custom-model"
                """
        )
    )

    @Option(name: .long, help: HelpTextFactory.help(en: "Provider name (e.g., gemini)", cn: "Provider 名称（例如：gemini）"))
    var provider: String

    @Option(name: .long, help: HelpTextFactory.help(en: "API base URL", cn: "API Base URL"))
    var baseUrl: String?

    @Option(name: .long, help: HelpTextFactory.help(en: "Default model name", cn: "默认模型名"))
    var model: String?

    func run() async throws {
        guard baseUrl != nil || model != nil else {
            print(Strings.get("config.no_changes"))
            return
        }

        let configManager = makeConfigManagerFromEnv()
        try configManager.updateProviderConfig(
            for: provider,
            baseURL: baseUrl,
            model: model
        )

        print(Strings.get("config.updated", provider))

        // 显示更新后的配置
        let config = try configManager.getProviderConfig(for: provider)
        printProviderConfig(provider: provider, config: config)
    }

    private func printProviderConfig(provider: String, config: ProviderConfig) {
        print("")
        print("[\(provider)]")
        if let baseURL = config.baseURL {
            print("  base_url: \(baseURL)")
        }
        if let model = config.model {
            print("  model: \(model)")
        }
    }
}

// MARK: - show

struct ShowConfigCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "show",
        abstract: HelpTextFactory.text(
            en: "Show provider configuration",
            cn: "查看 Provider 配置"
        ),
        discussion: helpDiscussion(
            en: """
                Display current configuration for a provider.

                OUTPUT FORMAT:
                  Config file: ~/.config/airis/config.json

                  [provider_name]
                    api_key: ✓ Configured / ✗ Not configured
                    base_url: https://...
                    model: model-name

                EXAMPLES:
                  # Show specific provider
                  airis gen config show --provider gemini

                  # Show all configured providers
                  airis gen config show

                SAMPLE OUTPUT:
                  [gemini]
                    api_key: ✓ Configured
                    base_url: https://generativelanguage.googleapis.com
                    model: gemini-3-pro-image-preview
                """,
            cn: """
                输出当前 Provider 配置与 API Key 配置状态。

                OUTPUT FORMAT:
                  配置文件：~/.config/airis/config.json

                  [provider_name]
                    api_key: ✓ 已配置 / ✗ 未配置
                    base_url: https://...
                    model: model-name

                EXAMPLES:
                  # 查看指定 provider
                  airis gen config show --provider gemini

                  # 查看全部 provider
                  airis gen config show
                """
        )
    )

    @Option(name: .long, help: HelpTextFactory.help(en: "Provider name (omit to show all)", cn: "Provider 名称（留空则显示全部）"))
    var provider: String?

    func run() async throws {
        let configManager = makeConfigManagerFromEnv()
        let keychain = KeychainManager()
        let appConfig = try configManager.loadConfig()

        print(Strings.get("config.file_location", configManager.getConfigFilePath()))

        // 显示默认 provider
        let defaultProvider = appConfig.defaultProvider ?? "gemini"
        print("\(Strings.get("config.default_provider")): \(defaultProvider)")
        print("")

        if let provider = provider {
            // 显示单个 provider
            try showProvider(provider, config: appConfig.providers[provider], keychain: keychain)
        } else {
            // 显示所有 provider
            for (name, config) in appConfig.providers.sorted(by: { $0.key < $1.key }) {
                try showProvider(name, config: config, keychain: keychain)
                print("")
            }
        }
    }

    private func showProvider(_ name: String, config: ProviderConfig?, keychain: KeychainManager) throws {
        print("[\(name)]")

        // API Key 状态
        let hasKey = keychain.hasAPIKey(for: name)
        let keyStatus = hasKey ? "✓ " + Strings.get("config.key_configured") : "✗ " + Strings.get("config.key_not_configured")
        print("  api_key: \(keyStatus)")

        // 配置信息
        if let config = config {
            if let baseURL = config.baseURL {
                print("  base_url: \(baseURL)")
            }
            if let model = config.model {
                print("  model: \(model)")
            }
        }
    }
}

// MARK: - reset

struct ResetConfigCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "reset",
        abstract: HelpTextFactory.text(
            en: "Reset provider configuration to defaults",
            cn: "重置 Provider 配置为默认值"
        ),
        discussion: helpDiscussion(
            en: """
                Reset provider settings to default values.
                Note: This does NOT delete the API key.

                Example:
                  airis gen config reset --provider gemini
                """,
            cn: """
                将 Provider 的 base_url / model 等配置恢复为默认值。
                注意：不会删除 API Key。

                EXAMPLES:
                  airis gen config reset --provider gemini
                """
        )
    )

    @Option(name: .long, help: HelpTextFactory.help(en: "Provider name", cn: "Provider 名称"))
    var provider: String

    func run() async throws {
        let configManager = makeConfigManagerFromEnv()
        try configManager.resetProviderConfig(for: provider)
        print(Strings.get("config.reset", provider))

        // 显示重置后的配置
        let config = try configManager.getProviderConfig(for: provider)
        print("")
        print("[\(provider)]")
        let forcePrint = ProcessInfo.processInfo.environment["AIRIS_FORCE_RESET_PRINT"] == "1"
        if let baseURL = config.baseURL ?? (forcePrint ? "forced-base" : nil) {
            print("  base_url: \(baseURL)")
        }
        if let model = config.model ?? (forcePrint ? "forced-model" : nil) {
            print("  model: \(model)")
        }
    }
}

// MARK: - set-default

struct SetDefaultCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "set-default",
        abstract: HelpTextFactory.text(
            en: "Set default provider",
            cn: "设置默认 Provider"
        ),
        discussion: helpDiscussion(
            en: """
                Set the default provider for image generation.
                When using 'airis gen draw', this provider will be used if --provider is not specified.

                EXAMPLES:
                  airis gen config set-default --provider gemini
                  airis gen config set-default --provider openai

                AVAILABLE PROVIDERS:
                  - gemini: Google Gemini (default)
                """,
            cn: """
                设置图像生成的默认 Provider。
                使用 'airis gen draw' 时，如果未指定 --provider，将使用此默认值。

                EXAMPLES:
                  airis gen config set-default --provider gemini
                  airis gen config set-default --provider openai

                可用 PROVIDERS:
                  - gemini: Google Gemini（默认）
                """
        )
    )

    @Option(name: .long, help: HelpTextFactory.help(en: "Provider name to set as default", cn: "设为默认的 Provider 名称"))
    var provider: String

    func run() async throws {
        let configManager = makeConfigManagerFromEnv()
        try configManager.setDefaultProvider(provider)
        print(Strings.get("config.default_set", provider))
    }
}
