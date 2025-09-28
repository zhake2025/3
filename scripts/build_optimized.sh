#!/bin/bash

# Kelivo PWA 优化构建脚本

echo "🚀 开始优化构建 Kelivo PWA..."

# 清理之前的构建
echo "🧹 清理之前的构建文件..."
flutter clean
rm -rf build/web

# 获取依赖
echo "📦 获取项目依赖..."
flutter pub get

# 执行优化构建
echo "🔨 执行优化构建..."
flutter build web \
  --release \
  --web-renderer canvaskit \
  --tree-shake-icons \
  --dart2js-optimization O4 \
  --no-source-maps \
  --base-href "/" \
  --pwa-strategy offline-first

# 构建完成后的优化
echo "⚡ 构建后优化..."

# 压缩JavaScript文件
if command -v gzip &> /dev/null; then
    echo "📦 压缩JavaScript文件..."
    find build/web -name "*.js" -exec gzip -9 -k {} \;
fi

# 显示构建结果
echo "📊 构建结果:"
if [ -d "build/web" ]; then
    echo "构建目录大小: $(du -sh build/web | cut -f1)"
    echo "主要文件大小:"
    ls -lah build/web/*.js 2>/dev/null | head -5
    ls -lah build/web/*.wasm 2>/dev/null | head -3
fi

echo "✅ Kelivo PWA 优化构建完成!"
echo "💡 提示: 使用 'flutter pub run build_runner build' 来生成代码"
echo "🌐 PWA 文件位于: build/web/"