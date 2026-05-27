#!/bin/bash
# TuyaPet 桌宠一键安装脚本
# 用法:
#   bash install.sh                    — 使用默认小鸭子形象
#   bash install.sh --images ~/imgs/   — 使用自定义图片

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="TuyaPet"
CUSTOM_IMAGES=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --images) CUSTOM_IMAGES="$2"; shift 2 ;;
    *) APP_NAME="$1"; shift ;;
  esac
done

echo ""
echo "🦆 TuyaPet 桌宠安装程序"
echo "========================"
echo ""

# 检查依赖
MISSING=""
if ! command -v swiftc &>/dev/null; then
  MISSING="$MISSING swiftc"
fi
if ! command -v node &>/dev/null; then
  MISSING="$MISSING node"
fi

if [ -n "$MISSING" ]; then
  echo "❌ 缺少依赖，请先安装："
  echo ""
  if [[ "$MISSING" == *"swiftc"* ]]; then
    echo "  Xcode Command Line Tools:"
    echo "    xcode-select --install"
    echo ""
  fi
  if [[ "$MISSING" == *"node"* ]]; then
    echo "  Node.js:"
    echo "    brew install node"
    echo ""
  fi
  exit 1
fi

# 自定义图片
if [ -n "$CUSTOM_IMAGES" ]; then
  if [ ! -d "$CUSTOM_IMAGES" ]; then
    echo "❌ 图片目录不存在: $CUSTOM_IMAGES"
    exit 1
  fi
  echo "🎨 使用自定义图片: $CUSTOM_IMAGES"
  echo ""

  IMG_DIR="$SCRIPT_DIR/images"

  # 检查必需图片
  REQUIRED="default.png"
  for f in $REQUIRED; do
    if [ ! -f "$CUSTOM_IMAGES/$f" ]; then
      echo "⚠️  未找到 $f，将保留默认图片"
    fi
  done

  # 复制存在的图片
  for f in "$CUSTOM_IMAGES"/*.png "$CUSTOM_IMAGES"/*.PNG "$CUSTOM_IMAGES"/*.webp; do
    [ -f "$f" ] && cp "$f" "$IMG_DIR/" && echo "  ✅ $(basename "$f")"
  done
  echo ""
fi

# 编译
echo "⚙️  编译中..."
bash "$SCRIPT_DIR/build.sh" "$APP_NAME"

# 安装到 /Applications（可选）
INSTALL_DIR="/Applications/$APP_NAME.app"
if [ -d "$INSTALL_DIR" ]; then
  echo ""
  echo "📦 更新 $INSTALL_DIR ..."
  rm -rf "$INSTALL_DIR"
fi
cp -R "$SCRIPT_DIR/output/$APP_NAME.app" /Applications/

echo ""
echo "🚀 启动 $APP_NAME..."
open "/Applications/$APP_NAME.app"

echo ""
echo "✅ 安装完成！"
echo ""
echo "   小鸭子已出现在你的屏幕上 🦆"
echo "   右键小鸭子可以聊天、换装、跳芭蕾等"
echo "   App 已安装到 /Applications/$APP_NAME.app"
echo ""
echo "💡 提示："
echo "   · 点击身体可以换装"
echo "   · 点击头部可以聊天"
echo "   · 右键打开功能菜单"
echo "   · 想换形象？替换 images/ 目录下的图片，重新运行 bash install.sh"
echo ""
