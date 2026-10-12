#!/usr/bin/env bash
# ==============================================================================
# PHONE TABLET - Biến điện thoại thành máy tính bảng (Tablet 2400x1080)
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

echo "📐 Đang chuyển điện thoại sang giao diện Máy tính bảng (Tablet 2400x1080)..."
adb -s "$CONNECTED_DEV" shell wm size 2400x1080 2>/dev/null || true
adb -s "$CONNECTED_DEV" shell wm density 280 2>/dev/null || true

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
