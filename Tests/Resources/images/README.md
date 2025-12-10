# 测试图片资源说明

本目录包含 Airis 项目的测试图片资源，采用**统一管理 + 符号链接**的组织方式。

---

## 📁 目录结构

```
images/
├── assets/                  所有物理图片文件（唯一存储位置）
├── imageio/                 ImageIOService 测试（符号链接）
├── vision/                  VisionService 测试（符号链接）
├── coreimage/               CoreImageService 测试（符号链接）
└── README.md                本文件
```

---

## 🖼️ 资源清单

### assets/（物理文件）

| 文件名 | 尺寸 | 格式 | 特性 | 大小 | 用途 |
|--------|------|------|------|------|------|
| `small_100x100.png` | 100×100 | PNG | RGB, 有透明 | 12KB | 基础加载测试 |
| `medium_512x512.jpg` | 512×512 | JPEG | RGB, 85%质量 | 26KB | 通用测试图 |
| `transparent_200x200.png` | 200×200 | PNG | RGBA, 透明 | 21KB | 透明通道测试 |
| `ocr_text.png` | 待生成 | PNG | 含文字 | ~30KB | OCR 测试 |
| `face_portrait.jpg` | 待生成 | JPEG | 含人脸 | ~40KB | 人脸检测测试 |

**总大小**: ~130KB

---

## 🔗 符号链接映射

### imageio/（ImageIOService 测试）
- `load_basic.png` → `../assets/small_100x100.png`
- `load_medium.jpg` → `../assets/medium_512x512.jpg`
- `alpha_test.png` → `../assets/transparent_200x200.png`
- `save_roundtrip.jpg` → `../assets/medium_512x512.jpg`

### vision/（VisionService 测试）
- `classify.jpg` → `../assets/medium_512x512.jpg`
- `ocr.png` → `../assets/ocr_text.png`（待创建）
- `face.jpg` → `../assets/face_portrait.jpg`（待创建）

### coreimage/（CoreImageService 测试）
- `filter.jpg` → `../assets/medium_512x512.jpg`
- `alpha_blend.png` → `../assets/transparent_200x200.png`

---

## 📝 图片生成记录

### 已生成

**small_100x100.png**:
```bash
# 使用 Gemini 2.5-flash + airis 自身工具链生成
airis gen draw "solid red square" --model gemini-2.5-flash-image -o temp.png
airis edit resize temp.png --width 100 --height 100 -o small_100x100.png
```

**medium_512x512.jpg**:
```bash
airis gen draw "blue gradient" --model gemini-3-pro-image-preview --image-size 1K -o temp.png
airis edit resize temp.png --width 512 --height 512 -o temp_512.png
airis edit fmt temp_512.png --format jpg -o medium_512x512.jpg
```

**transparent_200x200.png**:
```bash
airis gen draw "red apple on white background" --model gemini-3-pro-image-preview -o temp.png
airis edit cut temp.png -o temp_cut.png --force
airis edit resize temp_cut.png --width 200 --height 200 -o transparent_200x200.png
```

### 待生成（按需）

**ocr_text.png** - OCR 测试需要时生成：
```bash
airis gen draw "a document with clear text 'Hello World', black text on white paper" \
    --model gemini-3-pro-image-preview -o ocr_text.png
```

**face_portrait.jpg** - 人脸检测需要时生成：
```bash
airis gen draw "portrait photo of a person, clear face, neutral expression" \
    --model gemini-3-pro-image-preview -o face_portrait.jpg
```

---

## 🎯 使用指南

### 在测试中引用

```swift
// 使用分类链接（语义清晰）
let testImageURL = URL(fileURLWithPath: "Tests/Resources/images/imageio/load_basic.png")

// 或直接使用物理文件
let testImageURL = URL(fileURLWithPath: "Tests/Resources/images/assets/small_100x100.png")
```

### 验证图片

```bash
# 验证所有图片
for img in assets/*; do
  airis analyze info "$img"
done
```

---

**最后更新**: 2025-12-10
