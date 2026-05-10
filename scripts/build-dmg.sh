#!/bin/bash
set -euo pipefail

# ========================================
# RClick DMG 打包脚本 (本地开发使用)
# ========================================

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_NAME="RClick"
SCHEME="RClick"
BUILD_DIR="${PROJECT_DIR}/build"
ARCHIVE_PATH="${BUILD_DIR}/${PROJECT_NAME}.xcarchive"
EXPORT_DIR="${BUILD_DIR}/export"
APP_PATH="${EXPORT_DIR}/${PROJECT_NAME}.app"
DMG_DIR="${BUILD_DIR}/dmg"
DMG_PATH="${BUILD_DIR}/${PROJECT_NAME}.dmg"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# 清理旧构建
info "清理旧构建产物..."
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# Archive
info "正在 Archive (Release)..."
xcodebuild archive \
    -project "${PROJECT_DIR}/${PROJECT_NAME}.xcodeproj" \
    -scheme "${SCHEME}" \
    -configuration Release \
    -archivePath "${ARCHIVE_PATH}" \
    -quiet \
    || error "Archive 失败"

info "Archive 完成: ${ARCHIVE_PATH}"

# 导出 .app (直接从 archive 中复制)
info "导出 .app..."
mkdir -p "${EXPORT_DIR}"
cp -R "${ARCHIVE_PATH}/Products/Applications/${PROJECT_NAME}.app" "${APP_PATH}" \
    || error "导出 .app 失败"

info "导出完成: ${APP_PATH}"

# 获取版本号
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${APP_PATH}/Contents/Info.plist" 2>/dev/null || echo "unknown")
BUILD=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${APP_PATH}/Contents/Info.plist" 2>/dev/null || echo "unknown")
info "版本: ${VERSION} (${BUILD})"

DMG_FINAL="${BUILD_DIR}/${PROJECT_NAME}-${VERSION}.dmg"

# 创建 DMG
info "正在创建 DMG..."
mkdir -p "${DMG_DIR}"
cp -R "${APP_PATH}" "${DMG_DIR}/"
ln -sf /Applications "${DMG_DIR}/Applications"

hdiutil create \
    -volname "${PROJECT_NAME} ${VERSION}" \
    -srcfolder "${DMG_DIR}" \
    -ov \
    -format UDZO \
    "${DMG_FINAL}" \
    -quiet \
    || error "创建 DMG 失败"

# 清理临时文件
rm -rf "${DMG_DIR}" "${ARCHIVE_PATH}"

# 输出结果
DMG_SIZE=$(du -h "${DMG_FINAL}" | cut -f1 | xargs)
info "========================================="
info "打包完成!"
info "DMG: ${DMG_FINAL}"
info "大小: ${DMG_SIZE}"
info "版本: ${VERSION} (${BUILD})"
info "========================================="

# 在 Finder 中显示
open -R "${DMG_FINAL}"
