# Airis 开发避坑指南

**基于 Task 1.1-2.1 的实际开发经验总结**

**创建日期**: 2025-12-08
**适用对象**: 后续开发 Agent 和开发者

---

## 🚨 关键避坑经验

### 1. macOS Keychain API（Task 2.1 踩坑）

#### ❌ 错误做法
```swift
let query: [CFString: Any] = [
    kSecClass: kSecClassGenericPassword,
    kSecAttrService: service,
    kSecAttrAccount: provider,
    kSecValueData: data,
    kSecUseDataProtectionKeychain: true  // ❌ CLI 工具会报错 -34018
]
```

#### ✅ 正确做法
```swift
// CLI 工具应该使用文件型 keychain，不需要 entitlements
let query: [CFString: Any] = [
    kSecClass: kSecClassGenericPassword,
    kSecAttrService: service,
    kSecAttrAccount: provider,
    kSecValueData: data,
    kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,  // 明确指定访问级别
    kSecAttrSynchronizable: false  // API Key 不应同步到 iCloud
]
```

#### 📝 经验教训
- **数据保护 Keychain 需要 entitlements**，CLI 工具难以配置
- **文件型 Keychain 同样安全**，且无需额外配置
- **使用 SecItemUpdate 而非删除+添加**（避免竞态条件）
- **必须设置 kSecAttrAccessible**（否则使用不可预测的默认值）

**参考**: Apple TN3137 - On Mac keychains

---

### 2. Gemini 模型差异（Task 2.1 踩坑）

#### ❌ 问题代码
```swift
// 两个模型使用相同的参数 - 错误！
let request = GeminiGenerateRequest(
    // ...
    generationConfig: GenerationConfig(
        imageConfig: ImageConfig(
            aspectRatio: aspectRatio,
            imageSize: imageSize  // ❌ Flash 模型不支持此参数
        )
    )
)
```

#### ✅ 正确做法
```swift
// 根据模型智能判断参数
let imageConfig: ImageConfig?
if actualModel.contains("2.5-flash") {
    // Flash: 只支持 aspectRatio，固定 1024px
    imageConfig = ImageConfig(aspectRatio: aspectRatio, imageSize: nil)
} else {
    // Pro: 支持 aspectRatio 和 imageSize (1K/2K/4K)
    imageConfig = ImageConfig(aspectRatio: aspectRatio, imageSize: imageSize)
}
```

#### 📝 经验教训
- **gemini-2.5-flash-image**: 固定 1024px，只支持 aspectRatio
- **gemini-3-pro-image-preview**: 支持 1K/2K/4K + aspectRatio
- **必须阅读官方文档**，不要假设 API 一致性
- **添加模型特性检测逻辑**

---

### 3. API 端点结构设计（Task 2.1 踩坑）

#### ❌ 错误设计
```swift
// 任务文档中的示例
let baseURL = "https://generativelanguage.googleapis.com/v1beta"  // ❌ 包含 /v1beta
let endpoint = "\(baseURL)/models/\(model):generateContent"
```

#### ✅ 正确设计
```swift
// baseURL 只存主机名，/v1beta 硬编码在代码中
let baseURL = "https://generativelanguage.googleapis.com"  // ✅ 只有主机名
let endpoint = "\(baseURL)/v1beta/models/\(model):generateContent"  // ✅ /v1beta 固定
```

#### 📝 经验教训
- **/v1beta 是 API 版本，应该硬编码**
- **baseURL 应该只存主机名**（便于代理和自定义端点）
- **配置文件中的 base_url 不应包含路径**
- **设计文档需要明确说明端点结构**

---

### 4. JSON 编码命名差异（Task 2.1 踩坑）

#### ❌ 错误假设
```swift
// 假设响应和请求使用相同的命名规则 - 错误！
struct Part: Codable {
    let inlineData: InlineData?

    enum CodingKeys: String, CodingKey {
        case inlineData = "inline_data"  // ❌ 响应实际是 camelCase
    }
}
```

#### ✅ 正确做法
```swift
// 请求模型：使用 snake_case
struct RequestPart: Codable {
    let inlineData: InlineData?
    enum CodingKeys: String, CodingKey {
        case inlineData = "inline_data"  // ✅ 请求用 snake_case
    }
}

// 响应模型：使用 camelCase
struct ResponsePart: Codable {
    let inlineData: InlineData?
    enum CodingKeys: String, CodingKey {
        case inlineData  // ✅ 响应用 camelCase（不映射）
    }
}
```

#### 📝 经验教训
- **请求和响应的命名规则可能不同**
- **必须用 curl 实际测试响应格式**
- **添加调试日志打印原始 JSON**
- **不要假设 API 的一致性**

---

### 5. Help 文档的重要性（Task 2.1 重大发现）

#### ❌ 任务文档中的缺失
- 只提到"帮助信息检查"
- 没有强调 help 对 AI Agent 的重要性
- 缺少 QUICK START 和 TROUBLESHOOTING 指导

#### ✅ 实际需要
```
OVERVIEW: 命令描述

QUICK START:
  1. 获取 API Key
  2. 配置命令
  3. 使用示例

AVAILABLE SETTINGS:
  列出所有可配置项和默认值

EXAMPLES:
  多个实际可运行的示例

TROUBLESHOOTING:
  常见错误和解决方案
```

#### 📝 经验教训
- **Help 文档评分提升：5.5/10 → 9.5/10**
- **新 AI Agent 必须能从 help 独立完成配置**
- **每个子命令都需要详细的 discussion**
- **QUICK START 是必需的，不是可选的**
- **要包含完整的配置项列表和默认值**

---

### 6. 多 Provider 架构设计（Task 2.1 改进）

#### ❌ 原始设计
```swift
// 硬编码 provider 名称
final class GeminiProvider {
    static let providerName = "gemini"  // ❌ 无法扩展
}
```

#### ✅ 改进设计
```swift
// 通用实现，支持任意 provider
final class GeminiProvider {
    private let providerName: String  // ✅ 运行时指定

    init(providerName: String, ...) {
        self.providerName = providerName
    }
}
```

#### 📝 经验教训
- **从一开始就设计为通用实现**
- **避免硬编码 provider 列表**
- **使用配置文件的 defaultProvider**
- **优先级：命令行 > 配置文件 > 硬编码默认**

---

### 7. HTTP 重试机制（Task 2.1 最佳实践）

#### ✅ 应该实现的功能
```swift
// 区分可重试和不可重试的错误
switch httpResponse.statusCode {
case 200...299:
    // 成功
case 500...599:
    // 5xx 服务器错误 - 可重试
    if retryCount < maxRetries {
        try await Task.sleep(...)
        return try await post(..., retryCount: retryCount + 1)
    }
case 400...499:
    // 4xx 客户端错误 - 不重试
}

// 网络错误也应重试
let retryableCodes: Set<Int> = [
    NSURLErrorTimedOut,
    NSURLErrorNetworkConnectionLost,
    NSURLErrorNotConnectedToInternet,
    NSURLErrorDNSLookupFailed
]
```

#### 📝 经验教训
- **POST 请求不会自动重试**（与 GET 不同）
- **必须实现应用层重试机制**
- **指数退避策略很重要**
- **区分 4xx（不重试）和 5xx（可重试）**
- **添加 Task.checkCancellation() 支持取消**

---

### 8. 用户体验细节（Task 2.1 发现）

#### ✅ 应该添加的功能
1. **参数总览**：生成前显示所有参数
2. **实际分辨率**：16:9 2K = 2752×1536
3. **参考图片列表**：显示文件名和序号
4. **进度指示**：清晰的阶段提示
5. **自动打开**：--open 和 --reveal 选项

#### 📝 经验教训
- **参数显示是必需功能，不是锦上添花**
- **用户应该清楚知道"发生了什么"**
- **emoji 可以提升可读性**（适度使用）
- **--open/--reveal 是高频需求**

---

### 9. 测试策略（Task 1.1-2.1 总结）

#### ✅ 测试最佳实践
```swift
// 1. 独立的 tearDown 清理
override func tearDown() {
    super.tearDown()
    try? keychain.deleteAPIKey(for: testProvider)
    try? FileManager.default.removeItem(at: tempConfigFile)
}

// 2. 使用唯一的测试标识
let testProvider = "test-provider-\(UUID().uuidString)"

// 3. 配置文件隔离
rm -rf ~/.config/airis  // 测试前清理
```

#### 📝 经验教训
- **测试应该能重复运行**（清理很重要）
- **避免测试污染真实配置文件**
- **使用临时文件和唯一标识**
- **ConfigManager 的测试最容易出问题**（需要清理）

---

## 📄 设计文档建议修改

### DESIGN.md 需要补充的内容

#### 1. **4.5 节 - API Key 存储**
```markdown
## 4.5 API Key 存储 (macOS Keychain)

⚠️ **CLI 工具特别注意**:
- 使用文件型 Keychain（不设置 kSecUseDataProtectionKeychain）
- 数据保护 Keychain 需要 entitlements，CLI 工具难以配置
- 使用 SecItemUpdate 优先策略（而非删除+添加）
- 必须设置 kSecAttrAccessible 和 kSecAttrSynchronizable

参考：Apple TN3137 - On Mac keychains
```

#### 2. **2.5 节 - Provider 架构**
```markdown
## 2.5 Provider 架构设计

### 多 Provider 支持
- GeminiProvider 应设计为通用实现（接受 providerName 参数）
- 避免硬编码 provider 列表
- baseURL 只存主机名，API 路径（如 /v1beta）硬编码在代码中

### 配置优先级
命令行参数 > config.defaultProvider > "gemini"
```

#### 3. **3.2 节 - Help 文档标准**
```markdown
## 3.2 Help 文档编写标准

每个命令的 discussion 必须包含：
1. QUICK START（3 步上手）
2. EXAMPLES（实际可运行的示例）
3. AVAILABLE SETTINGS（可配置项列表 + 默认值）
4. OUTPUT FORMAT（输出格式示例）
5. TROUBLESHOOTING（常见错误和解决方案）

目标：新 AI Agent 必须能从 help 独立完成配置和使用。
```

---

## 📋 任务文档建议修改

### TASK-2.1-Gen-Commands.md 需要补充

#### 1. **API 端点结构说明**
```markdown
## ⚠️ 重要：API 端点结构

- baseURL 只存储主机名（如 https://api.example.com）
- /v1beta 路径应硬编码在 GeminiProvider 中
- 最终端点：{baseURL}/v1beta/models/{model}:generateContent

错误示例：baseURL = "https://api.example.com/v1beta"  ❌
正确示例：baseURL = "https://api.example.com"  ✅
```

#### 2. **模型差异说明**
```markdown
## ⚠️ 模型参数差异

gemini-2.5-flash-image:
  - 固定 1024px 分辨率
  - 只支持 aspectRatio 参数
  - imageSize 参数会导致 400 错误

gemini-3-pro-image-preview:
  - 支持 1K/2K/4K 分辨率
  - 同时支持 aspectRatio 和 imageSize
  - 支持 Google Search 工具
```

#### 3. **响应格式注意事项**
```markdown
## ⚠️ JSON 编码差异

请求体使用 snake_case:
  inline_data, mime_type, response_modalities

响应体使用 camelCase:
  inlineData, mimeType, responseModalities

解决方案：
- 为请求和响应创建独立的模型
- 正确设置 CodingKeys 映射
- 用 curl 实际测试响应格式
```

#### 4. **Help 文档要求**
```markdown
## ✅ Help 文档检查清单

ConfigCommand 必须包含：
- [ ] QUICK START（完整的配置流程）
- [ ] AVAILABLE SETTINGS（可配置项列表）
- [ ] 每个设置项的默认值
- [ ] STORAGE（配置存储位置说明）
- [ ] SAMPLE OUTPUT（输出格式示例）

DrawCommand 必须包含：
- [ ] 模型对比（2.5 Flash vs 3 Pro）
- [ ] 完整的 aspect ratio 和分辨率说明
- [ ] 提示词策略和模板（摄影/插画/文字/产品）
- [ ] 使用场景指南（社交媒体/壁纸/海报）
- [ ] BEST PRACTICES（Gemini 官方推荐）

目标：新 AI Agent 阅读 help 后能独立完成所有操作
```

#### 5. **用户体验要求**
```markdown
## ✅ 参数显示标准

生成前必须显示：
- Provider 名称
- 模型名称
- 提示词
- 纵横比 + 实际像素分辨率
- 参考图片列表（序号 + 文件名）
- 输出路径
- Google Search 状态
- 后续操作（--open/--reveal）

示例输出：
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎨 图像生成参数
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🏢 Provider: duckcoding
💾 输出: output.png
👁️  完成后: 在 Finder 中显示
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔑 模型: gemini-3-pro-image-preview
📝 提示词: ...
📐 纵横比: 16:9
📏 分辨率: 2K (2752×1536)
🖼️  参考图片: 2 张
   [1] image1.png
   [2] image2.png
```

---

### TASK-1.2-Core-Infrastructure.md 需要补充

#### 补充 Keychain 注意事项
```markdown
## ⚠️ Keychain 实现注意事项

macOS CLI 工具的 Keychain 使用：
1. 不使用 kSecUseDataProtectionKeychain（需要 entitlements）
2. 必须设置 kSecAttrAccessible（推荐 kSecAttrAccessibleAfterFirstUnlock）
3. 必须设置 kSecAttrSynchronizable: false（API Key 不应同步）
4. 使用 SecItemUpdate 优先策略（而非删除+添加）

错误 -34018 (errSecMissingEntitlement)：
  → 尝试使用数据保护 Keychain 但缺少 entitlements
  → 解决：移除 kSecUseDataProtectionKeychain
```

---

## 🛠️ 通用开发建议

### 1. 知识获取策略

**顺序很重要**：
1. **先查询官方文档**（Context7 + apple-docs-explorer）
2. **实际 curl 测试 API**（验证格式和行为）
3. **添加调试输出**（打印原始 JSON）
4. **边开发边写测试**
5. **开发完成后补充 help**

### 2. 错误处理最佳实践

```swift
// ✅ 提供详细的错误信息和恢复建议
throw AirisError.apiKeyNotFound(provider: provider)
// 自动显示：
// Error: API key not found for provider: gemini
// Run 'airis gen config set-key --provider gemini' to configure
```

### 3. HTTPClient 必需功能

- ✅ 超时配置（request: 60s, resource: 600s）
- ✅ waitsForConnectivity
- ✅ 自动重试机制（5xx 和网络错误）
- ✅ 指数退避策略
- ✅ Task 取消检查
- ✅ 详细的错误信息

### 4. 测试编写原则

```swift
// ✅ 每个测试独立
override func tearDown() {
    super.tearDown()
    // 清理所有测试数据
    try? keychain.deleteAPIKey(for: testProvider)
    try? FileManager.default.removeItem(at: tempFile)
}

// ✅ 使用唯一标识
let testProvider = "test-\(UUID().uuidString)"

// ✅ 测试前清理配置
rm -rf ~/.config/airis
```

---

## 📊 实际工时 vs 预估工时

| Task | 预估 | 实际 | 差异 | 原因 |
|------|------|------|------|------|
| 1.1 | 2-4h | ~1h | -50% | 相对简单 |
| 1.2 | 4-6h | ~2h | -60% | 代码简单，查询快 |
| 1.3 | 3-5h | ~1h | -70% | 只是空壳命令 |
| 2.1 | 6-8h | ~6h | 准确 | 包含完整实现 + 最佳实践改进 + Help 优化 |

**预估基本准确**，但前 3 个任务可以更快完成。

---

## 🎯 后续任务建议

### Task 3.1 (Vision Service) 注意事项

预计会遇到的问题：
1. **Vision 框架的 async/await 支持**（需要查询官方文档）
2. **VNImageRequestHandler 的使用方式**
3. **结果解析和格式化**
4. **错误处理**（Vision 特定错误）

建议：
- 先用 apple-docs-explorer 查询 Vision 框架完整 API
- 创建通用的 VisionService 基类
- 为不同类型的请求创建统一接口
- 添加详细的进度输出

### Task 3.2-3.3 (analyze 命令) 注意事项

预计工作量：
- 每个命令约 1-2 小时（如果 VisionService 设计良好）
- Help 文档编写约 30 分钟/命令
- 测试编写约 30 分钟/命令

建议：
- 复用 VisionService 的通用逻辑
- 为输出格式创建统一的格式化工具
- 支持 JSON 和 人类可读 两种输出格式

---

## 📚 文档模板改进

### 未来任务文档应包含的章节

```markdown
# Task X.X: 任务名称

## ⚠️ 开发前必读

### API 特性差异
（列出不同 API 版本/模型的差异）

### 已知坑点
（基于前序任务的经验）

### 端点结构
（明确 baseURL vs 固定路径）

## ✅ 任务清单

### X. 实现核心功能
（代码实现）

### X. Help 文档要求
- [ ] QUICK START
- [ ] EXAMPLES（至少 3 个）
- [ ] AVAILABLE OPTIONS（列出所有选项 + 默认值）
- [ ] TROUBLESHOOTING

### X. 用户体验要求
- [ ] 参数显示总览
- [ ] 进度指示
- [ ] 详细的错误信息

### X. 测试要求
- [ ] 单元测试（覆盖主要功能）
- [ ] 边界测试（错误情况）
- [ ] 清理测试（tearDown）

## 🎯 验收标准

除了功能验收，还应包括：
- [ ] Help 文档完整性（新 AI Agent 能否独立使用）
- [ ] 错误信息友好性（是否提供恢复建议）
- [ ] 参数显示完整性
- [ ] 测试可重复运行
```

---

## 🔑 关键经验总结

### TOP 10 避坑指南

1. **Keychain**: CLI 工具用文件型，不用数据保护型
2. **端点结构**: baseURL = 主机名，API 路径硬编码
3. **模型差异**: Flash vs Pro 参数不同，需智能判断
4. **JSON 编码**: 请求 snake_case，响应 camelCase
5. **Help 文档**: 必须包含 QUICK START 和 TROUBLESHOOTING
6. **多 Provider**: 从一开始设计为通用实现
7. **HTTP 重试**: 必须实现应用层重试，区分 4xx/5xx
8. **用户体验**: 参数总览是必需的，不是可选的
9. **测试清理**: tearDown 必须清理所有测试数据
10. **官方文档**: 永远先查询，不要假设

### 开发效率提升建议

1. **使用 apple-docs-explorer 和 Context7**（节省 50% 查询时间）
2. **curl 先测试 API**（避免猜测响应格式）
3. **边开发边写测试**（避免后期补测试）
4. **边开发边写 help**（避免遗忘细节）
5. **添加调试输出**（快速定位问题）

---

**结论**: 设计文档整体良好，但需要补充实战经验和避坑指南。建议创建独立的 `PITFALLS.md` 文档记录这些内容。
