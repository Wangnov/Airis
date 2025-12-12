#!/bin/bash
set -euo pipefail

# 离线生成/更新测试图片资源（确定性、无需网络、无需 API Key）。
#
# 用法:
#   make test-assets
#   bash Tests/Resources/create_test_images.sh           # 仅生成缺失文件
#   FORCE=1 make test-assets                             # 覆盖已存在的可生成资源
#   bash Tests/Resources/create_test_images.sh --force    # 同上

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SWIFT_SCRIPT="$SCRIPT_DIR/generate_test_images.swift"

if ! command -v swift >/dev/null 2>&1; then
  echo "⚠️  未找到 swift，跳过测试资源生成" >&2
  exit 0
fi

args=("$@")

# 兼容 Makefile 的 FORCE=1
if [[ "${FORCE:-}" == "1" ]]; then
  args+=("--force")
fi

echo "🖼️  生成测试图片资源（离线）..."

# macOS 自带的 bash(3.2) 在 set -u 下展开空数组会报错，因此需要分支处理。
if (( ${#args[@]} )); then
  swift "$SWIFT_SCRIPT" "${args[@]}"
else
  swift "$SWIFT_SCRIPT"
fi
