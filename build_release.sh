#!/bin/bash
# One-command release build + packaging for the Chinese-localized Ice app.
# Requires full Xcode (not just Command Line Tools). Produces:
#   build/Build/Products/Release/Ice.app   (ad-hoc signed, runs locally)
#   Ice-cn.dmg                              (drag-to-install disk image)
#
# Usage:  ./build_release.sh
set -euo pipefail

if ! xcode-select -p 2>/dev/null | grep -q "Xcode.app"; then
  echo "ERROR: 需要完整 Xcode。请先安装 Xcode 并执行："
  echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
  echo "  xcodebuild -runFirstLaunch"
  exit 1
fi

cd "$(dirname "$0")"

DERIVED=./build
APP="$DERIVED/Build/Products/Release/Ice.app"
DMG=./Ice-cn.dmg

echo "==> 解析依赖并编译 Release (中文本地化)"
xcodebuild build \
  -project Ice.xcodeproj \
  -scheme Ice \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$DERIVED" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="-" \
  DEVELOPMENT_TEAM="" \
  ENABLE_HARDENED_RUNTIME=NO \
  ONLY_ACTIVE_ARCH=YES

echo "==> 本机 ad-hoc 重签名（带 entitlements）"
codesign --force --deep --sign - \
  --entitlements Ice/Ice.entitlements \
  "$APP"

echo "==> 打包 DMG"
rm -f "$DMG"
STAGING=$(mktemp -d)
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
hdiutil create -volname "Ice" -srcfolder "$STAGING" -ov -format UDZO "$DMG"
rm -rf "$STAGING"

echo
echo "完成！可直接使用："
echo "  App: $APP"
echo "  DMG: $DMG"
echo "打开后若界面非中文：系统设置 › 通用 › 语言与区域 › 应用程序 › 为 Ice 选择「简体中文」，或用中文系统语言。"
