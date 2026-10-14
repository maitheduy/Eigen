#!/bin/bash

set -e

# ============================================================
# UNIVERSAL HTML DEPLOY
# Git + GitHub + Tag + GitHub Pages
# ============================================================

echo ""
echo "============================================================"
echo "        🚀 UNIVERSAL HTML DEPLOY"
echo "============================================================"
echo ""

# ------------------------------------------------------------
# 1. Kiểm tra Git
# ------------------------------------------------------------

if ! command -v git >/dev/null 2>&1; then
    echo "❌ Không tìm thấy Git."
    exit 1
fi

# ------------------------------------------------------------
# 2. Kiểm tra GitHub CLI
# ------------------------------------------------------------

if ! command -v gh >/dev/null 2>&1; then
    echo "❌ Chưa cài GitHub CLI (gh)."
    echo ""
    echo "Cài bằng:"
    echo "brew install gh"
    exit 1
fi

# ------------------------------------------------------------
# 3. Kiểm tra đăng nhập GitHub
# ------------------------------------------------------------

if ! gh auth status >/dev/null 2>&1; then
    echo "❌ GitHub CLI chưa đăng nhập."
    echo ""
    echo "Hãy chạy:"
    echo "gh auth login"
    exit 1
fi

# ------------------------------------------------------------
# 4. Kiểm tra index.html
# ------------------------------------------------------------

if [ ! -f "index.html" ]; then
    echo "❌ Không tìm thấy index.html"
    echo ""
    echo "Hãy chạy deploy.sh trong thư mục chứa index.html."
    exit 1
fi

# ------------------------------------------------------------
# 5. Tự động lấy thông tin
# ------------------------------------------------------------

GITHUB_USER="$(gh api user --jq '.login')"
REPO_NAME="$(basename "$PWD")"

REMOTE_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}.git"
APP_URL="https://${GITHUB_USER}.github.io/${REPO_NAME}/"
FORK_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}/fork"

# Phiên bản mặc định
VERSION="${1:-v1.0.0}"

echo "👤 GitHub user : $GITHUB_USER"
echo "📦 Repository  : $REPO_NAME"
echo "📄 Entry file  : index.html"
echo "🏷️ Version     : $VERSION"
echo ""

# ------------------------------------------------------------
# 6. Kiểm tra repository GitHub
# ------------------------------------------------------------

if ! gh repo view "${GITHUB_USER}/${REPO_NAME}" >/dev/null 2>&1; then

    echo "❌ Repository GitHub chưa tồn tại:"
    echo "   ${GITHUB_USER}/${REPO_NAME}"
    echo ""
    echo "Hãy tạo repository trên GitHub trước."
    exit 1
fi

echo "✅ Repository GitHub đã tồn tại."

# ------------------------------------------------------------
# 7. Git init
# ------------------------------------------------------------

if [ ! -d ".git" ]; then
    echo "🔧 Khởi tạo Git..."
    git init
else
    echo "✅ Git repository đã tồn tại."
fi

# ------------------------------------------------------------
# 8. Main branch
# ------------------------------------------------------------

git branch -M main

echo "✅ Branch: main"

# ------------------------------------------------------------
# 9. Remote origin
# ------------------------------------------------------------

if git remote get-url origin >/dev/null 2>&1; then

    CURRENT_REMOTE="$(git remote get-url origin)"

    echo "🔗 Remote hiện tại:"
    echo "   $CURRENT_REMOTE"

    if [ "$CURRENT_REMOTE" != "$REMOTE_URL" ]; then
        echo "🔧 Cập nhật origin..."
        git remote set-url origin "$REMOTE_URL"
    fi

else

    echo "🔗 Thêm origin:"
    echo "   $REMOTE_URL"

    git remote add origin "$REMOTE_URL"
fi

# ------------------------------------------------------------
# 10. Git add
# ------------------------------------------------------------

echo ""
echo "📦 git add ."

git add .

# ------------------------------------------------------------
# 11. Git commit
# ------------------------------------------------------------

if ! git diff --cached --quiet; then

    echo "📝 Tạo commit..."

    git commit -m "Deploy ${REPO_NAME}"

else

    echo "ℹ️ Không có thay đổi mới để commit."
fi

# ------------------------------------------------------------
# 12. Push main
# ------------------------------------------------------------

echo ""
echo "⬆️ Push main lên GitHub..."

git push -u origin main

# ------------------------------------------------------------
# 13. Tạo tag
# ------------------------------------------------------------

echo ""
echo "🏷️ Kiểm tra tag ${VERSION}..."

if git rev-parse "$VERSION" >/dev/null 2>&1; then

    echo "ℹ️ Tag ${VERSION} đã tồn tại."

else

    git tag -a "$VERSION" -m "${REPO_NAME} ${VERSION}"

    echo "✅ Đã tạo tag ${VERSION}."
fi

# ------------------------------------------------------------
# 14. Push tag
# ------------------------------------------------------------

echo ""
echo "⬆️ Push tag ${VERSION}..."

git push origin "$VERSION" || true

# ------------------------------------------------------------
# 15. GitHub Pages
# ------------------------------------------------------------

echo ""
echo "🌐 Kiểm tra GitHub Pages..."

if gh api "repos/${GITHUB_USER}/${REPO_NAME}/pages" >/dev/null 2>&1; then

    echo "✅ GitHub Pages đã được bật."

else

    echo "🚀 Đang bật GitHub Pages..."

    gh api \
        --method POST \
        "repos/${GITHUB_USER}/${REPO_NAME}/pages" \
        -f 'source[branch]=main' \
        -f 'source[path]=/' \
        -f 'build_type=legacy'

    echo "✅ GitHub Pages đã được kích hoạt."
fi

# ------------------------------------------------------------
# 16. Kết quả
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "              🎉 DEPLOY THÀNH CÔNG"
echo "============================================================"
echo ""
echo "📦 GITHUB:"
echo "https://github.com/${GITHUB_USER}/${REPO_NAME}"
echo ""
echo "🌐 LINK CHẠY ỨNG DỤNG:"
echo "$APP_URL"
echo ""
echo "🔀 LINK FORK CHO SINH VIÊN:"
echo "$FORK_URL"
echo ""
echo "🏷️ VERSION:"
echo "$VERSION"
echo ""
echo "============================================================"
echo ""
