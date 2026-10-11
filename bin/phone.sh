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

PHONE_SAVE_DIR="$HOME/Pictures/Phone"
mkdir -p "$PHONE_SAVE_DIR"

adb -s "$CONNECTED_DEV" shell "touch /sdcard/.phone_sync_marker" 2>/dev/null

PHONE_PULL_WATCHER_PID=""
(
    while true; do
        sleep 1.5
        NEW_FILES=$(adb -s "$CONNECTED_DEV" shell "find /sdcard/DCIM/Screenshots /sdcard/DCIM/Camera /sdcard/Pictures/Screenshots -maxdepth 1 -type f -newer /sdcard/.phone_sync_marker 2>/dev/null" 2>/dev/null | tr -d '\r')
        
        if [ -n "$NEW_FILES" ]; then
            adb -s "$CONNECTED_DEV" shell "touch /sdcard/.phone_sync_marker" 2>/dev/null
            
            while IFS= read -r f; do
                [ -z "$f" ] && continue
                FILENAME=$(basename "$f")
                if [[ "$FILENAME" == laptop_screenshot_* ]]; then
                    continue
                fi
                if [[ "$FILENAME" =~ \.(jpg|jpeg|png|webp|JPG|JPEG|PNG|WEBP)$ ]]; then
                    LOCAL_FILE="$PHONE_SAVE_DIR/$FILENAME"
                    adb -s "$CONNECTED_DEV" pull "$f" "$LOCAL_FILE" >/dev/null 2>&1
                    if [ -s "$LOCAL_FILE" ]; then
                        if command -v wl-copy >/dev/null 2>&1; then
                            if [[ "$FILENAME" =~ \.(jpg|jpeg|JPG|JPEG)$ ]]; then
                                wl-copy -t image/jpeg < "$LOCAL_FILE" 2>/dev/null || true
                            else
                                wl-copy -t image/png < "$LOCAL_FILE" 2>/dev/null || true
                            fi
                        elif command -v xclip >/dev/null 2>&1; then
                            xclip -selection clipboard -t image/png -i "$LOCAL_FILE" 2>/dev/null || true
                        fi
                        command -v notify-send >/dev/null 2>&1 && notify-send "📱 Phone Mirror" "📸 Đã lưu ảnh từ điện thoại vào máy tính!\n📁 $FILENAME (Đã copy vào Clipboard)" -i camera-photo
                    fi
                fi
            done <<< "$NEW_FILES"
        fi
    done
) &
PHONE_PULL_WATCHER_PID=$!

trap "kill $PHONE_PULL_WATCHER_PID 2>/dev/null; adb -s \"$CONNECTED_DEV\" shell \"rm -f /sdcard/.phone_sync_marker\" 2>/dev/null" EXIT INT TERM

echo "🚀 Khởi chạy phản chiếu màn hình điện thoại..."
scrcpy -s "$CONNECTED_DEV" "${OPTS[@]}"
