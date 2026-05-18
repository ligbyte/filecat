#!/bin/bash

# 检查是否提供了提交信息
if [ -z "$1" ]; then
    echo "Usage: $0 \"Your commit message\" [branch]"
    exit 1
fi

# 获取提交信息
commitMessage="$1"

# 检查是否指定了分支，默认推送到 main/master 分支
if [ -n "$2" ]; then
    branch="$2"
else
    branch="main"  # 或者设置为 "master" 视情况而定
fi

# 添加所有更改
git add --all

# 提交更改
git commit -m "$commitMessage"

# 推送更改到指定分支
git push origin "$branch"

# 提示用户操作完成
echo "Commit and push to branch $branch completed."