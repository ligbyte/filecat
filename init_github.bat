@echo off
:: 设置代码页为 UTF-8
chcp 65001 >nul

:: git_init_push.bat
:: 初始化 Git 仓库并推送到 GitHub 远程仓库（main 分支）

setlocal

:: 检查是否安装了 git
where git >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: 未找到 git 命令，请确保已安装 Git 并添加到系统 PATH。
    exit /b 1
)

echo 正在初始化 Git 仓库...
git init
if %errorlevel% neq 0 goto error

echo 添加所有文件到暂存区...
git add --all
if %errorlevel% neq 0 goto error

echo 提交初始版本...
git commit -m "init project"
if %errorlevel% neq 0 goto error

echo 重命名分支为 main...
git branch -M main
if %errorlevel% neq 0 goto error

echo 添加远程仓库 origin...
git remote add origin git@github.com:ligbyte/filecat.git
if %errorlevel% neq 0 (
    echo 警告: 添加远程仓库失败，可能已存在远程 origin。
)

echo 推送代码到远程仓库 main 分支...
git push -u origin main
if %errorlevel% neq 0 goto error

echo.
echo ✅ 项目初始化并推送成功！
goto end

:error
echo.
echo ❌ 脚本执行失败，出现错误。
exit /b 1

:end
end