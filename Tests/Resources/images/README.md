# 测试图片资源说明

本目录包含 Airis 项目的测试图片资源，采用 **assets(物理文件) + 按用途分类的符号链接** 的组织方式。

---

## 目录结构

```
images/
├── assets/                  所有物理图片文件（唯一存储位置）
├── imageio/                 ImageIOService 测试（符号链接）
├── vision/                  VisionService 测试（符号链接）
├── coreimage/               CoreImageService 测试（符号链接）
├── landscape.jpg            性能/集成测试通用大图（符号链接）
├── line_art.png             线稿测试图（符号链接）
└── README.md                本文件
```

---

## 资源来源与维护策略

### 1) 可确定性生成（离线、无需网络、无需 API Key）

以下图片由脚本 **确定性生成**，用于保证测试在干净环境可运行：

- 入口：`make test-assets`
- 覆盖重生成：`FORCE=1 make test-assets`
- 实现：`Tests/Resources/generate_test_images.swift`

脚本默认只生成缺失文件，避免污染工作区；需要覆盖重生成时再显式开启 `--force`。

### 2) 真实图片（随仓库提交，不在脚本中生成）

人脸/手/猫/前景分割等测试，若使用程序化图片会导致 Vision 行为不稳定，因此这些图片直接随仓库提交，脚本不会生成。

---

## 关键资源清单（assets/）

| 文件名 | 用途 | 维护方式 |
|--------|------|----------|
| `small_100x100.png` | 基础加载/缩放 | 脚本生成 |
| `small_100x100_meta.png` | 元数据/Info 输出测试 | 脚本生成 |
| `transparent_200x200.png` | Alpha 通道测试 | 脚本生成 |
| `medium_512x512.jpg` | 通用测试图（多处复用） | 仓库提交 |
| `rectangle_512x512.png` | 矩形检测/边缘场景 | 脚本生成 |
| `line_art_512x512.png` | 线稿/滤镜边缘场景 | 脚本生成 |
| `document_text_512x512.png` | OCR 文档测试 | 脚本生成 |
| `document_1024x1024.png` | OCR/性能（较大尺寸） | 脚本生成 |
| `qrcode_512x512.png` | 条码/二维码检测 | 脚本生成 |
| `horizon_clear_512x512.jpg` | 地平线矫正（正常对比度） | 脚本生成 |
| `horizon_contrast_512x512.jpg` | 地平线矫正（高对比度） | 脚本生成 |
| `perf_1024x1024.jpg` | 性能/集成测试通用大图 | 仓库提交 |
| `face_512x512.png` | 人脸检测 | 仓库提交 |
| `hand_512x512.png` | 手部检测 | 仓库提交 |
| `cat_512x512.png` | 动物识别/分类 | 仓库提交 |
| `foreground_*.jpg` | 前景分割/抠图（多场景） | 仓库提交 |

---

## 符号链接映射

### imageio/（ImageIOService 测试）
- `load_basic.png` → `../assets/small_100x100.png`
- `load_medium.jpg` → `../assets/medium_512x512.jpg`
- `alpha_test.png` → `../assets/transparent_200x200.png`
- `save_roundtrip.jpg` → `../assets/medium_512x512.jpg`

### vision/（VisionService 测试）
- `classify.jpg` → `../assets/medium_512x512.jpg`
- `document.png` → `../assets/document_text_512x512.png`
- `qrcode.png` → `../assets/qrcode_512x512.png`
- `face.png` → `../assets/face_512x512.png`
- `hand.png` → `../assets/hand_512x512.png`
- `cat.png` → `../assets/cat_512x512.png`

### coreimage/（CoreImageService 测试）
- `filter.jpg` → `../assets/medium_512x512.jpg`
- `alpha_blend.png` → `../assets/transparent_200x200.png`

---

## 测试侧访问方式（推荐）

测试代码请优先使用 `TestResources` 访问资源（避免硬编码路径、支持 Bundle.module）：

```swift
let url = TestResources.image("assets/small_100x100.png")
```

---

**最后更新**: 2025-12-12
