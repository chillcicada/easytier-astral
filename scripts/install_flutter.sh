#!/bin/bash
# 统一的Flutter安装脚本 (Linux/macOS)
# 使用环境变量 FLUTTER_VERSION 和 FLUTTER_CHANNEL

set -e

FLUTTER_VERSION="${FLUTTER_VERSION:-main}"
FLUTTER_PATH="${HOME}/flutter"

echo "=========================================="
echo "🐦 安装 Flutter"
echo "版本: $FLUTTER_VERSION"
echo "=========================================="

# 克隆 Flutter 仓库
echo "正在克隆 Flutter $FLUTTER_VERSION 分支..."
git clone https://github.com/flutter/flutter.git --branch "$FLUTTER_VERSION" "$FLUTTER_PATH" --depth 1

# 添加到 PATH
echo "$FLUTTER_PATH/bin" >> $GITHUB_PATH
export PATH="$FLUTTER_PATH/bin:$PATH"

# 授予执行权限
chmod +x "$FLUTTER_PATH/bin/flutter"

# 验证安装
echo "验证 Flutter 安装..."
flutter --version
echo "✅ Flutter 安装完成！"
