# 🏗️ Airis 设计文档 (Design Document)

| 文档版本 | **v1.0** |
| :--- | :--- |
| **关联 PRD** | v1.5 (The Polyglot & Agent-Native Edition) |
| **目标平台** | macOS 15.0+ (Universal Binary: Intel & Apple Silicon) |
| **Swift 版本** | Swift 6.0+ |
| **更新日期** | 2025-12-08 |

---

## 1. 技术栈选型

### 1.1 核心依赖

| 组件 | 版本 | 用途 | 选型理由 |
|------|------|------|---------|
| **Swift** | 6.0+ | 系统编程语言 | • 原生性能<br>• 类型安全<br>• 完整并发支持（async/await, actors）<br>• 内存安全保证 |
| **swift-argument-parser** | 1.3.0+ | CLI 参数解析 | • Apple 官方维护<br>• 声明式 API<br>• 自动生成 help 信息<br>• 支持 subcommands 和 @OptionGroup |
| **Swift Package Manager** | 内置 | 依赖管理与构建 | • Swift 原生工具链<br>• 零配置依赖管理<br>• 跨平台构建支持 |

### 1.2 系统框架

| 框架 | 最低版本 | 用途 | 关键 API |
|------|---------|------|---------|
| **Vision** | macOS 15.0 | 视觉分析与检测 | • `VNImageRequestHandler`<br>• Swift-native API (无 VN 前缀)<br>• `CalculateImageAestheticsScoresRequest` |
| **CoreImage** | macOS 15.0 | 图像处理与滤镜 | • `CIFilter` 工厂方法<br>• `CIImage.autoAdjustmentFilters()`<br>• Metal 硬件加速 |
| **ImageIO** | macOS 15.0 | 图像编解码与元数据 | • `CGImageSource/CGImageDestination`<br>• 零拷贝元数据读写<br>• WebP 支持（macOS 11+） |
| **SensitiveContentAnalysis** | macOS 14.0 | 敏感内容检测 | • `SCSensitivityAnalyzer`<br>• 设备端 ML 模型<br>• 隐私优先设计 |
| **Foundation** | macOS 15.0 | 基础设施 | • `URLSession` (网络)<br>• `FileManager` (文件系统)<br>• `Locale` (国际化) |
| **Security** | macOS 15.0 | 凭证存储 | • `Keychain` API (SecItemAdd/SecItemCopyMatching) |

### 1.3 版本兼容性矩阵

| 功能 | macOS 最低版本 | 备注 |
|------|---------------|------|
| 基础 CLI 框架 | 15.0 | Swift 6 + ArgumentParser |
| Vision 基础分析 (tag, ocr, barcode, face) | 11.0 | 向后兼容 |
| Vision 高级分析 (pose, hand, flow) | 14.0 | Neural Engine 加速 |
| Vision 3D 姿态 (pose3d, petpose, persons) | 17.0 (iOS) / 14.0 (macOS) | 需要 A12+ 或 Apple Silicon |
| 美学评分 (score) | 15.0 | 新 Swift API |
| CoreImage 滤镜 | 15.0 | Metal 3 优化 |
| ImageIO WebP | 11.0 | 读写均支持 |
| SensitiveContentAnalysis | 14.0 | 需用户启用系统设置 |

---

## 2. 系统架构设计

### 2.1 整体架构

Airis 采用**三层架构**设计，CLI 层采用**二级子命令**组织：

```
┌──────────────────────────────────────────────────────────────┐
│                  CLI 层 (Presentation)                        │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  airis (Root Command)                                  │  │
│  │    ├── gen ──┬── draw                                  │  │
│  │    │         └── config                                │  │
│  │    ├── analyze ──┬── info, tag, score, ocr            │  │
│  │    │             └── safe, palette, similar, meta      │  │
│  │    ├── detect ──┬── barcode, face, animal             │  │
│  │    │            └── pose, pose3d, hand, pet-pose      │  │
│  │    ├── vision ──┬── flow, align                       │  │
│  │    │            └── saliency, persons                  │  │
│  │    └── edit ──┬── cut, resize, crop, enhance...       │  │
│  │               ├── filter ─── blur, sepia, comic...    │  │
│  │               └── adjust ─── color, exposure, flip... │  │
│  └────────────────────────────────────────────────────────┘  │
│         ↓ ArgumentParser (Subcommands + Options)             │
└──────────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────────┐
│                   业务层 (Business Logic)                     │
│  ┌─────────────────┬──────────────────┬──────────────────┐   │
│  │  Image Analysis │  Image Transform │  Generation      │   │
│  │   (Vision/CI)   │   (CoreImage)    │   (Gemini)       │   │
│  └─────────────────┴──────────────────┴──────────────────┘   │
│         ↓ async/await Concurrency Model                      │
└──────────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────────┐
│                  基础设施层 (Infrastructure)                  │
│  ┌──────────┬───────────┬──────────┬─────────────────────┐   │
│  │ Locales  │  Keychain │  Network │  Error Handling     │   │
│  └──────────┴───────────┴──────────┴─────────────────────┘   │
└──────────────────────────────────────────────────────────────┘
```

**新的命令层次结构**:
- **顶级命令**: 5 个 (`gen`, `analyze`, `detect`, `vision`, `edit`)
- **二级子命令**: 根据功能聚合
- **三级子命令**: `edit filter` 和 `edit adjust` 两个分组
- **常用别名**: 保留 10-15 个高频命令的顶级别名（如 `tag`, `face`, `enhance`）

### 2.2 目录结构

```
Airis/
├── Package.swift                    # SPM 清单
├── Sources/
│   └── Airis/
│       ├── main.swift               # 入口 (@main)
│       │
│       ├── Core/                    # 基础设施层
│       │   ├── Locales/
│       │   │   ├── Language.swift        # 语言检测与切换
│       │   │   └── Strings.swift         # 双语字符串表
│       │   │
│       │   ├── Network/
│       │   │   ├── HTTPClient.swift      # URLSession 封装
│       │   │   └── MultipartFormData.swift # Multipart 请求构建
│       │   │
│       │   ├── Security/
│       │   │   └── KeychainManager.swift # Keychain CRUD
│       │   │
│       │   └── Utils/
│       │       ├── FileUtils.swift       # 文件路径处理
│       │       └── ErrorTypes.swift      # 统一错误定义
│       │
│       ├── Domain/                  # 业务层 (领域模型)
│       │   ├── Models/
│       │   │   ├── ImageAnalysisResult.swift
│       │   │   ├── GenerationRequest.swift
│       │   │   └── TransformOptions.swift
│       │   │
│       │   ├── Providers/           # 生成服务抽象
│       │   │   ├── ImageProvider.swift    # Protocol
│       │   │   └── GeminiProvider.swift   # Gemini 实现
│       │   │
│       │   ├── Services/            # 核心服务
│       │   │   ├── VisionService.swift    # Vision 框架封装
│       │   │   ├── CoreImageService.swift # CoreImage 封装
│       │   │   ├── ImageIOService.swift   # ImageIO 封装
│       │   │   └── SensitiveContentService.swift
│       │   │
│       │   └── Algorithms/          # 算法实现
│       │       ├── PaletteExtractor.swift # 色彩提取
│       │       └── DefringeKernel.swift   # 去光晕算法
│       │
│       └── Commands/                # CLI 层 (命令定义)
│           ├── Root.swift           # 根命令 (@main struct)
│           │
│           ├── Gen/                 # gen 命令组
│           │   ├── GenCommand.swift      # gen 父命令
│           │   ├── DrawCommand.swift
│           │   └── ConfigCommand.swift
│           │
│           ├── Analyze/             # analyze 命令组
│           │   ├── AnalyzeCommand.swift  # analyze 父命令
│           │   ├── InfoCommand.swift
│           │   ├── TagCommand.swift
│           │   ├── ScoreCommand.swift
│           │   ├── OCRCommand.swift
│           │   ├── SafeCommand.swift
│           │   ├── PaletteCommand.swift
│           │   ├── SimilarCommand.swift
│           │   └── MetaCommand.swift
│           │
│           ├── Detect/              # detect 命令组
│           │   ├── DetectCommand.swift   # detect 父命令
│           │   ├── BarcodeCommand.swift
│           │   ├── FaceCommand.swift
│           │   ├── AnimalCommand.swift
│           │   ├── PoseCommand.swift
│           │   ├── Pose3DCommand.swift
│           │   ├── HandCommand.swift
│           │   └── PetPoseCommand.swift
│           │
│           ├── Vision/              # vision 命令组
│           │   ├── VisionCommand.swift   # vision 父命令
│           │   ├── FlowCommand.swift
│           │   ├── AlignCommand.swift
│           │   ├── SaliencyCommand.swift
│           │   └── PersonsCommand.swift
│           │
│           ├── Edit/                # edit 命令组
│           │   ├── EditCommand.swift     # edit 父命令
│           │   ├── CutCommand.swift
│           │   ├── ResizeCommand.swift
│           │   ├── CropCommand.swift
│           │   ├── EnhanceCommand.swift
│           │   ├── ScanCommand.swift
│           │   ├── StraightenCommand.swift
│           │   ├── TraceCommand.swift
│           │   ├── DefringeCommand.swift
│           │   ├── FormatCommand.swift
│           │   ├── ThumbCommand.swift
│           │   │
│           │   ├── Filter/          # edit filter 子组
│           │   │   ├── FilterCommand.swift   # filter 父命令
│           │   │   ├── BlurCommand.swift
│           │   │   ├── SharpenCommand.swift
│           │   │   ├── PixelCommand.swift
│           │   │   ├── NoiseCommand.swift
│           │   │   ├── ComicCommand.swift
│           │   │   ├── HalftoneCommand.swift
│           │   │   ├── SepiaCommand.swift
│           │   │   ├── MonoCommand.swift
│           │   │   ├── ChromeCommand.swift
│           │   │   ├── NoirCommand.swift
│           │   │   └── InstantCommand.swift
│           │   │
│           │   └── Adjust/          # edit adjust 子组
│           │       ├── AdjustCommand.swift   # adjust 父命令
│           │       ├── ColorCommand.swift
│           │       ├── ExposureCommand.swift
│           │       ├── TemperatureCommand.swift
│           │       ├── VignetteCommand.swift
│           │       ├── InvertCommand.swift
│           │       ├── PosterizeCommand.swift
│           │       ├── ThresholdCommand.swift
│           │       ├── FlipCommand.swift
│           │       └── RotateCommand.swift
│           │
│           └── Aliases/             # 常用命令别名
│               ├── TagAlias.swift        # tag -> analyze tag
│               ├── FaceAlias.swift       # face -> detect face
│               ├── EnhanceAlias.swift    # enhance -> edit enhance
│               ├── CutAlias.swift        # cut -> edit cut
│               └── ...
│
└── Tests/
    └── AirisTests/
        ├── LocalesTests.swift
        ├── VisionServiceTests.swift
        ├── CoreImageServiceTests.swift
        └── CommandTests/
            ├── AnalyzeCommandTests.swift
            ├── DetectCommandTests.swift
            └── EditCommandTests.swift
```

---

## 3. 核心设计模式

### 3.1 命令模式 (Command Pattern)

使用 `swift-argument-parser` 的声明式 API 实现**层次化子命令**：

```swift
// 根命令
@main
struct Airis: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "airis",
        abstract: "The AI-Native Messenger for Image Operations",
        version: "1.0.0",
        subcommands: [
            // 五大顶级命令组
            GenCommand.self,
            AnalyzeCommand.self,
            DetectCommand.self,
            VisionCommand.self,
            EditCommand.self,

            // 常用别名（hidden: true）
            TagAlias.self,
            FaceAlias.self,
            EnhanceAlias.self,
            CutAlias.self,
            ResizeAlias.self,
        ]
    )

    @OptionGroup var globalOptions: GlobalOptions

    mutating func validate() throws {
        // 全局语言设置
        Language.current = Language.resolve(explicit: globalOptions.lang)
    }
}

// 全局选项（所有子命令共享）
struct GlobalOptions: ParsableArguments {
    @Option(name: .long, help: "Output language (en/cn)")
    var lang: Language?

    @Flag(name: .long, help: "Enable verbose output")
    var verbose: Bool = false
}

// 示例：analyze 父命令
struct AnalyzeCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "analyze",
        abstract: "Analyze image properties and content",
        discussion: """
            Provides comprehensive image analysis including metadata, \
            content recognition, aesthetic scoring, and more.
            """,
        subcommands: [
            InfoCommand.self,
            TagCommand.self,
            ScoreCommand.self,
            OCRCommand.self,
            SafeCommand.self,
            PaletteCommand.self,
            SimilarCommand.self,
            MetaCommand.self
        ]
    )
}

// 示例：edit 父命令（三级结构）
struct EditCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "edit",
        abstract: "Edit and transform images",
        subcommands: [
            // 二级命令
            CutCommand.self,
            ResizeCommand.self,
            CropCommand.self,
            EnhanceCommand.self,
            ScanCommand.self,
            StraightenCommand.self,
            TraceCommand.self,
            DefringeCommand.self,
            FormatCommand.self,
            ThumbCommand.self,

            // 三级父命令
            FilterCommand.self,
            AdjustCommand.self
        ]
    )
}

// 示例：filter 父命令
struct FilterCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "filter",
        abstract: "Apply artistic filters and effects",
        subcommands: [
            BlurCommand.self,
            SharpenCommand.self,
            PixelCommand.self,
            NoiseCommand.self,
            ComicCommand.self,
            HalftoneCommand.self,
            SepiaCommand.self,
            MonoCommand.self,
            ChromeCommand.self,
            NoirCommand.self,
            InstantCommand.self
        ]
    )
}

// 示例：叶子命令实现
struct TagCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tag",
        abstract: "Recognize scenes and objects in images",
        discussion: """
            Uses Vision framework to classify image content and return \
            confidence-scored labels.
            """
    )

    @Argument(help: "Input image path", completion: .file())
    var inputPath: String

    @Option(name: .shortAndLong, help: "Minimum confidence threshold (0.0-1.0)")
    var threshold: Float = 0.5

    @Option(name: .shortAndLong, help: "Maximum number of tags to return")
    var limit: Int = 10

    func run() async throws {
        let service = ServiceContainer.shared.visionService
        let results = try await service.classifyImage(at: URL(fileURLWithPath: inputPath))

        let filtered = results
            .filter { $0.confidence >= threshold }
            .prefix(limit)

        for observation in filtered {
            print("\(observation.identifier): \(observation.confidence)")
        }
    }
}

// 别名实现（保持向后兼容）
struct TagAlias: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tag",
        shouldDisplay: false  // 不在 help 中显示
    )

    @Argument var inputPath: String
    @Option var threshold: Float = 0.5
    @Option var limit: Int = 10

    func run() async throws {
        // 直接调用实际命令
        var command = TagCommand()
        command.inputPath = inputPath
        command.threshold = threshold
        command.limit = limit
        try await command.run()
    }
}
```

### 3.2 服务定位模式 (Service Locator)

集中管理核心服务实例：

```swift
// 服务容器
final class ServiceContainer {
    static let shared = ServiceContainer()

    // 懒加载服务实例
    lazy var visionService = VisionService()
    lazy var coreImageService = CoreImageService()
    lazy var imageIOService = ImageIOService()
    lazy var sensitiveContentService = SensitiveContentService()
    lazy var geminiProvider = GeminiProvider(httpClient: httpClient)

    private lazy var httpClient = HTTPClient()

    private init() {}
}

// 使用示例
struct TagCommand: ParsableCommand {
    func run() async throws {
        let result = try await ServiceContainer.shared.visionService
            .classifyImage(at: inputPath)
        print(result)
    }
}
```

### 3.3 策略模式 (Strategy Pattern)

用于图像生成 Provider 的抽象：

**⚠️ 实际实现经验**（基于 Task 2.1）:

实际上我们采用了**通用实现**而非协议抽象，原因：
- Gemini 兼容的 API 端点众多（官方、代理、自建）
- 协议抽象增加复杂度但收益有限
- 配置文件可以灵活添加新端点

```swift
// ✅ 实际采用的设计：通用 Provider
final class GeminiProvider {
    private let providerName: String  // 运行时指定
    private let httpClient: HTTPClient
    private let keychainManager: KeychainManager
    private let configManager: ConfigManager

    init(providerName: String, ...) {
        self.providerName = providerName
        // ...
    }

    func generateImage(...) async throws -> URL {
        // 从配置读取该 provider 的设置
        let config = try configManager.getProviderConfig(for: providerName)
        let apiKey = try keychainManager.getAPIKey(for: providerName)

        // 构建端点
        let baseURL = config.baseURL ?? "https://generativelanguage.googleapis.com"
        let endpoint = "\(baseURL)/v1beta/models/\(model):generateContent"
        // ...
    }
}
```

**多 Provider 配置**:
```bash
# 添加官方 Gemini
airis gen config set-key --provider gemini --key "KEY"
airis gen config set --provider gemini --base-url "https://generativelanguage.googleapis.com"

# 添加自定义端点（如代理）
airis gen config set-key --provider custom --key "KEY"
airis gen config set --provider custom --base-url "https://proxy.example.com"

# 使用
airis gen draw "prompt" --provider custom
```

**端点结构规范**:
- `baseURL`: 只存储主机名（如 `https://api.example.com`）
- API 路径（如 `/v1beta`）硬编码在代码中
- 最终端点：`{baseURL}/v1beta/models/{model}:generateContent`

**未来扩展**:
如需支持完全不同的 API（DALL-E、Midjourney），可：
1. 创建对应的 Provider 类（DALLEProvider、MidjourneyProvider）
2. 在 DrawCommand 中根据 provider 选择实现

// 原有的协议示例（保留作为未来参考）
protocol ImageGenerationProvider {
    func generate(prompt: String, references: [URL], model: String) async throws -> URL
}
```

### 3.4 结果类型模式 (Result Type)

使用 Swift 原生 `Result<Success, Failure>` 处理可恢复错误：

```swift
enum AirisError: LocalizedError {
    case fileNotFound(String)
    case unsupportedFormat(String)
    case visionRequestFailed(String)
    case networkError(Error)
    case apiKeyNotFound

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return Strings.get("error.file_not_found", args: [path])
        case .unsupportedFormat(let format):
            return Strings.get("error.unsupported_format", args: [format])
        // ...
        }
    }
}

// 使用示例
func loadImage(at path: String) -> Result<CGImage, AirisError> {
    guard FileManager.default.fileExists(atPath: path) else {
        return .failure(.fileNotFound(path))
    }
    // ...
    return .success(cgImage)
}
```

---

## 4. 关键设计决策

### 4.1 并发模型：Swift Concurrency (async/await)

**决策**: 使用 Swift 原生并发模型，而非 GCD 或 OperationQueue。

**理由**:
- ✅ **结构化并发**: 自动管理任务生命周期，避免内存泄漏
- ✅ **类型安全**: 编译时检查数据竞争（Swift 6 严格并发检查）
- ✅ **Actor 隔离**: Vision/CoreImage 等框架天然支持 async API
- ✅ **取消传播**: Task cancellation 自动传递到子任务

**实现示例**:

```swift
final class VisionService {
    // 使用 actor 保护共享状态
    actor RequestCoordinator {
        private var activeRequests: Set<UUID> = []

        func registerRequest(_ id: UUID) {
            activeRequests.insert(id)
        }

        func completeRequest(_ id: UUID) {
            activeRequests.remove(id)
        }
    }

    private let coordinator = RequestCoordinator()

    func classifyImage(at url: URL) async throws -> [VNClassificationObservation] {
        let requestId = UUID()
        await coordinator.registerRequest(requestId)
        defer { Task { await coordinator.completeRequest(requestId) } }

        // Vision 请求执行
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(url: url, options: [:])

        try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([request])
                let results = request.results ?? []
                continuation.resume(returning: results)
            } catch {
                continuation.resume(throwing: AirisError.visionRequestFailed(error.localizedDescription))
            }
        }
    }
}
```

### 4.2 图像加载策略：延迟加载 + 内存管理

**决策**: 使用 `CGImageSource` 进行延迟解码，而非一次性加载全图。

**理由**:
- ✅ **内存效率**: 大图片（如 8K）只在需要时解码部分区域
- ✅ **元数据零拷贝**: `info` 和 `meta` 命令无需加载像素数据
- ✅ **硬件加速**: 自动利用 Image I/O 的硬件解码器

**实现示例**:

```swift
final class ImageIOService {
    func loadImageMetadata(at url: URL) throws -> [CFString: Any] {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw AirisError.fileNotFound(url.path)
        }

        // 零拷贝读取元数据
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            throw AirisError.unsupportedFormat(url.pathExtension)
        }

        return properties
    }

    func loadImage(at url: URL, maxDimension: Int? = nil) throws -> CGImage {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw AirisError.fileNotFound(url.path)
        }

        var options: [CFString: Any] = [
            kCGImageSourceShouldCache: false, // 延迟解码
            kCGImageSourceCreateThumbnailFromImageAlways: true
        ]

        if let maxDim = maxDimension {
            options[kCGImageSourceThumbnailMaxPixelSize] = maxDim
        }

        guard let image = CGImageSourceCreateImageAtIndex(source, 0, options as CFDictionary) else {
            throw AirisError.unsupportedFormat(url.pathExtension)
        }

        return image
    }
}
```

### 4.3 本地化架构：编译时字符串 + 运行时切换

**决策**: 使用自定义字符串表，而非 `.strings` 文件。

**理由**:
- ✅ **类型安全**: 编译时检查键名拼写错误
- ✅ **动态切换**: 支持 `--lang` 参数覆盖系统语言
- ✅ **Agent 友好**: 英文键名直接映射到语义

**实现示例**:

```swift
enum Language: String, ExpressibleByArgument, CaseIterable {
    case en, cn

    static var current: Language = .en

    static var fromSystem: Language {
        let preferred = Locale.preferredLanguages.first ?? "en"
        return preferred.hasPrefix("zh") ? .cn : .en
    }

    static var fromEnvironment: Language? {
        guard let env = ProcessInfo.processInfo.environment["AIRIS_LANG"],
              let lang = Language(rawValue: env.lowercased()) else {
            return nil
        }
        return lang
    }

    static func resolve(explicit: Language?) -> Language {
        explicit ?? fromEnvironment ?? fromSystem
    }
}

struct Strings {
    private static let dict: [String: [Language: String]] = [
        "error.file_not_found": [
            .en: "File not found: %@",
            .cn: "文件未找到：%@"
        ],
        "info.dimension": [
            .en: "Dimensions: %d × %d px",
            .cn: "尺寸：%d × %d 像素"
        ],
        "safe.disabled_hint": [
            .en: """
                ⚠️ Sensitive Content Analysis is disabled.
                Enable in: System Settings > Privacy & Security > Sensitive Content Warning
                """,
            .cn: """
                ⚠️ 敏感内容分析已禁用。
                启用路径：系统设置 > 隐私与安全性 > 敏感内容警告
                """
        ]
    ]

    static func get(_ key: String, args: [CVarArg] = []) -> String {
        let template = dict[key]?[Language.current] ?? key
        return args.isEmpty ? template : String(format: template, arguments: args)
    }
}
```

### 4.4 错误处理策略：分层错误 + 本地化消息

**决策**: 三层错误处理机制。

**层次结构**:
1. **框架层错误**: 捕获系统框架异常并转换为 `AirisError`
2. **业务层错误**: 定义领域特定错误（如 `InvalidImageDimension`）
3. **CLI 层错误**: 转换为用户友好的本地化消息

**实现示例**:

```swift
// 1. 统一错误类型
enum AirisError: LocalizedError {
    case fileNotFound(String)
    case unsupportedFormat(String)
    case visionRequestFailed(String)
    case networkError(Error)
    case apiKeyNotFound
    case invalidDimension(width: Int, height: Int, max: Int)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return Strings.get("error.file_not_found", args: [path])
        case .invalidDimension(let w, let h, let max):
            return Strings.get("error.invalid_dimension", args: [w, h, max])
        case .apiKeyNotFound:
            return Strings.get("error.api_key_not_found")
        default:
            return Strings.get("error.unknown")
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .apiKeyNotFound:
            return Strings.get("error.api_key_recovery")
        default:
            return nil
        }
    }
}

// 2. 命令层统一错误处理
extension ParsableCommand {
    func handleError(_ error: Error) {
        let message: String
        let recovery: String?

        if let airisError = error as? AirisError {
            message = airisError.errorDescription ?? "Unknown error"
            recovery = airisError.recoverySuggestion
        } else {
            message = error.localizedDescription
            recovery = nil
        }

        // 输出格式化错误
        print("❌ \(message)", to: &standardError)
        if let suggestion = recovery {
            print("💡 \(suggestion)", to: &standardError)
        }
    }
}
```

### 4.5 API Key 存储：macOS Keychain

**决策**: 使用系统 Keychain，而非明文配置文件。

**理由**:
- ✅ **安全**: 加密存储，需要用户授权访问
- ✅ **跨应用共享**: 可与其他工具共享凭证（通过相同 bundle ID）
- ✅ **原生集成**: 无需第三方依赖

**⚠️ CLI 工具特别注意**（基于实战经验）:

1. **使用文件型 Keychain，不用数据保护 Keychain**
   - 数据保护 Keychain 需要 `com.apple.application-identifier` entitlement
   - CLI 工具难以签名和配置 provisioning profile
   - 错误 -34018 (errSecMissingEntitlement) → 缺少 entitlements
   - 文件型 Keychain 同样安全，且无需额外配置

2. **必须设置的安全属性**
   ```swift
   kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock  // 必需
   kSecAttrSynchronizable: false  // API Key 不应同步到 iCloud
   ```

3. **使用 SecItemUpdate 优先策略**（而非删除+添加）
   - 避免竞态条件
   - 保留持久引用
   - 符合 Keychain 数据库特性

**参考文档**:
- Apple TN3137: On Mac keychains
- SecItem: Pitfalls and Best Practices (Apple Forums)

**实现示例**:

```swift
final class KeychainManager {
    private let service = "live.airis.cli"

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
            throw AirisError.apiKeyNotFound
        }

        return key
    }
}
```

---

## 5. 性能优化策略

### 5.1 Vision 框架优化

```swift
final class VisionService {
    // ✅ 复用 VNSequenceRequestHandler（用于视频/批量处理）
    private lazy var sequenceHandler = VNSequenceRequestHandler()

    // ✅ 启用 Neural Engine 加速
    func configureForegroundMaskRequest() -> VNGenerateForegroundInstanceMaskRequest {
        let request = VNGenerateForegroundInstanceMaskRequest()
        request.usesCPUOnly = false // 使用 Neural Engine
        return request
    }

    // ✅ 批量请求优化（一次执行多个 Vision 请求）
    func analyzeImage(url: URL) async throws -> ComprehensiveResult {
        let tagRequest = VNClassifyImageRequest()
        let faceRequest = VNDetectFaceLandmarksRequest()
        let barcodeRequest = VNDetectBarcodesRequest()

        let handler = VNImageRequestHandler(url: url, options: [:])

        // 并行执行多个请求
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try handler.perform([tagRequest])
            }
            group.addTask {
                try handler.perform([faceRequest])
            }
            group.addTask {
                try handler.perform([barcodeRequest])
            }
            try await group.waitForAll()
        }

        return ComprehensiveResult(
            tags: tagRequest.results ?? [],
            faces: faceRequest.results ?? [],
            barcodes: barcodeRequest.results ?? []
        )
    }
}
```

### 5.2 CoreImage 滤镜链优化

```swift
final class CoreImageService {
    // ✅ 复用 CIContext（昂贵的创建成本）
    private lazy var context: CIContext = {
        let options: [CIContextOption: Any] = [
            .useSoftwareRenderer: false, // 使用 Metal
            .cacheIntermediates: true,   // 缓存中间结果
            .workingColorSpace: CGColorSpace(name: CGColorSpace.displayP3)!
        ]
        return CIContext(options: options)
    }()

    // ✅ 延迟执行（滤镜链懒惰求值）
    func applyFilters(_ filters: [CIFilter], to image: CIImage) -> CIImage {
        filters.reduce(image) { currentImage, filter in
            filter.setValue(currentImage, forKey: kCIInputImageKey)
            return filter.outputImage ?? currentImage
        }
    }

    // ✅ 仅渲染需要的区域（避免全图渲染）
    func renderToFile(image: CIImage, url: URL, extent: CGRect? = nil) throws {
        let targetExtent = extent ?? image.extent
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        try context.writePNGRepresentation(
            of: image,
            to: url,
            format: .RGBA8,
            colorSpace: colorSpace,
            options: [:]
        )
    }
}
```

### 5.3 内存管理

```swift
// ✅ 使用 autoreleasepool 控制峰值内存（批量处理时）
func processBatch(urls: [URL]) async throws {
    for url in urls {
        try await withoutActuallyEscaping(url) { url in
            try await autoreleasepool {
                let image = try ImageIOService().loadImage(at: url)
                let result = try await VisionService().classifyImage(cgImage: image)
                print(result)
                // image 自动释放
            }
        }
    }
}
```

---

## 6. 测试策略

### 6.1 单元测试

```swift
import XCTest
@testable import Airis

final class LocalesTests: XCTestCase {
    func testLanguageResolution() {
        // 测试优先级：explicit > env > system
        XCTAssertEqual(Language.resolve(explicit: .en), .en)

        setenv("AIRIS_LANG", "cn", 1)
        XCTAssertEqual(Language.resolve(explicit: nil), .cn)
        unsetenv("AIRIS_LANG")
    }

    func testStringsInterpolation() {
        Language.current = .en
        XCTAssertEqual(
            Strings.get("error.file_not_found", args: ["/test.jpg"]),
            "File not found: /test.jpg"
        )

        Language.current = .cn
        XCTAssertEqual(
            Strings.get("error.file_not_found", args: ["/test.jpg"]),
            "文件未找到：/test.jpg"
        )
    }
}

final class VisionServiceTests: XCTestCase {
    func testClassifyImage() async throws {
        let bundle = Bundle(for: type(of: self))
        let url = bundle.url(forResource: "test_cat", withExtension: "jpg")!

        let service = VisionService()
        let results = try await service.classifyImage(at: url)

        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.contains { $0.identifier.contains("cat") })
    }
}
```

### 6.2 集成测试

```bash
#!/bin/bash
# Tests/IntegrationTests/test_commands.sh

# 测试 info 命令
airis info test.jpg | grep "Dimensions:"

# 测试 tag 命令
airis tag test_cat.jpg | grep "cat"

# 测试 similar 命令
distance=$(airis similar image1.jpg image2.jpg)
[ $distance -lt 0.5 ] || exit 1

# 测试 enhance 命令
airis enhance input.jpg -o output.jpg
[ -f output.jpg ] || exit 1
```

---

## 7. 构建与部署

### 7.1 Package.swift 配置

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Airis",
    platforms: [
        .macOS(.v15) // 要求 macOS 15.0+
    ],
    products: [
        .executable(name: "airis", targets: ["Airis"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser",
            from: "1.3.0"
        )
    ],
    targets: [
        .executableTarget(
            name: "Airis",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"), // Swift 6 严格并发
                .enableExperimentalFeature("AccessLevelOnImport")
            ]
        ),
        .testTarget(
            name: "AirisTests",
            dependencies: ["Airis"],
            resources: [
                .copy("Resources/test_images")
            ]
        )
    ]
)
```

### 7.2 构建命令

```bash
# 开发构建（带调试符号）
swift build -c debug

# 发布构建（优化 + Universal Binary）
swift build -c release \
    --arch arm64 --arch x86_64 \
    --disable-sandbox

# 运行测试
swift test

# 生成 Xcode 项目（可选）
swift package generate-xcodeproj
```

### 7.3 安装脚本

```bash
#!/bin/bash
# install.sh

set -e

echo "🚀 Building Airis..."
swift build -c release --arch arm64 --arch x86_64

echo "📦 Installing binary..."
sudo cp .build/apple/Products/Release/airis /usr/local/bin/

echo "✅ Airis installed successfully!"
echo "Run 'airis --help' to get started."
```

---

## 8. 未来扩展计划

### 8.1 MCP Server 集成

将 Airis 封装为 Model Context Protocol (MCP) Server，供 Claude Desktop 调用：

```json
// claude_desktop_config.json
{
  "mcpServers": {
    "airis": {
      "command": "/usr/local/bin/airis",
      "args": ["mcp-server"],
      "env": {
        "AIRIS_LANG": "en"
      }
    }
  }
}
```

### 8.2 插件系统

支持用户自定义滤镜和分析器：

```swift
// 插件协议
protocol AirisPlugin {
    var name: String { get }
    var version: String { get }
    func execute(input: CIImage, options: [String: Any]) throws -> CIImage
}

// 动态加载
class PluginManager {
    func loadPlugins(from directory: URL) throws -> [AirisPlugin] {
        // 使用 dlopen 加载 .dylib
    }
}
```

### 8.3 批量处理模式

```bash
# 批量处理目录下所有图片
airis batch enhance ./photos/*.jpg --output ./enhanced/

# 并行处理（利用多核）
airis batch resize ./images/*.png --width 1024 --jobs 8
```

---

## 9. 参考资料

### 9.1 Apple 官方文档
- [Vision Framework - Apple Developer](https://developer.apple.com/documentation/vision)
- [Core Image Programming Guide](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_intro/ci_intro.html)
- [Swift Concurrency - WWDC Videos](https://developer.apple.com/videos/play/wwdc2021/10132/)
- [ArgumentParser Documentation](https://swiftpackageindex.com/apple/swift-argument-parser/main/documentation/argumentparser)

### 9.2 技术规范
- [Swift Evolution Proposals](https://github.com/swiftlang/swift-evolution)
- [Swift Package Manager Specification](https://github.com/swiftlang/swift-package-manager/blob/main/Documentation/Usage.md)
- [Gemini API Reference](https://ai.google.dev/gemini-api/docs)

---

**文档状态**: ✅ 已完成
**审核者**: 待定
**最后更新**: 2025-12-08
