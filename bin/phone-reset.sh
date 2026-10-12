#!/usr/bin/env bash
# ==============================================================================
# PHONE RESET - Khôi phục toàn bộ cài đặt màn hình điện thoại về mặc định
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/get-device.sh" ]; then
    source "$SCRIPT_DIR/get-device.sh"
    CONNECTED_DEV=$(find_and_connect_device "$1")
else
    CONNECTED_DEV=$(adb devices | grep -E "\s+device$" | head -n 1 | awk '{print $1}')
fi

if [ -z "$CONNECTED_DEV" ]; then
    echo "⚠️ Không tìm thấy thiết bị kết nối!"
    exit 1
fi

echo "🔄 Đang khôi phục cài đặt hiển thị & giao diện về mặc định..."
adb -s "$CONNECTED_DEV" shell wm size reset 2>/dev/null || true
adb -s "$CONNECTED_DEV" shell wm density reset 2>/dev/null || true
adb -s "$CONNECTED_DEV" shell settings put global force_desktop_mode_on_external_displays 0 2>/dev/null || true
adb -s "$CONNECTED_DEV" shell settings put global enable_freeform_support 1 2>/dev/null || true
adb -s "$CONNECTED_DEV" shell wm reset-letterbox-style 2>/dev/null || true
adb -s "$CONNECTED_DEV" shell wm reset-multi-window-config 2>/dev/null || true
adb -s "$CONNECTED_DEV" shell "am crash com.miui.home 2>/dev/null || pkill -f com.miui.home" 2>/dev/null || true

echo "✅ Đã khôi phục toàn bộ cài đặt màn hình về mặc định của nhà sản xuất!"
