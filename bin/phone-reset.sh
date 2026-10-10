#!/usr/bin/env bash
# ==============================================================================
# PHONE RESET - Khôi phục toàn bộ cài đặt màn hình điện thoại về mặc định
# ==============================================================================

CONNECTED_DEV=$(adb devices | grep -E "(:[0-9]+|_tcp)\s+device" | head -n 1 | awk '{print $1}')
if [ -z "$CONNECTED_DEV" ]; then
    MDNS_DEV=$(adb mdns services 2>/dev/null | grep "_adb-tls-connect" | head -n 1 | awk '{print $NF}')
    if [ -n "$MDNS_DEV" ]; then
        adb connect "$MDNS_DEV" >/dev/null 2>&1
        CONNECTED_DEV="$MDNS_DEV"
    fi
fi
if [ -z "$CONNECTED_DEV" ]; then
    USB_DEV=$(adb devices | grep -v "List" | grep -E "\s+device$" | head -n 1 | awk '{print $1}')
    [ -n "$USB_DEV" ] && CONNECTED_DEV="$USB_DEV"
fi

if [ -z "$CONNECTED_DEV" ]; then
    echo "⚠️ Không tìm thấy điện thoại!"
    exit 1
fi

echo "🔄 Đang khôi phục cài đặt hiển thị & giao diện về mặc định..."
adb -s "$CONNECTED_DEV" shell wm size reset 2>/dev/null
adb -s "$CONNECTED_DEV" shell wm density reset 2>/dev/null
adb -s "$CONNECTED_DEV" shell settings put global force_desktop_mode_on_external_displays 0 2>/dev/null
adb -s "$CONNECTED_DEV" shell settings put global enable_freeform_support 1 2>/dev/null
adb -s "$CONNECTED_DEV" shell wm reset-letterbox-style 2>/dev/null
adb -s "$CONNECTED_DEV" shell wm reset-multi-window-config 2>/dev/null
adb -s "$CONNECTED_DEV" shell "am crash com.miui.home 2>/dev/null || pkill -f com.miui.home" 2>/dev/null

echo "✅ Đã khôi phục toàn bộ cài đặt màn hình về mặc định của nhà sản xuất!"
