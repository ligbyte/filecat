#!/bin/bash

# git_init_push.sh
# 初始化 Git 仓库并推送到 GitHub 远程仓库（main 分支）

# 设置严格模式
set -euo pipefail

echo "检查 git 是否可用..."
if ! command -v git &> /dev/null; then
    echo "错误: git 未安装或未在 PATH 中，请先安装 Git。"
    exit 1
fi

echo "正在初始化 Git 仓库..."
git init

echo "添加所有文件到暂存区..."
git add --all

echo "提交初始版本..."
git commit -m "init project"

echo "重命名分支为 main..."
git branch -M main

echo "添加远程仓库 origin..."
git remote add origin git@github.com:ligbyte/filecat.git || \
    echo "警告: 可能已存在远程 origin，跳过添加。"

echo "推送代码到远程仓库 main 分支..."
git push -u origin main

echo ""
echo "✅ 项目初始化并推送成功！"
exit 0