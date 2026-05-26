#!/bin/bash

# 切换到 rust 目录
cd rust || { echo "Failed to enter rust directory"; exit 1; }

# 清理 cargo 构建
echo "Cleaning cargo build..."
cargo clean

# 构建发布版本
echo "Building release version..."
cargo build --release || { echo "Cargo build failed"; exit 1; }

# 返回上级目录
cd .. || { echo "Failed to return to parent directory"; exit 1; }

# 清理 Flutter 项目
echo "Cleaning flutter project..."
flutter clean

# 运行 Flutter 应用
echo "Running flutter app..."
LD_LIBRARY_PATH="./rust/target/release:$LD_LIBRARY_PATH" flutter run -d linux