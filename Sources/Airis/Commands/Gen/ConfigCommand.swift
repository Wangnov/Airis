import ArgumentParser
import Foundation

struct ConfigCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "config",
        abstract: "Manage API keys and configuration",
        discussion: """
            Configure API keys and settings for AI providers.

            - API keys are stored securely in macOS Keychain
            - Other settings are stored in ~/.config/airis/config.json

            Supported providers: gemini
            """,
        subcommands: [
            SetKeyCommand.self,
            GetKeyCommand.self,
            DeleteKeyCommand.self,
            SetConfigCommand.self,
            ShowConfigCommand.self,
            ResetConfigCommand.self
        ]
    )
}

// MARK: - set-key

struct SetKeyCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "set-key",
        abstract: "Set API key for a provider",
        discussion: """
            Store an API key securely in macOS Keychain.

            Examples:
              airis gen config set-key --provider gemini --key "your-api-key"
              airis gen config set-key --provider gemini  # prompts for key
            """
    )

    @Option(name: .long, help: "Provider name (e.g., gemini)")
    var provider: String

    @Option(name: .long, help: "API key value (omit to enter interactively)")
    var key: String?

    func run() async throws {
        let apiKey: String
        if let providedKey = key {
            apiKey = providedKey
        } else {
            print(Strings.get("config.enter_key", provider), terminator: "")
            guard let input = readLine(strippingNewline: true), !input.isEmpty else {
                throw AirisError.invalidResponse
            }
            apiKey = input
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
        abstract: "Get API key for a provider (masked)",
        discussion: """
            Retrieve and display an API key (partially masked for security).

            Example:
              airis gen config get-key --provider gemini
            """
    )

    @Option(name: .long, help: "Provider name")
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
        abstract: "Delete API key for a provider",
        discussion: """
            Remove an API key from macOS Keychain.

            Example:
              airis gen config delete-key --provider gemini
            """
    )

    @Option(name: .long, help: "Provider name")
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
        abstract: "Set provider configuration",
        discussion: """
            Configure provider settings (stored in config file).

            Examples:
              airis gen config set --provider gemini --base-url "https://api.example.com"
              airis gen config set --provider gemini --model "gemini-2.0-flash"
            """
    )

    @Option(name: .long, help: "Provider name (e.g., gemini)")
    var provider: String

    @Option(name: .long, help: "API base URL")
    var baseUrl: String?

    @Option(name: .long, help: "Default model name")
    var model: String?

    func run() async throws {
        guard baseUrl != nil || model != nil else {
            print(Strings.get("config.no_changes"))
            return
        }

        let configManager = ConfigManager()
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
        abstract: "Show provider configuration",
        discussion: """
            Display current configuration for a provider.

            Examples:
              airis gen config show --provider gemini
              airis gen config show  # show all providers
            """
    )

    @Option(name: .long, help: "Provider name (omit to show all)")
    var provider: String?

    func run() async throws {
        let configManager = ConfigManager()
        let keychain = KeychainManager()
        let appConfig = try configManager.loadConfig()

        print(Strings.get("config.file_location", configManager.getConfigFilePath()))
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
        abstract: "Reset provider configuration to defaults",
        discussion: """
            Reset provider settings to default values.
            Note: This does NOT delete the API key.

            Example:
              airis gen config reset --provider gemini
            """
    )

    @Option(name: .long, help: "Provider name")
    var provider: String

    func run() async throws {
        let configManager = ConfigManager()
        try configManager.resetProviderConfig(for: provider)
        print(Strings.get("config.reset", provider))

        // 显示重置后的配置
        let config = try configManager.getProviderConfig(for: provider)
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
