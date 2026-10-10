#!/usr/bin/env bash
# ==============================================================================
# PHONE TABLET - Biến điện thoại thành máy tính bảng (Tablet 2400x1080)
# ==============================================================================

set -e

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
    echo "⚠️ Không tìm thấy điện thoại qua Wi-Fi hoặc USB!"
    exit 1
fi

echo "📐 Đang chuyển điện thoại sang giao diện Máy tính bảng (Tablet 2400x1080)..."
adb -s "$CONNECTED_DEV" shell wm size 2400x1080 2>/dev/null
adb -s "$CONNECTED_DEV" shell wm density 280 2>/dev/null

ENABLE_AUDIO=false
if [[ "$*" =~ "--audio" || "$*" =~ "-a" ]]; then
    ENABLE_AUDIO=true
fi

OPTS=(
    --window-title="Phone Tablet (2400x1080)"
    --max-size=1600
    --video-bit-rate=16M
    --max-fps=60
    --video-buffer=0
    --keyboard=uhid
    --push-target=/sdcard/Pictures/Screenshots/
)

if [ "$ENABLE_AUDIO" = "true" ]; then
    OPTS+=(--audio-buffer=50)
else
    OPTS+=(--no-audio)
fi

echo "🚀 Mở scrcpy chế độ Tablet..."
scrcpy -s "$CONNECTED_DEV" "${OPTS[@]}"
