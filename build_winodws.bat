@echo off
chcp 65001 >nul


:: 获取当前脚本所在的目录，确保在任何路径下运行都能正确找到项目
cd /d "%~dp0"

echo ========================================
echo [1/5] 正在进入 Rust 目录并清理旧构建...
echo ========================================
cd rust
if %errorlevel% neq 0 (echo 错误：无法进入 rust 目录！ && pause && exit /b 1)
call cargo clean
if %errorlevel% neq 0 (echo 错误：cargo clean 执行失败！ && pause && exit /b 1)

echo.
echo ========================================
echo [2/5] 正在以 Release 模式编译 Rust 项目...
echo ========================================
call cargo build --release
if %errorlevel% neq 0 (echo 错误：Rust 编译失败！ && pause && exit /b 1)

echo.
echo ========================================
echo [3/5] 正在返回上级目录并复制 DLL 文件...
echo ========================================
cd ..
copy "rust\target\release\filecat.dll" ".\" /Y
if %errorlevel% neq 0 (echo 错误：复制 filecat.dll 失败！ && pause && exit /b 1)

echo.
echo ========================================
echo [4/5] 正在清理 Flutter 项目...
echo ========================================
call flutter clean
if %errorlevel% neq 0 (echo 错误：flutter clean 执行失败！ && pause && exit /b 1)

echo.
echo ========================================
echo [5/5] 正在启动 Flutter Windows 应用...
echo ========================================
call flutter run -d windows

echo.
echo ========================================
echo 脚本执行完毕
echo ========================================
pause