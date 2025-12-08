# Airis 任务索引与路线图

**文档版本**: v1.0
**最后更新**: 2025-12-08
**项目状态**: 🔵 规划阶段

---

## 📊 总览

Airis 项目被拆分为 **9 个 Phase**，共 **20+ 个独立任务**。每个任务预估工作量为 2-8 小时，适合分批次完成。

---

## 🎯 Phase 1: 基础设施与框架搭建 (P0 - 必须最先完成)

| Task | 文件 | 状态 | 工作量 | 前置条件 |
|------|------|------|--------|---------|
| **1.1** | Project Init | 🔵 待开始 | 2-4h | 无 |
| **1.2** | Core Infrastructure | 🔵 待开始 | 4-6h | Task 1.1 |
| **1.3** | CLI Framework | 🔵 待开始 | 3-5h | Task 1.2 |

**交付物**:
- ✅ Swift Package Manager 配置
- ✅ 双语本地化系统
- ✅ 统一错误类型
- ✅ 5 个顶级父命令结构

**预计总工时**: 9-15 小时

---

## 🎨 Phase 2: 生成模块 (P1 - 独立模块)

| Task | 文件 | 状态 | 工作量 | 前置条件 |
|------|------|------|--------|---------|
| **2.1** | gen Commands | 🔵 待开始 | 6-8h | Task 1.3 |

**交付物**:
- ✅ Keychain API Key 管理
- ✅ Gemini Provider 基础实现
- ✅ `gen draw` 和 `gen config` 命令

**预计总工时**: 6-8 小时

---

## 🔍 Phase 3: 分析模块 (P1 - Vision 框架基础)

| Task | 文件 | 状态 | 工作量 | 前置条件 |
|------|------|------|--------|---------|
| **3.1** | Vision Service | 🔵 待开始 | 4-6h | Task 1.2 |
| **3.2** | analyze Commands (Batch 1) | 🔵 待开始 | 6-8h | Task 3.1 |
| **3.3** | analyze Commands (Batch 2) | 🔵 待开始 | 6-8h | Task 3.1 |

**Batch 1** (Task 3.2):
- `analyze info` - 图像基本信息
- `analyze tag` - 场景识别
- `analyze score` - 美学评分
- `analyze ocr` - 文字识别

**Batch 2** (Task 3.3):
- `analyze safe` - 敏感内容检测
- `analyze palette` - 色彩提取
- `analyze similar` - 图片相似度
- `analyze meta` - 元数据读写

**预计总工时**: 16-22 小时

---

## 👁️ Phase 4: 检测模块 (P1 - 对象检测)

| Task | 文件 | 状态 | 工作量 | 前置条件 |
|------|------|------|--------|---------|
| **4.1** | detect Commands (Batch 1) | 🔵 待开始 | 5-7h | Task 3.1 |
| **4.2** | detect Commands (Batch 2) | 🔵 待开始 | 6-8h | Task 3.1 |

**Batch 1** (Task 4.1):
- `detect barcode` - 条形码/二维码
- `detect face` - 人脸检测
- `detect animal` - 动物检测

**Batch 2** (Task 4.2):
- `detect pose` - 人体 2D 姿态
- `detect pose3d` - 人体 3D 姿态
- `detect hand` - 手势检测
- `detect pet-pose` - 宠物姿态

**预计总工时**: 11-15 小时

---

## 🌟 Phase 5: 高级视觉模块 (P2 - 可选)

| Task | 文件 | 状态 | 工作量 | 前置条件 |
|------|------|------|--------|---------|
| **5.1** | vision Commands | 🔵 待开始 | 6-8h | Task 3.1 |

**包含命令**:
- `vision flow` - 光流分析
- `vision align` - 图像配准
- `vision saliency` - 显著性检测
- `vision persons` - 多人分割

**预计总工时**: 6-8 小时

---

## ✏️ Phase 6: 编辑模块基础 (P1 - CoreImage)

| Task | 文件 | 状态 | 工作量 | 前置条件 |
|------|------|------|--------|---------|
| **6.1** | CoreImage Service | 🔵 待开始 | 4-6h | Task 1.2 |
| **6.2** | edit Commands (Batch 1) | 🔵 待开始 | 6-8h | Task 6.1 |
| **6.3** | edit Commands (Batch 2) | 🔵 待开始 | 6-8h | Task 6.1 |

**Batch 1** (Task 6.2):
- `edit cut` - 抠图
- `edit resize` - 缩放
- `edit crop` - 裁剪
- `edit enhance` - 一键增强

**Batch 2** (Task 6.3):
- `edit scan` - 文档扫描
- `edit straighten` - 拉正
- `edit trace` - 矢量描摹
- `edit defringe` - 去光晕
- `edit fmt` - 格式转换
- `edit thumb` - 缩略图

**预计总工时**: 16-22 小时

---

## 🎭 Phase 7: 滤镜模块 (P2 - 艺术效果)

| Task | 文件 | 状态 | 工作量 | 前置条件 |
|------|------|------|--------|---------|
| **7.1** | edit filter Commands | 🔵 待开始 | 8-10h | Task 6.1 |

**包含命令** (11 个):
- blur, sharpen, pixel, noise
- comic, halftone
- sepia, mono, chrome, noir, instant

**预计总工时**: 8-10 小时

---

## 🎨 Phase 8: 调整模块 (P2 - 色彩与几何)

| Task | 文件 | 状态 | 工作量 | 前置条件 |
|------|------|------|--------|---------|
| **8.1** | edit adjust Commands | 🔵 待开始 | 6-8h | Task 6.1 |

**包含命令** (9 个):
- color, exposure, temperature, vignette
- invert, posterize, threshold
- flip, rotate

**预计总工时**: 6-8 小时

---

## 🧪 Phase 9: 测试与优化 (P0 - 必须)

| Task | 文件 | 状态 | 工作量 | 前置条件 |
|------|------|------|--------|---------|
| **9.1** | Unit Tests | 🔵 待开始 | 8-10h | 所有功能模块 |
| **9.2** | Integration Tests | 🔵 待开始 | 6-8h | Task 9.1 |
| **9.3** | Documentation | 🔵 待开始 | 4-6h | Task 9.2 |

**交付物**:
- ✅ 所有模块的单元测试
- ✅ 端到端集成测试
- ✅ 使用文档与示例
- ✅ 性能基准测试

**预计总工时**: 18-24 小时

---

## 📈 项目里程碑

### Milestone 1: MVP (最小可用产品)
**包含**: Phase 1 + Phase 2 + Task 3.1 + Task 3.2 (部分 analyze 命令)
**工时**: 约 25-35 小时
**可交付**: 基础 CLI + gen + 部分 analyze 命令

### Milestone 2: 分析完整版
**包含**: M1 + Task 3.3 + Phase 4
**工时**: 约 50-70 小时
**可交付**: 完整的 gen + analyze + detect 功能

### Milestone 3: 编辑完整版
**包含**: M2 + Phase 6
**工时**: 约 70-95 小时
**可交付**: 所有核心功能（不含高级滤镜）

### Milestone 4: 功能完整版
**包含**: M3 + Phase 5 + Phase 7 + Phase 8
**工时**: 约 90-120 小时
**可交付**: 所有 48 个命令

### Milestone 5: 发布版本
**包含**: M4 + Phase 9
**工时**: 约 110-145 小时
**可交付**: 经过测试的 v1.0 版本

---

## 🗓️ 建议开发顺序

### 第一周 (优先级 P0)
1. Task 1.1 → Task 1.2 → Task 1.3 (基础设施)
2. Task 3.1 (Vision Service)

### 第二周 (核心功能)
3. Task 2.1 (gen 命令)
4. Task 3.2 (analyze Batch 1)
5. Task 3.3 (analyze Batch 2)

### 第三周 (检测功能)
6. Task 4.1 (detect Batch 1)
7. Task 4.2 (detect Batch 2)
8. Task 6.1 (CoreImage Service)

### 第四周 (编辑功能)
9. Task 6.2 (edit Batch 1)
10. Task 6.3 (edit Batch 2)

### 第五周 (高级功能)
11. Task 5.1 (vision 命令) - 可选
12. Task 7.1 (filter 命令)
13. Task 8.1 (adjust 命令)

### 第六周 (测试与优化)
14. Task 9.1 (单元测试)
15. Task 9.2 (集成测试)
16. Task 9.3 (文档)

---

## 📋 任务文件清单

```
docs/tasks/
├── README.md (本文件)
├── TASK-1.1-Project-Init.md ✅
├── TASK-1.2-Core-Infrastructure.md ✅
├── TASK-1.3-CLI-Framework.md ✅
├── TASK-2.1-Gen-Commands.md ✅
├── TASK-3.1-Vision-Service.md ✅
├── TASK-3.2-Analyze-Commands-Batch1.md (待生成)
├── TASK-3.3-Analyze-Commands-Batch2.md (待生成)
├── TASK-4.1-Detect-Commands-Batch1.md (待生成)
├── TASK-4.2-Detect-Commands-Batch2.md (待生成)
├── TASK-5.1-Vision-Commands.md (待生成)
├── TASK-6.1-CoreImage-Service.md (待生成)
├── TASK-6.2-Edit-Commands-Batch1.md (待生成)
├── TASK-6.3-Edit-Commands-Batch2.md (待生成)
├── TASK-7.1-Filter-Commands.md (待生成)
├── TASK-8.1-Adjust-Commands.md (待生成)
├── TASK-9.1-Unit-Tests.md (待生成)
├── TASK-9.2-Integration-Tests.md (待生成)
└── TASK-9.3-Documentation.md (待生成)
```

---

## 🎯 当前进度

| Phase | 已完成 | 进行中 | 待开始 | 总计 |
|-------|--------|--------|--------|------|
| Phase 1 | 3 | 0 | 0 | 3 |
| Phase 2 | 1 | 0 | 0 | 1 |
| Phase 3 | 0 | 0 | 3 | 3 |
| Phase 4 | 0 | 0 | 2 | 2 |
| Phase 5 | 0 | 0 | 1 | 1 |
| Phase 6 | 0 | 0 | 3 | 3 |
| Phase 7 | 0 | 0 | 1 | 1 |
| Phase 8 | 0 | 0 | 1 | 1 |
| Phase 9 | 0 | 0 | 3 | 3 |
| **总计** | **4** | **0** | **14** | **18** |

**已完成任务**:
- ✅ Task 1.1: 项目初始化（实际 ~1h）
- ✅ Task 1.2: 核心基础设施层（实际 ~2h）
- ✅ Task 1.3: CLI 框架搭建（实际 ~1h）
- ✅ Task 2.1: gen 命令组（实际 ~6h，含完整实现 + 最佳实践优化）

**下一步**: Task 3.1 - Vision Service 基础设施

---

## 📝 使用说明

1. **按顺序完成**: Phase 1 必须最先完成
2. **可并行任务**: Phase 2-5 可以并行进行（如果有多人）
3. **检查前置条件**: 每个任务都有前置条件，确保满足后再开始
4. **更新状态**: 完成任务后更新本文档的进度表

---

**下一步**: 开始 **Task 1.1: 项目初始化**
