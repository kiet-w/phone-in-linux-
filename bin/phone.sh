#!/usr/bin/env bash
# ==============================================================================
# PHONE MIRROR - Phản chiếu màn hình điện thoại mượt mà 60 FPS chống giật
# - Tự động dò tìm điện thoại qua Wi-Fi (mDNS / IP) hoặc cáp USB
# - Cấu hình triệt tiêu rung giật (jitter buffer 25ms, max-fps 60, codec H.264 phần cứng)
# - Bàn phím phần cứng UHID gõ tiếng Việt Telex
# - Tự động đồng bộ Clipboard 2 chiều giữa điện thoại và máy tính
# - Mặc định phát âm thanh trên điện thoại (--no-audio)
# ==============================================================================

set -e

echo "Đang tìm điện thoại qua mạng Wi-Fi hoặc USB..."

CONNECTED_DEV=$(adb devices | grep -E "(:[0-9]+|_tcp)\s+device" | head -n 1 | awk '{print $1}')
if [ -z "$CONNECTED_DEV" ]; then
    MDNS_DEV=$(adb mdns services 2>/dev/null | grep "_adb-tls-connect" | head -n 1 | awk '{print $NF}')
    if [ -n "$MDNS_DEV" ]; then
        echo "Đã tìm thấy điện thoại tại $MDNS_DEV, đang kết nối..."
        adb connect "$MDNS_DEV" >/dev/null 2>&1
        CONNECTED_DEV="$MDNS_DEV"
    fi
fi
if [ -z "$CONNECTED_DEV" ]; then
    USB_DEV=$(adb devices | grep -v "List" | grep -E "\s+device$" | head -n 1 | awk '{print $1}')
    if [ -n "$USB_DEV" ]; then
        CONNECTED_DEV="$USB_DEV"
    fi
fi

if [ -z "$CONNECTED_DEV" ]; then
    echo "⚠️ Không tìm thấy điện thoại qua Wi-Fi hoặc USB!"
    echo "👉 Hãy đảm bảo điện thoại đã bật 'Gỡ lỗi qua Wi-Fi' (Wireless Debugging) hoặc cắm cáp USB."
    exit 1
fi

ENABLE_AUDIO=false
if [[ "$*" =~ "--audio" || "$*" =~ "-a" ]]; then
    ENABLE_AUDIO=true
fi

OPTS=(
    --window-title="Phone Mirror"
    --video-codec=h264
    --max-size=1080
    --video-bit-rate=12M
    --max-fps=60
    --video-buffer=25
    --keyboard=uhid
    --push-target=/sdcard/Pictures/Screenshots/
)

if [ "$ENABLE_AUDIO" = "true" ]; then
    OPTS+=(--audio-buffer=50)
    echo "🔊 Âm thanh: Phát trên Loa Laptop"
else
    OPTS+=(--no-audio)
    echo "📱 Âm thanh: Phát trực tiếp trên Loa Điện thoại"
fi

echo "🚀 Khởi chạy phản chiếu màn hình điện thoại..."
scrcpy -s "$CONNECTED_DEV" "${OPTS[@]}"
