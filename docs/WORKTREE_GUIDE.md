# Airis Worktree 并行开发指南

## 📁 Worktree 目录

**统一位置**: `~/airis-worktrees/`

所有并行开发任务都在此目录下创建独立的 worktree。

---

## 🚀 标准工作流

### 步骤 1: 创建 Worktree

```bash
cd ~/Airis

# 创建新任务的 worktree
git worktree add ~/airis-worktrees/task-X.Y-name -b feature/task-X.Y

# 示例
git worktree add ~/airis-worktrees/task-3.3-analyze -b feature/task-3.3
```

### 步骤 2: Agent 在 Worktree 中开发

Agent 提示词模板：
```markdown
你的工作目录: ~/airis-worktrees/task-X.Y-name
你的分支: feature/task-X.Y

开发要求：
1. 在当前 worktree 目录中开发
2. 测试使用临时配置（ConfigManager(configFile: tempFile)）
3. Help 文档达到 9+/10 标准
4. 完成后运行 swift test 确保全部通过
5. 提交代码并通知主 Agent

任务详情: [提示词文件路径]
```

### 步骤 3: 验收和合并

```bash
cd ~/Airis

# 验收各个 worktree 的实现
cd ~/airis-worktrees/task-X.Y-name && swift test

# 回到主仓库合并
cd ~/Airis
git merge --no-ff feature/task-X.Y -m "Merge Task X.Y: 功能描述"

# 验证合并后测试
swift test
```

### 步骤 4: 清理

```bash
cd ~/Airis

# 删除 worktree
git worktree remove ~/airis-worktrees/task-X.Y-name

# 删除分支
git branch -d feature/task-X.Y
```

---

## 📝 命名规范

### Worktree 目录命名

格式: `task-X.Y-简短描述`

| Task | Worktree 目录 | 分支名 |
|------|--------------|--------|
| 3.3 | `task-3.3-analyze` | `feature/task-3.3` |
| 4.2 | `task-4.2-detect` | `feature/task-4.2` |
| 5.1 | `task-5.1-vision` | `feature/task-5.1` |
| 6.2 | `task-6.2-edit` | `feature/task-6.2` |

---

## ✅ 测试隔离要求

### ConfigManager
```swift
// ✅ 测试时使用临时路径
let tempFile = FileManager.default.temporaryDirectory
    .appendingPathComponent("test_config_\(UUID()).json")
let manager = ConfigManager(configFile: tempFile)

// tearDown 清理
try? FileManager.default.removeItem(at: tempFile)
```

### KeychainManager
```swift
// ✅ 使用唯一测试 ID
let testProvider = "test-\(UUID().uuidString)"

// tearDown 清理
try? keychain.deleteAPIKey(for: testProvider)
```

**禁止**: 直接操作 `~/.config/airis/config.json`

---

## 🎯 质量标准

### Help 文档（9+/10）
- ✅ QUICK START
- ✅ EXAMPLES（3+ 个）
- ✅ OUTPUT FORMAT
- ✅ OPTIONS（完整说明）
- ✅ TROUBLESHOOTING

### 代码质量
- ✅ 遵循 Swift 6 严格并发
- ✅ 使用 @preconcurrency 处理 Vision 框架
- ✅ 复用 ServiceContainer 服务
- ✅ 统一的错误处理（AirisError）
- ✅ 本地化支持（Strings.get）

### 测试要求
- ✅ 每个命令至少 3 个测试
- ✅ 测试隔离（不污染用户数据）
- ✅ 100% 测试通过
- ✅ tearDown 清理所有测试数据

---

## 📊 并行开发追踪

### 阶段 2 可并行任务

| Task | 命令数 | 预估工时 | 依赖 | 状态 |
|------|--------|---------|------|------|
| 3.3 | 4 (safe, palette, similar, meta) | 6-8h | Task 3.1 ✅ | 🔵 待开始 |
| 4.2 | 4 (pose, pose3d, hand, petpose) | 6-8h | Task 3.1 ✅ | 🔵 待开始 |
| 5.1 | 4 (flow, align, saliency, persons) | 6-8h | Task 3.1 ✅ | 🔵 待开始 |
| 6.2 | 4 (cut, resize, crop, enhance) | 6-8h | Task 6.1 ✅ | 🔵 待开始 |

**可同时进行**: 全部 4 个任务
**并行总工时**: 6-8 小时

---

## 🔍 查看当前状态

```bash
# 查看所有 worktrees
git worktree list

# 查看分支
git branch -a

# 查看各 worktree 的测试状态
for dir in ~/airis-worktrees/task-*; do
  echo "Testing $dir..."
  cd "$dir" && swift test
done
```
