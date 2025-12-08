# Task 2.1: gen 命令组实现

**状态**: ✅ 已完成
**优先级**: 🟡 P1 (独立模块，可并行)
**预估工作量**: 6-8 小时
**实际工作量**: ~6 小时
**前置条件**: Task 1.3 完成

---

## ⚠️ 开发前必读（避坑指南）

### 1. Keychain API 关键注意事项

**❌ 常见错误**:
```swift
// 错误：使用数据保护 Keychain 会报 -34018 错误
kSecUseDataProtectionKeychain: true  // ❌ CLI 工具不支持
```

**✅ 正确做法**:
```swift
// CLI 工具应使用文件型 Keychain
let query: [CFString: Any] = [
    kSecClass: kSecClassGenericPassword,
    kSecAttrService: service,
    kSecAttrAccount: provider,
    kSecValueData: data,
    kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,  // 必须设置
    kSecAttrSynchronizable: false  // API Key 不应同步
    // 不设置 kSecUseDataProtectionKeychain
]

// 使用 SecItemUpdate 优先策略（而非删除+添加）
let updateStatus = SecItemUpdate(query, attributes)
if updateStatus == errSecItemNotFound {
    SecItemAdd(addQuery, nil)
}
```

**参考**: Apple TN3137 - On Mac keychains

### 2. API 端点结构规范

**❌ 错误设计**:
```
baseURL = "https://api.example.com/v1beta"  // ❌ 包含路径
```

**✅ 正确设计**:
```
baseURL = "https://api.example.com"  // ✅ 只有主机名
代码中硬编码: "\(baseURL)/v1beta/models/\(model):generateContent"
```

### 3. Gemini 模型差异

| 特性 | gemini-2.5-flash-image | gemini-3-pro-image-preview |
|------|------------------------|----------------------------|
| 分辨率 | 固定 1024px | 1K/2K/4K 可选 |
| imageSize 参数 | ❌ 不支持（会报 400） | ✅ 支持 |
| aspectRatio 参数 | ✅ 支持 | ✅ 支持 |
| Google Search | ❌ 不支持 | ✅ 支持 |
| 参考图片 | 最多 3 张 | 最多 14 张 |
| 速度 | ~1.7 秒 | ~18 秒 |

### 4. JSON 编码差异

**请求体**（snake_case）:
```json
{"inline_data": {"mime_type": "...", "data": "..."}}
```

**响应体**（camelCase）:
```json
{"inlineData": {"mimeType": "...", "data": "..."}}
```

**解决方案**: 为请求和响应使用不同的 CodingKeys 映射。

### 5. Help 文档必需内容

每个命令必须包含：
- ✅ QUICK START（3 步上手）
- ✅ EXAMPLES（实际可运行）
- ✅ AVAILABLE SETTINGS（可配置项 + 默认值）
- ✅ TROUBLESHOOTING（常见错误）

目标：新 AI Agent 阅读 help 后能独立完成配置。

---

## 📋 目标

实现 `gen` 命令组的两个子命令：
- `gen draw`: AI 图像生成
- `gen config`: API Key 配置管理

包含 Keychain 存储和 Gemini Provider 基础实现。

---

## ✅ 任务清单

### 1. 实现 Keychain 管理器

- [ ] 创建 `Sources/Airis/Core/Security/KeychainManager.swift`：

```swift
import Foundation
import Security

final class KeychainManager {
    private let service = "live.airis.cli"

    /// 保存 API Key
    func saveAPIKey(_ key: String, for provider: String) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: provider,
            kSecValueData: key.data(using: .utf8)!
        ]

        // 删除旧值
        SecItemDelete(query as CFDictionary)

        // 插入新值
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw AirisError.keychainError(status)
        }
    }

    /// 获取 API Key
    func getAPIKey(for provider: String) throws -> String {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: provider,
            kSecReturnData: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            throw AirisError.apiKeyNotFound(provider: provider)
        }

        return key
    }

    /// 删除 API Key
    func deleteAPIKey(for provider: String) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: provider
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AirisError.keychainError(status)
        }
    }
}
```

### 2. 实现 HTTP 客户端

- [ ] 创建 `Sources/Airis/Core/Network/HTTPClient.swift`：

```swift
import Foundation

final class HTTPClient {
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }

    /// 发送 POST 请求
    func post(
        url: URL,
        headers: [String: String] = [:],
        body: Data
    ) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body

        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AirisError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AirisError.invalidResponse
        }

        return (data, httpResponse)
    }
}
```

### 3. 实现 Gemini Provider（基础版）

- [ ] 创建 `Sources/Airis/Domain/Providers/GeminiProvider.swift`：

```swift
import Foundation

final class GeminiProvider {
    private let httpClient: HTTPClient
    private let keychainManager: KeychainManager

    init(httpClient: HTTPClient = HTTPClient(), keychainManager: KeychainManager = KeychainManager()) {
        self.httpClient = httpClient
        self.keychainManager = keychainManager
    }

    /// 生成图像（占位实现）
    func generateImage(
        prompt: String,
        references: [URL] = [],
        model: String = "gemini-3-image-preview"
    ) async throws {
        // 获取 API Key
        let apiKey = try keychainManager.getAPIKey(for: "gemini")

        // 打印调试信息
        print("🌐 Connecting to Gemini Image API...")
        print("🔑 Model: \(model)")
        print("📝 Prompt: \(prompt)")

        if !references.isEmpty {
            print("🖼️ Processing \(references.count) reference images...")
        }

        // TODO: 实际 API 调用将在后续优化
        print("⚠️ Gemini Image API integration coming soon!")
        print("💡 For now, configure your API key and test the workflow.")
    }
}
```

### 4. 实现 config 命令

- [ ] 创建 `Sources/Airis/Commands/Gen/ConfigCommand.swift`：

```swift
import ArgumentParser
import Foundation

struct ConfigCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "config",
        abstract: "Manage API keys and configuration",
        subcommands: [
            SetKeyCommand.self,
            GetKeyCommand.self,
            DeleteKeyCommand.self
        ]
    )
}

// MARK: - set-key

struct SetKeyCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "set-key",
        abstract: "Set API key for a provider"
    )

    @Option(name: .long, help: "Provider name (e.g., gemini)")
    var provider: String

    @Option(name: .long, help: "API key value")
    var key: String?

    func run() async throws {
        let apiKey: String
        if let providedKey = key {
            apiKey = providedKey
        } else {
            // 从 stdin 读取（安全输入）
            print("Enter API key for \(provider): ", terminator: "")
            guard let input = readLine(strippingNewline: true), !input.isEmpty else {
                throw AirisError.invalidResponse
            }
            apiKey = input
        }

        let keychain = KeychainManager()
        try keychain.saveAPIKey(apiKey, for: provider)

        print("✅ API key saved for provider: \(provider)")
    }
}

// MARK: - get-key

struct GetKeyCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get-key",
        abstract: "Get API key for a provider (masked)"
    )

    @Option(name: .long, help: "Provider name")
    var provider: String

    func run() async throws {
        let keychain = KeychainManager()
        let key = try keychain.getAPIKey(for: provider)

        // 显示遮罩版本（只显示前4位和后4位）
        let masked = maskAPIKey(key)
        print("API key for \(provider): \(masked)")
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
        abstract: "Delete API key for a provider"
    )

    @Option(name: .long, help: "Provider name")
    var provider: String

    func run() async throws {
        let keychain = KeychainManager()
        try keychain.deleteAPIKey(for: provider)
        print("✅ API key deleted for provider: \(provider)")
    }
}
```

### 5. 实现 draw 命令

- [ ] 创建 `Sources/Airis/Commands/Gen/DrawCommand.swift`：

```swift
import ArgumentParser
import Foundation

struct DrawCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "draw",
        abstract: "Generate images using AI",
        discussion: """
            Generate images from text prompts, with optional reference images.

            Examples:
              airis gen draw "cyberpunk cat"
              airis gen draw "realistic photo" --ref sketch.jpg
              airis gen draw "mix two styles" --ref style1.jpg --ref style2.jpg
            """
    )

    @Argument(help: "Text description for image generation")
    var prompt: String

    @Option(name: .long, help: "Reference image path (can be used multiple times)")
    var ref: [String] = []

    @Option(name: .long, help: "Model version ID")
    var model: String = "gemini-3-image-preview"

    @Option(name: .long, help: "AI provider (default: gemini)")
    var provider: String = "gemini"

    func run() async throws {
        // 验证参考图片
        let refURLs = try ref.map { path in
            try FileUtils.validateFile(at: path)
        }

        // 调用 Provider
        let gemini = GeminiProvider()
        try await gemini.generateImage(
            prompt: prompt,
            references: refURLs,
            model: model
        )
    }
}
```

### 6. 更新 GenCommand 注册子命令

- [ ] 编辑 `Sources/Airis/Commands/Gen/GenCommand.swift`：

```swift
import ArgumentParser

struct GenCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "gen",
        abstract: "Generate images using AI providers",
        discussion: """
            Connect to AI image generation services like Gemini Image.
            Requires API key configuration.
            """,
        subcommands: [
            DrawCommand.self,
            ConfigCommand.self
        ]
    )
}
```

### 7. 测试命令

- [ ] 测试 config 命令：
  ```bash
  # 设置 API key
  swift run airis gen config set-key --provider gemini --key "test-key-123"

  # 获取 API key（遮罩显示）
  swift run airis gen config get-key --provider gemini

  # 删除 API key
  swift run airis gen config delete-key --provider gemini
  ```

- [ ] 测试 draw 命令：
  ```bash
  # 设置测试 API key
  swift run airis gen config set-key --provider gemini --key "test-key"

  # 测试生成（占位实现）
  swift run airis gen draw "cyberpunk cat"
  swift run airis gen draw "realistic photo" --ref test.jpg
  ```

---

## 🎯 验收标准

- ✅ `gen config set-key` 可成功保存 API key 到 Keychain
- ✅ `gen config get-key` 显示遮罩后的 API key
- ✅ `gen config delete-key` 可删除 API key
- ✅ `gen draw` 可读取 API key 并执行（即使是占位实现）
- ✅ `gen draw --ref` 可验证参考图片路径
- ✅ 所有错误有友好的本地化提示

---

## 📦 交付物

- `Core/Security/KeychainManager.swift`
- `Core/Network/HTTPClient.swift`
- `Domain/Providers/GeminiProvider.swift`
- `Commands/Gen/ConfigCommand.swift`
- `Commands/Gen/DrawCommand.swift`
- 更新的 `Commands/Gen/GenCommand.swift`

---

## 📝 注意事项

1. **Gemini API**: 此版本只实现占位功能，实际 API 调用后续优化
2. **安全性**: API Key 存储在 Keychain，不要硬编码
3. **参考图**: 当前只验证路径，实际 Base64 编码在后续实现

---

## 🔗 相关文档

- [DESIGN.md - Keychain 存储](../DESIGN.md#45-api-key-存储macos-keychain)
- [PRD.md - gen 模块](../PRD.md#21-模块-a-生成网关-generation--messenger)

---

## ⏭️ 下一步

完成此任务后，可以并行进行：
- **Task 3.1: Vision Service 基础设施**
- **Task 6.1: CoreImage Service 基础设施**
