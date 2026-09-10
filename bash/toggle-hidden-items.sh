#!/usr/bin/env bash
# toggle_hidden_items.sh
# Toggle hiển thị/ẩn các file và thư mục ẩn trên macOS (Finder)

PREF_KEY="AppleShowAllFiles"
PREF_DOMAIN="com.apple.finder"

# Lấy giá trị hiện tại
current=$(defaults read "$PREF_DOMAIN" "$PREF_KEY" 2>/dev/null)

if [[ "$current" == "YES" || "$current" == "1" || "$current" == "true" ]]; then
    # Đang hiện -> Ẩn đi
    defaults write "$PREF_DOMAIN" "$PREF_KEY" -bool false
    echo "🙈 Hidden items: HIDDEN (file ẩn sẽ không hiển thị)"
else
    # Đang ẩn -> Hiện ra
    defaults write "$PREF_DOMAIN" "$PREF_KEY" -bool true
    echo "👁️  Hidden items: SHOW (file ẩn sẽ được hiển thị)"
fi

# Khởi động lại Finder để áp dụng thay đổi
killall Finder
echo "🔄 Finder đã được khởi động lại."
