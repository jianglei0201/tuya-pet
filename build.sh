#!/bin/bash
# Kitty Pet — 一键编译打包脚本
# 用法: ./build.sh [AppName]
# 示例: ./build.sh KittyPet
#       ./build.sh MyPet

set -e

APP_NAME="${1:-KittyPet}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"
IMG_DIR="$SCRIPT_DIR/images"
OUT_DIR="$SCRIPT_DIR/output"
BUNDLE="$OUT_DIR/$APP_NAME.app"

echo "🐱 Building $APP_NAME..."

# Check dependencies
if ! command -v swiftc &>/dev/null; then
  echo "❌ 需要安装 Xcode Command Line Tools: xcode-select --install"
  exit 1
fi
if ! command -v node &>/dev/null; then
  echo "❌ 需要安装 Node.js: brew install node"
  exit 1
fi

# Clean
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS"
mkdir -p "$BUNDLE/Contents/Resources"

# Compile Swift
echo "  ⚙️  编译 app.swift..."
swiftc "$SRC_DIR/app.swift" \
  -framework Cocoa \
  -framework WebKit \
  -o "$BUNDLE/Contents/MacOS/$APP_NAME"

# Copy resources into MacOS (server.js runs from same dir)
echo "  📄 复制资源文件..."
cp "$SRC_DIR/server.js" "$BUNDLE/Contents/MacOS/"
cp "$SRC_DIR/pet-window.html" "$BUNDLE/Contents/MacOS/"

# Copy images with standard names
cp "$IMG_DIR/default.png" "$BUNDLE/Contents/MacOS/"
cp "$IMG_DIR/sleep.png" "$BUNDLE/Contents/MacOS/"
cp "$IMG_DIR/typing.png" "$BUNDLE/Contents/MacOS/"
cp "$IMG_DIR/hungry.png" "$BUNDLE/Contents/MacOS/"
cp "$IMG_DIR/happy.png" "$BUNDLE/Contents/MacOS/"
cp "$IMG_DIR/bored.png" "$BUNDLE/Contents/MacOS/"
cp "$IMG_DIR/tired.png" "$BUNDLE/Contents/MacOS/"
cp "$IMG_DIR/dress.png" "$BUNDLE/Contents/MacOS/"
cp "$IMG_DIR/dress_happy.png" "$BUNDLE/Contents/MacOS/"
cp "$IMG_DIR/dress_hungry.png" "$BUNDLE/Contents/MacOS/"
cp "$IMG_DIR/dress_tired.png" "$BUNDLE/Contents/MacOS/"
cp "$IMG_DIR/dress_bored.png" "$BUNDLE/Contents/MacOS/"
cp "$IMG_DIR/dress_frown.png" "$BUNDLE/Contents/MacOS/"
cp "$IMG_DIR/dress2.png" "$BUNDLE/Contents/MacOS/"
cp "$IMG_DIR/dress2_happy.png" "$BUNDLE/Contents/MacOS/"
cp "$IMG_DIR/dress2_hungry.png" "$BUNDLE/Contents/MacOS/"
cp "$IMG_DIR/dress2_tired.png" "$BUNDLE/Contents/MacOS/"
cp "$IMG_DIR/dress2_bored.png" "$BUNDLE/Contents/MacOS/"
cp "$IMG_DIR/dress2_frown.png" "$BUNDLE/Contents/MacOS/"
cp "$IMG_DIR/dress3.png" "$BUNDLE/Contents/MacOS/"
cp "$IMG_DIR/dress3_happy.png" "$BUNDLE/Contents/MacOS/"
cp "$IMG_DIR/dress3_hungry.png" "$BUNDLE/Contents/MacOS/"
cp "$IMG_DIR/dress3_tired.png" "$BUNDLE/Contents/MacOS/"
cp "$IMG_DIR/dress3_bored.png" "$BUNDLE/Contents/MacOS/"
cp "$IMG_DIR/dress3_frown.png" "$BUNDLE/Contents/MacOS/"
cp "$IMG_DIR/walk_sprite.png" "$BUNDLE/Contents/MacOS/"
cp "$IMG_DIR/sleep_sprite.png" "$BUNDLE/Contents/MacOS/"
cp "$IMG_DIR/ballet_sprite.png" "$BUNDLE/Contents/MacOS/"

# Info.plist
cat > "$BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.kitty-pet.app</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# Codesign
echo "  🔏 签名..."
codesign --force --deep --sign - "$BUNDLE" 2>/dev/null

echo ""
echo "✅ 打包完成: $BUNDLE"
echo "   双击打开即可使用！"
echo ""
echo "💡 换皮方法: 替换 images/ 下的图片，重新运行 ./build.sh"
