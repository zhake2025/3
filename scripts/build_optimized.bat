@echo off
REM Kelivo PWA 优化构建脚本 (Windows 版本)

echo 🚀 开始优化构建 Kelivo PWA...

REM 清理之前的构建
echo 🧹 清理之前的构建文件...
flutter clean
if exist "build\web" rmdir /s /q "build\web"

REM 获取依赖
echo 📦 获取项目依赖...
flutter pub get

REM 执行优化构建
echo 🔨 执行优化构建...
flutter build web ^
  --release ^
  --web-renderer canvaskit ^
  --tree-shake-icons ^
  --dart2js-optimization O4 ^
  --no-source-maps ^
  --base-href "/" ^
  --pwa-strategy offline-first

REM 构建完成后的优化
echo ⚡ 构建后优化...

REM 显示构建结果
echo 📊 构建结果:
if exist "build\web" (
    echo 构建目录: build\web
    dir "build\web\*.js" 2>nul
    dir "build\web\*.wasm" 2>nul
)

echo ✅ Kelivo PWA 优化构建完成!
echo 💡 提示: 使用 'flutter pub run build_runner build' 来生成代码
echo 🌐 PWA 文件位于: build\web\

pause