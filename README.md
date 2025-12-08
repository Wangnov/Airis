# Airis

[中文](#中文版本) | [English](#english-version)

---

## 中文版本

**Airis** - AI 驱动的图像处理信使

一个强大的命令行工具，结合了 Apple Vision 框架、CoreImage 和 AI 图像生成能力，提供全面的图像处理功能。

### ✨ 特性

- 🎨 **AI 图像生成** - 使用 Gemini API 从文本生成图像
- 🔍 **图像分析** - 场景识别、OCR、美学评分、色彩提取
- 👁️ **对象检测** - 人脸、条形码、动物、人体姿态检测
- 🌟 **高级视觉** - 光流分析、图像配准、显著性检测
- ✏️ **图像编辑** - 背景移除、缩放、裁剪、滤镜、色彩调整

### 🚀 快速开始

```bash
# 1. 编译
swift build -c release

# 2. 创建符号链接
ln -sf $(pwd)/.build/release/airis ~/.local/bin/airis

# 3. 配置 API Key
airis gen config set-key --provider gemini --key "YOUR_API_KEY"

# 4. 生成第一张图片
airis gen draw "赛博朋克猫" -o cat.png
```

### 📚 功能速览

**51 个命令** | **640 tests** | **85% 覆盖率**

---

## English Version

**Airis** - The AI-Native Messenger for Image Operations

A powerful CLI tool combining Apple Vision, CoreImage, and AI generation.

### ✨ Features

- 🎨 AI Image Generation with Gemini
- 🔍 Image Analysis (OCR, tagging, scoring)
- 👁️ Object Detection (faces, barcodes, poses)
- 🌟 Advanced Vision (optical flow, saliency)
- ✏️ Image Editing (filters, adjustments, transforms)

### 🚀 Quick Start

```bash
swift build -c release
airis gen config set-key --provider gemini --key "KEY"
airis gen draw "cyberpunk cat" -o cat.png
```

**51 commands** | **640 tests** | **85% coverage**

---

For detailed documentation, run: `airis --help`
