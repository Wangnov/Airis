# Airis 项目记忆文档

## 项目概览

**Airis** - AI 驱动的图像处理 CLI 工具

- **命令数量**: 51 个
- **测试数量**: 640 tests
- **覆盖率**: 85%
- **语言**: Swift 5.10+
- **平台**: macOS 14.0+

---

## git 提交规范

遵循 Conventional Commits 规范，包含简略的 scope。

**类型**:
- `feat(module)`: 新功能
- `fix(module)`: Bug 修复
- `perf(module)`: 性能优化
- `test(module)`: 测试相关
- `docs`: 文档更新
- `build`: 构建系统
- `refactor`: 重构

**示例**:
```bash
git commit -m "feat(analyze): 添加美学评分命令"
git commit -m "fix(vision): 移除强制解包"
git commit -m "perf(tests): 并行化性能测试"
```

---

## 快速命令（Makefile）

### 日常开发

```bash
# 快速测试（推荐）- 75秒，跳过性能测试
make test-quick

# 编译 debug
make build

# 开发模式：快速测试 + 编译
make dev
```

### 完整验证

```bash
# 完整测试 - 101秒，包含性能基准
make test

# 编译 release
make release

# 安装到 ~/.local/bin
make install
```

### 测试选项

```bash
make test-quick       # 快速测试（75s，跳过性能）⚡
make test             # 完整测试（101s，640 tests）
make test-perf        # 仅性能测试
make test-unit        # 仅单元测试
make test-integration # 仅集成测试
```

### 工具命令

```bash
make clean            # 清理构建产物
make format           # 格式化代码（需要 swiftformat）
make lint             # 代码检查（需要 swiftlint）
make help             # 显示帮助
```

---

## 项目架构要点

### 分层架构

```
Sources/Airis/
├── Commands/          # 命令层（ArgumentParser）
│   ├── Gen/          # AI 图像生成
│   ├── Analyze/      # 图像分析
│   ├── Detect/       # 对象检测
│   ├── Vision/       # 高级视觉
│   └── Edit/         # 图像编辑
├── Domain/           # 业务逻辑层
│   ├── Services/     # 服务（VisionService, CoreImageService, ImageIOService）
│   ├── Providers/    # AI Provider（GeminiProvider）
│   └── Models/       # 数据模型
└── Core/             # 核心基础设施
    ├── Locales/      # 双语本地化
    ├── Security/     # Keychain 管理
    ├── Network/      # HTTP 客户端
    └── Utils/        # 工具类
```

### 服务单例（ServiceContainer）

```swift
// 访问服务
let vision = ServiceContainer.shared.visionService
let coreImage = ServiceContainer.shared.coreImageService
let imageIO = ServiceContainer.shared.imageIOService
```

---

## 并行开发工作流（Worktree）

### 创建并行任务

```bash
# 1. 创建 worktrees
cd ~/Airis
git worktree add ~/Airis/worktrees/task-X.Y-name -b feature/task-X.Y

# 2. 查看所有 worktrees
git worktree list

# 3. 副 Agent 在 worktree 中开发
cd ~/Airis/worktrees/task-X.Y-name
swift build
swift test

# 4. 提交
git add .
git commit -m "feat(module): 实现 Task X.Y"
```

### 主 Agent 验收合并

```bash
cd ~/Airis

# 1. 验收
cd ~/Airis/worktrees/task-X.Y-name
swift test  # 必须通过

# 2. 合并
cd ~/Airis
git merge --no-ff feature/task-X.Y -m "Merge Task X.Y: 描述"

# 3. 验证
swift test --parallel

# 4. 清理
git worktree remove ~/Airis/worktrees/task-X.Y-name
git branch -d feature/task-X.Y
```

### 测试资产规范

```bash
# 测试资产位置
~/Airis/worktrees/test-assets/task-X.Y/

# ⚠️ 重要：生成测试资产使用主仓库的稳定版
~/.local/bin/airis gen draw "prompt" -o ~/Airis/worktrees/test-assets/task-X.Y/test.png

# ❌ 不要使用 worktree 中的开发版
.build/debug/airis gen draw "prompt"  # 可能不稳定
```

---

## Apple 框架最佳实践

### Vision 框架

```swift
// ✅ 使用 @preconcurrency 处理 Swift 6 警告
@preconcurrency import Vision

// ✅ 异步调用（自动在后台线程）
let results = try await visionService.classifyImage(at: url)

// ✅ 批量请求
let analysis = try await visionService.performMultipleRequests(at: url)
```

### CoreImage 框架

```swift
// ✅ CIContext 全局复用（关键！）
let context = CIContext(mtlDevice: device)  // 只创建一次

// ❌ 不要每次创建
func process() {
    let context = CIContext()  // 性能灾难
}

// ✅ Metal 加速优先
if let device = MTLCreateSystemDefaultDevice() {
    context = CIContext(mtlDevice: device)
}
```

### Keychain (Security)

```swift
// ✅ 推荐：使用 Data Protection Keychain
var query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecUseDataProtectionKeychain as String: true,
    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
]

// ⚠️ CLI 工具需要代码签名才能使用 Data Protection Keychain
```

### SensitiveContentAnalysis

```swift
// ⚠️ 需要 entitlements（已添加到 Airis.entitlements）
// com.apple.developer.sensitivecontentanalysis.client

// ⚠️ 需要付费 Apple Developer Program 签名
// ⚠️ 用户需启用系统设置 > 敏感内容警告
```

---

## 测试最佳实践

### 类级别 setUp（Apple 推荐）

```swift
final class MyTests: XCTestCase {
    // ✅ 类级别：共享昂贵资源
    nonisolated(unsafe) static let sharedService = VisionService()
    static var cachedImage: CGImage?

    override class func setUp() {
        super.setUp()
        // 只执行一次，节省时间
        cachedImage = try? ImageIOService().loadImage(at: testURL)
    }

    // 实例级别：使用共享资源
    var service: VisionService!

    override func setUp() {
        super.setUp()
        service = Self.sharedService  // 快速
    }
}
```

### 性能测试

```swift
// ✅ 减少迭代次数（快速反馈）
let options = XCTMeasureOptions()
options.iterationCount = 3  // 从默认 10 次优化

measure(metrics: [XCTCPUMetric()], options: options) {
    // 被测代码
}

// ✅ 预热首次调用
_ = try? await service.someOperation()
measure { /* ... */ }
```

### 测试隔离

```swift
// ✅ 使用临时文件避免污染用户配置
let tempFile = FileManager.default.temporaryDirectory
    .appendingPathComponent("test_config_\(UUID()).json")
let manager = ConfigManager(configFile: tempFile)

// tearDown 清理
try? FileManager.default.removeItem(at: tempFile)
```

---

## 代码质量标准

### 错误处理

```swift
// ✅ 使用统一错误类型
throw AirisError.fileNotFound(path)

// ✅ 支持本地化
var errorDescription: String? {
    case .fileNotFound(let path):
        return Strings.get("error.file_not_found", path)
}

// ❌ 避免强制解包
let image = CIImage(contentsOf: url)!  // 危险

// ✅ 使用 guard let
guard let image = CIImage(contentsOf: url) else {
    throw AirisError.imageDecodeFailed
}
```

### 并发安全

```swift
// ✅ 服务类标记为 Sendable
final class VisionService: Sendable { }

// ✅ ServiceContainer 使用 let（不用 lazy var）
final class ServiceContainer: Sendable {
    static let shared = ServiceContainer()
    let visionService = VisionService()  // 线程安全
}

// ❌ 避免
lazy var visionService = VisionService()  // 非线程安全
```

### 本地化

```swift
// ✅ 所有用户可见字符串使用 Strings.get()
print(Strings.get("error.file_not_found", filename))

// ❌ 避免硬编码
print("文件未找到: \(filename)")  // 无法切换语言
```

### SwiftLint 常见问题（避坑指南）

**运行检查**: `make lint` 或 `swiftlint`

#### Force Unwrapping（必须避免）

```swift
// ❌ 源代码绝不使用
let image = CIImage(contentsOf: url)!
if x != nil { count += x!.value }

// ✅ 使用 if let / guard let
if let x = x { count += x.value }
guard let image = CIImage(contentsOf: url) else { throw ... }

// ✅ 测试用 XCTUnwrap
func test() throws {
    let url = try XCTUnwrap(testImageURL)
}

// ⚠️ measure 闭包不支持 throws，需在外部解包
func testPerf() throws {
    let img = try XCTUnwrap(testCIImage)
    measure { _ = process(img) }
}
```

#### Cyclomatic Complexity（已全局禁用）

CLI 项目的命令 `run()` 函数和枚举映射函数复杂度高是正常的，已在 `.swiftlint.yml` 中禁用此规则。

#### Empty Count

```swift
// ❌ 无意义断言
XCTAssertTrue(array.count >= 0)  // 永远为 true

// ✅ 删除或改为
XCTAssertNotNil(array)
```

#### Identifier Name

单字符变量需加入白名单（已配置）：`r,g,b,w,h,x,y,z,i,v,ev`

#### Line Length

CLI 项目设为 150 字符（不是默认的 120）。超长行拆分为局部变量：
```swift
// 前: print("\(String(format: ...)), \(String(format: ...)), ...")
// 后: let x = String(format: ...); print("\(x), \(y), ...")
```

#### Prefer For-Where

```swift
// ❌ 不推荐
for item in items { if condition { ... } }

// ✅ 推荐
for item in items where condition { ... }
```

---

## 已知问题和注意事项

### 测试资产依赖

⚠️ **当前问题**: 12 个测试文件依赖外部路径 `~/Airis/worktrees/test-assets/`

**影响**: 在干净环境会跳过部分测试

**解决方案**: 见 `docs/tasks/fix/FIX-7-Test-Assets.md`

### SensitiveContentAnalysis 限制

⚠️ **`analyze safe` 命令需要**:
1. macOS 14.0+
2. 付费 Apple Developer Program 签名
3. 用户启用系统设置 > 敏感内容警告
4. `Airis.entitlements` 文件（已添加）

### macOS 版本依赖

| 功能 | 最低版本 | 命令 |
|------|---------|------|
| 基础功能 | macOS 14.0 | 大部分命令 |
| 背景移除 | macOS 14.0 | `edit cut` |
| 美学评分 | macOS 15.0 | `analyze score` |
| 3D 姿态检测 | macOS 14.0 | `detect pose3d` |

---

## 性能优化要点

### 测试性能

**当前最佳性能**:
- 完整测试: ~101s (`make test`)
- 快速测试: ~75s (`make test-quick`) ⚡

**优化措施**:
1. `swift test --parallel` - 并行执行
2. `iterationCount = 3` - 减少性能测试迭代
3. 类级别 setUp - 共享服务和资源

### CIContext 复用

```swift
// ✅ 全局单例，Metal 加速
final class CoreImageService: Sendable {
    private let context: CIContext

    init() {
        if let device = MTLCreateSystemDefaultDevice() {
            self.context = CIContext(mtlDevice: device)
        } else {
            self.context = CIContext()
        }
    }
}
```

---

## 开发流程

### 新功能开发

1. 阅读对应的 Task 文档: `docs/tasks/TASK-X.Y-*.md`
2. 创建分支: `git checkout -b feature/task-X.Y`
3. 实现功能 + 测试
4. `make test-quick` 验证
5. 提交并合并到 main

### 并行开发（多任务）

参考: `docs/tasks/PARALLEL_WORKFLOW.md`

**关键步骤**:
1. 主 Agent 创建 worktrees
2. 生成详细的 Agent 提示词
3. 副 Agents 并行开发
4. 主 Agent 逐个验收合并

**效率提升**: 65%+（实战验证）

---

## 文档索引

### 核心文档

- `docs/PRD.md` - 产品需求
- `docs/DESIGN.md` - 架构设计
- `docs/tasks/README.md` - 任务索引
- `docs/tasks/PARALLEL_WORKFLOW.md` - 并行工作流

### 问题修复文档

- `docs/tasks/fix/README.md` - 问题修复索引
- `docs/tasks/fix/FIX-1-Localization-Keys.md` - 本地化补全
- `docs/tasks/fix/FIX-2-Force-Unwrap.md` - 强制解包修复
- `docs/tasks/fix/FIX-3-Entitlements.md` - Entitlements 配置

---

## Help 文档质量标准（9+/10）

每个命令必须包含:

```
QUICK START:
  一行快速示例

EXAMPLES:
  3+ 个实际可运行的示例

OUTPUT FORMAT 或 OUTPUT:
  输出格式示例或说明

OPTIONS:
  所有参数的完整说明（含默认值）

TROUBLESHOOTING（推荐）:
  常见错误和解决方案
```

---

## 常用命令速查

### 构建和安装

```bash
# 编译
swift build -c release

# 创建符号链接
ln -sf $(pwd)/.build/release/airis ~/.local/bin/airis

# 验证
airis --version
```

### 测试

```bash
# 并行快速测试（推荐）
make test-quick

# 完整测试
make test

# 指定测试
swift test --filter VisionServiceTests
```

### Worktree 管理

```bash
# 查看所有 worktrees
git worktree list

# 删除 worktree
git worktree remove ~/Airis/worktrees/task-X.Y

# 删除分支
git branch -d feature/task-X.Y
```

---

## 代码模板

### 新命令模板

```swift
import ArgumentParser

struct NewCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "new",
        abstract: "简短描述",
        discussion: """
            QUICK START:
              airis new example.jpg

            EXAMPLES:
              # 示例 1
              airis new input.jpg -o output.png
            """
    )

    @Argument(help: "Input image path")
    var input: String

    @Option(name: [.short, .long], help: "Output path")
    var output: String

    func run() async throws {
        // 1. 验证输入
        let inputURL = try FileUtils.validateImageFile(at: input)

        // 2. 显示参数总览
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📊 处理参数")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 输入: \(inputURL.lastPathComponent)")
        print("💾 输出: \(output)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")

        // 3. 执行操作
        let service = ServiceContainer.shared.visionService
        let result = try await service.someOperation(at: inputURL)

        // 4. 显示结果
        print("✅ " + Strings.get("info.success"))
    }
}
```

### 测试模板

```swift
import XCTest
@testable import Airis

final class NewCommandTests: XCTestCase {
    // ✅ 类级别共享服务
    nonisolated(unsafe) static let sharedService = ServiceType()

    var service: ServiceType!

    override func setUp() {
        super.setUp()
        service = Self.sharedService
    }

    func testBasicOperation() async throws {
        let result = try await service.operation()
        XCTAssertNotNil(result)
    }
}
```

---

## 性能基准

### 当前性能（MacBook Pro M1）

| 测试套件 | 耗时 | 测试数 |
|---------|------|--------|
| VisionPerformanceTests | ~10s | 11 |
| ImageIOPerformanceTests | ~10s | 11 |
| CoreImagePerformanceTests | ~6s | 24 |
| Integration Tests | ~14s | 30 |
| 其他单元测试 | ~50s | 564 |
| **总计** | **~101s** | **640** |

---

## 待处理的 P1 任务

参考: `docs/tasks/fix/README.md`

**优先级 P1（短期修复）**:
- FIX-4: Gemini 调用健壮性（1-2h）
- FIX-6: ServiceContainer 并发安全（1h）
- FIX-7: 测试资产内置化（2-3h）

**优先级 P2（可选）**:
- FIX-8: 命令别名与双语 Help（3-4h）

---

## 故障排查

### 测试失败

```bash
# 检查测试资产是否存在
ls -la ~/Airis/worktrees/test-assets/

# 跳过需要资产的测试
make test-unit

# 查看详细错误
swift test --verbose
```

### 编译错误

```bash
# 清理重新编译
make clean
make build

# 查看依赖
swift package show-dependencies
```

### API Key 配置

```bash
# 配置 Gemini API Key
airis gen config set-key --provider gemini --key "YOUR_KEY"

# 查看配置
airis gen config show

# 测试生成
airis gen draw "test" -o test.png
```

---

## 有用的链接

- [Apple Vision Framework](https://developer.apple.com/documentation/vision)
- [Core Image Programming Guide](https://developer.apple.com/documentation/coreimage)
- [XCTest Performance Testing](https://developer.apple.com/documentation/xcode/writing-and-running-performance-tests)
- [Swift Testing Framework](https://developer.apple.com/documentation/testing)
- [Swift Argument Parser](https://github.com/apple/swift-argument-parser)

---

**最后更新**: 2025-12-09
