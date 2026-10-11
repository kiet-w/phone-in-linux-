#!/usr/bin/env bash
# ==============================================================================
# PHONE SNAP - Chụp ảnh màn hình điện thoại từ máy tính và lưu thẳng vào ~/Pictures/Phone
# ==============================================================================

CONNECTED_DEV=$(adb devices | grep -E "(:[0-9]+|_tcp)\s+device" | head -n 1 | awk '{print $1}')
if [ -z "$CONNECTED_DEV" ]; then
    MDNS_DEV=$(adb mdns services 2>/dev/null | grep "_adb-tls-connect" | head -n 1 | awk '{print $NF}')
    [ -n "$MDNS_DEV" ] && CONNECTED_DEV="$MDNS_DEV"
fi
if [ -z "$CONNECTED_DEV" ]; then
    USB_DEV=$(adb devices | grep -v "List" | grep -E "\s+device$" | head -n 1 | awk '{print $1}')
    [ -n "$USB_DEV" ] && CONNECTED_DEV="$USB_DEV"
fi

if [ -z "$CONNECTED_DEV" ]; then
    echo "⚠️ Không tìm thấy điện thoại qua Wi-Fi hoặc USB!"
    exit 1
fi

PHONE_SAVE_DIR="$HOME/Pictures/Phone"
mkdir -p "$PHONE_SAVE_DIR"

FILENAME="phone_snapshot_$(date +%Y%m%d_%H%M%S).png"
DEST_FILE="$PHONE_SAVE_DIR/$FILENAME"

# Kiểm tra xem có màn hình ảo scrcpy không
VIRTUAL_DISPLAY_ID=$(adb -s "$CONNECTED_DEV" shell "dumpsys SurfaceFlinger --display-id 2>/dev/null" | grep -B 1 "Virtual display" | head -n 1 | awk '{print $2}')

if [ -n "$VIRTUAL_DISPLAY_ID" ] && [ "$VIRTUAL_DISPLAY_ID" != "0" ]; then
    adb -s "$CONNECTED_DEV" shell "screencap -d $VIRTUAL_DISPLAY_ID -p /sdcard/tmp_snap.png" >/dev/null 2>&1
    adb -s "$CONNECTED_DEV" pull /sdcard/tmp_snap.png "$DEST_FILE" >/dev/null 2>&1
    adb -s "$CONNECTED_DEV" shell "rm -f /sdcard/tmp_snap.png" >/dev/null 2>&1
else
    adb -s "$CONNECTED_DEV" exec-out screencap -p > "$DEST_FILE"
fi

if [ -s "$DEST_FILE" ]; then
    if command -v wl-copy >/dev/null 2>&1; then
        wl-copy -t image/png < "$DEST_FILE"
    elif command -v xclip >/dev/null 2>&1; then
        xclip -selection clipboard -t image/png -i "$DEST_FILE"
    fi
    echo "✅ Đã chụp ảnh màn hình điện thoại: $DEST_FILE"
    echo "📋 Đã copy sẵn vào Clipboard máy tính (Bấm Ctrl + V để dán ngay)!"
    command -v notify-send >/dev/null 2>&1 && notify-send "📱 Phone Snap" "📸 Đã chụp màn hình điện thoại!\n📁 $FILENAME (Đã copy vào Clipboard)" -i camera-photo
else
    echo "❌ Không thể chụp ảnh màn hình!"
    exit 1
fi
