#!/usr/bin/env bash
# ==============================================================================
# PHONE CLIP - Gửi ảnh/ảnh chụp màn hình hoặc dán clipboard từ Laptop sang Phone
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
    echo "⚠️ Không tìm thấy điện thoại qua Wi-Fi hoặc USB!"
    exit 1
fi

TYPES=$(wl-paste -l 2>/dev/null || xclip -selection clipboard -t TARGETS -o 2>/dev/null || true)

if echo "$TYPES" | grep -q "image/"; then
    MIME=$(echo "$TYPES" | grep -m1 "image/")
    EXT="png"
    [ "$MIME" = "image/jpeg" ] && EXT="jpg"
    
    FILENAME="laptop_screenshot_$(date +%Y%m%d_%H%M%S).$EXT"
    TMPFILE="/tmp/$FILENAME"
    DEST_PHONE="/sdcard/Pictures/Screenshots/$FILENAME"
    
    wl-paste -t "$MIME" > "$TMPFILE" 2>/dev/null || true
    if [ -s "$TMPFILE" ]; then
        echo "🚀 Đang gửi ảnh sang điện thoại..."
        adb -s "$CONNECTED_DEV" push "$TMPFILE" "$DEST_PHONE" >/dev/null 2>&1
        adb -s "$CONNECTED_DEV" shell "am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file://$DEST_PHONE" >/dev/null 2>&1
        rm -f "$TMPFILE"
        echo "✅ Đã chuyển ảnh sang điện thoại thành công: $FILENAME"
        echo "👉 Bạn có thể vào Zalo, Teams hoặc Bộ sưu tập để bấm icon 📷 gửi ngay!"
        command -v notify-send >/dev/null 2>&1 && notify-send "📱 Phone Dual" "📸 Đã chuyển ảnh sang điện thoại! Bấm icon 📷 để gửi ngay." -i camera-photo
    fi
elif [ -n "$TYPES" ]; then
    adb -s "$CONNECTED_DEV" shell "input keyevent 279" 2>/dev/null || true
    echo "📋 Đã gửi lệnh dán nội dung sang điện thoại!"
    command -v notify-send >/dev/null 2>&1 && notify-send "📱 Phone Dual" "📋 Đã dán sang điện thoại!" -i edit-paste
else
    echo "⚠️ Khay nhớ tạm (Clipboard) của laptop hiện đang trống!"
fi
