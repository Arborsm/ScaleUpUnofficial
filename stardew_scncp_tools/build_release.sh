#!/bin/bash

# 当任何命令失败时立即退出脚本
set -e

# --- 脚本开始 ---
# 这个脚本假定你已经在 Flutter 项目的根目录下运行
# 例如: cd /path/to/your/project/stardew_scncp_tools/
# 然后运行 ./build_release.sh

echo " cleaning previous build artifacts..."
flutter clean

echo " getting dependencies..."
flutter pub get

echo " starting release build for desktop..."

# --- 选择你的目标平台 ---
# 请取消下面你需要的构建命令的注释 (删除行首的 #)

# 为 macOS 构建
# flutter build macos \
#   --release \
#   --obfuscate \
#   --split-debug-info=build/debug-info \
#   --tree-shake-icons

# 为 Linux 构建
# flutter build linux \
#   --release \
#   --obfuscate \
#   --split-debug-info=build/debug-info \
#   --tree-shake-icons

# 为 Windows 构建 (通常在 Windows 机器上运行)
# flutter build windows \
#   --release \
#   --obfuscate \
#   --split-debug-info=build/debug-info \
#   --tree-shake-icons


echo " build finished successfully!"
echo " find the release build in the 'build/<platform>/runner/Release' directory."
echo " find the de-obfuscation symbols in: build/debug-info/"