#!/bin/bash
# 创建测试所需的图片资源

cd "$(dirname "$0")/images"

# 使用 sips 创建测试图片（macOS 内置工具）

# 1. 小图 100x100 (PNG)
sips -z 100 100 --setProperty format png -o small_100x100.png /System/Library/Desktop\ Pictures/Solid\ Colors/Solid\ Aqua\ Graphite.png 2>/dev/null

# 2. 中图 512x512 (JPEG)
sips -z 512 512 --setProperty format jpeg --setProperty formatOptions 85 -o medium_512x512.jpg /System/Library/Desktop\ Pictures/Solid\ Colors/Solid\ Blue.png 2>/dev/null

# 3. 带透明通道 (PNG)
# 从系统图标复制一个有透明的图片
cp /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericDocumentIcon.icns transparent.png 2>/dev/null || echo "skip transparent"

echo "测试图片创建完成"
ls -lh
