#!/usr/bin/env bash
# ==============================================================================
# PHONE DUAL SCREEN - Màn hình thứ 2 Độc lập cho Android trên Linux (Scrcpy)
# Tính năng:
# - Tự động phát hiện thiết bị qua Wi-Fi (mDNS / IP) hoặc USB
# - Giao diện chọn ứng dụng tương tác đẹp mắt (hoặc truyền trực tiếp tên app)
# - Chế độ Flex Display Responsive: Co giãn tự do theo kích thước cửa sổ
# - Tự động thích ứng hướng Ngang (Landscape) hoặc Dọc (Portrait)
# - Xóa bỏ hoàn toàn khung trôi 3 chấm (• • •) & viền đen của Xiaomi HyperOS
# - Không gây lag/khựng cảm ứng: Cấu hình hệ thống 1 lần duy nhất cho mỗi cửa sổ
# - Hỗ trợ gõ tiếng Việt Telex phần cứng 100% (--keyboard=uhid)
# - Quản lý âm thanh linh hoạt: Mặc định loa điện thoại, hỗ trợ loa laptop (-a) hoặc cả hai (--dup)
# - Đồng bộ ảnh chụp màn hình / ảnh copy từ laptop sang điện thoại tự động
# - Kéo thả (Drag & Drop) ảnh/file trực tiếp vào điện thoại
# ==============================================================================

# Hàm kiểm tra trạng thái thiết bị thực sự kết nối và sẵn sàng
is_device_ready() {
    local target="$1"
    [ -n "$target" ] && [ "$(adb -s "$target" get-state 2>/dev/null)" = "device" ]
}

# 1. Kiểm tra các thiết bị ĐÃ kết nối và sẵn sàng
CONNECTED_DEV=""
READY_DEVS=($(adb devices | grep -E "\s+device$" | awk '{print $1}'))

if [ ${#READY_DEVS[@]} -eq 1 ]; then
    CONNECTED_DEV="${READY_DEVS[0]}"
elif [ ${#READY_DEVS[@]} -gt 1 ]; then
    echo "📱 Phát hiện nhiều thiết bị Android đang kết nối:"
    for i in "${!READY_DEVS[@]}"; do
        DEV_NAME=$(adb -s "${READY_DEVS[$i]}" shell getprop ro.product.model 2>/dev/null || echo "${READY_DEVS[$i]}")
        echo "  $((i+1))) ${READY_DEVS[$i]} ($DEV_NAME)"
    done
    read -rp "👉 Chọn thiết bị bạn muốn dùng [1]: " DEV_IDX
    DEV_IDX="${DEV_IDX:-1}"
    CONNECTED_DEV="${READY_DEVS[$((DEV_IDX-1))]}"
fi

# 2. Nếu chưa có thiết bị nào kết nối: Dò tìm qua mDNS
if [ -z "$CONNECTED_DEV" ]; then
    # Thử kết nối với thiết bị Xiaomi quen thuộc trước nếu có
    XIAOMI_MDNS=$(adb mdns services 2>/dev/null | grep "adb-y5byr4qszx5xxwga-auiTWP" | head -n 1 | awk '{print $NF}')
    if [ -n "$XIAOMI_MDNS" ]; then
        echo "Đang thử kết nối tới điện thoại của bạn tại $XIAOMI_MDNS..."
        adb connect "$XIAOMI_MDNS" >/dev/null 2>&1
        if is_device_ready "$XIAOMI_MDNS"; then
            CONNECTED_DEV="$XIAOMI_MDNS"
        fi
    fi
    
    # Nếu chưa được, duyệt qua các dịch vụ mDNS khác và kiểm tra kết nối thực tế
    if [ -z "$CONNECTED_DEV" ]; then
        MDNS_LIST=($(adb mdns services 2>/dev/null | grep "_adb-tls-connect" | awk '{print $NF}'))
        for endpoint in "${MDNS_LIST[@]}"; do
            echo "Đang kiểm tra kết nối tới $endpoint..."
            adb connect "$endpoint" >/dev/null 2>&1
            if is_device_ready "$endpoint"; then
                CONNECTED_DEV="$endpoint"
                break
            fi
        done
    fi
fi

# 3. Nếu vẫn chưa kết nối được: Cho phép nhập IP:Port hoặc hướng dẫn cắm cáp USB
while [ -z "$CONNECTED_DEV" ] || ! is_device_ready "$CONNECTED_DEV"; do
    echo "=========================================================="
    echo "⚠️ Chưa tìm thấy hoặc chưa kết nối được với điện thoại!"
    echo "👉 Hãy đảm bảo:"
    echo "   1) Cắm cáp USB nối điện thoại vào laptop (Khuyên dùng khi ở mạng công ty / trường học)"
    echo "   HOẶC"
    echo "   2) Trên điện thoại: Vào Cài đặt > Tùy chọn nhà phát triển > Bật 'Gỡ lỗi không dây'"
    echo "=========================================================="
    read -rp "👉 Nhập IP & Cổng hiển thị trên điện thoại (ví dụ: 10.45.111.225:45129) hoặc nhấn Enter để quét lại: " USER_INPUT_DEV
    
    if [ -n "$USER_INPUT_DEV" ]; then
        echo "Đang kết nối tới $USER_INPUT_DEV..."
        adb connect "$USER_INPUT_DEV"
        if is_device_ready "$USER_INPUT_DEV"; then
            CONNECTED_DEV="$USER_INPUT_DEV"
            break
        else
            echo "❌ Không thể kết nối tới $USER_INPUT_DEV. Vui lòng kiểm tra lại IP/Cổng và xác nhận 'Cho phép' trên màn hình điện thoại!"
        fi
    else
        # Thử kiểm tra lại thiết bị kết nối (ví dụ người dùng vừa cắm cáp USB hoặc vừa bật Wi-Fi debugging)
        NEW_DEV=$(adb devices | grep -E "\s+device$" | head -n 1 | awk '{print $1}')
        if [ -n "$NEW_DEV" ]; then
            CONNECTED_DEV="$NEW_DEV"
            break
        fi
    fi
done

echo "✅ Đã kết nối thành công với thiết bị: $CONNECTED_DEV"

# Xử lý cờ tuỳ chọn
FORCE_ORIENTATION=""
AUDIO_MODE="phone"   # "phone" (mặc định), "laptop" (-a), "both" (--dup)
SHOW_TOUCHES=false

while [[ "$1" == -* ]]; do
    case "$1" in
        -p|--portrait|-d|--doc)
            FORCE_ORIENTATION="portrait"
            shift
            ;;
        -l|--landscape|-n|--ngang)
            FORCE_ORIENTATION="landscape"
            shift
            ;;
        -a|--audio)
            AUDIO_MODE="laptop"
            shift
            ;;
        --dup|-dup)
            AUDIO_MODE="both"
            shift
            ;;
        -t|--touches|--show-touches)
            SHOW_TOUCHES=true
            shift
            ;;
        *)
            break
            ;;
    esac
done

INPUT_APP="$1"

# Danh sách ứng dụng phổ biến
declare -A POPULAR_APPS=(
    ["1"]="com.microsoft.teams|Microsoft Teams"
    ["2"]="com.zing.zalo|Zalo"
    ["3"]="com.google.android.youtube|YouTube"
    ["4"]="com.spotify.music|Spotify"
    ["5"]="com.facebook.orca|Messenger"
    ["6"]="com.discord|Discord"
    ["7"]="org.telegram.messenger|Telegram"
    ["8"]="com.google.android.gm|Gmail"
    ["9"]="com.android.chrome|Google Chrome"
    ["10"]="com.google.android.apps.messaging|Tin nhắn (SMS)"
    ["11"]="com.ss.android.ugc.trill|TikTok"
    ["12"]="com.facebook.katana|Facebook"
    ["13"]="com.miui.notes|Ghi chú (Notes)"
    ["14"]="com.google.android.calendar|Lịch (Calendar)"
)

# Hiển thị menu chọn nếu không truyền tham số
if [ -z "$INPUT_APP" ]; then
    echo "=========================================================="
    echo "📱 CHỌN ỨNG DỤNG MỞ TRÊN MÀN HÌNH ĐỘC LẬP THỨ 2:"
    echo "=========================================================="
    echo "  1) Microsoft Teams         8) Gmail"
    echo "  2) Zalo                    9) Google Chrome"
    echo "  3) YouTube                10) Tin nhắn SMS"
    echo "  4) Spotify                11) TikTok"
    echo "  5) Messenger              12) Facebook"
    echo "  6) Discord                13) Ghi chú (Notes)"
    echo "  7) Telegram               14) Lịch (Calendar)"
    echo "----------------------------------------------------------"
    echo "  C) Mở Màn hình chính (Trống) / Launcher phụ"
    echo "  L) Xem toàn bộ ứng dụng đang cài trên điện thoại"
    echo "=========================================================="
    read -rp "👉 Nhập số (1-14) hoặc tên ứng dụng bạn muốn mở [Mặc định 1]: " USER_CHOICE
    USER_CHOICE="${USER_CHOICE:-1}"

    if [[ "$USER_CHOICE" =~ ^[0-9]+$ ]] && [ -n "${POPULAR_APPS[$USER_CHOICE]}" ]; then
        PKG=$(echo "${POPULAR_APPS[$USER_CHOICE]}" | cut -d'|' -f1)
        APP_NAME=$(echo "${POPULAR_APPS[$USER_CHOICE]}" | cut -d'|' -f2)
    elif [ "$USER_CHOICE" = "C" ] || [ "$USER_CHOICE" = "c" ]; then
        PKG=""
        APP_NAME="Màn hình Trống (Secondary Launcher)"
    elif [ "$USER_CHOICE" = "L" ] || [ "$USER_CHOICE" = "l" ]; then
        echo "Đang tải danh sách ứng dụng đã cài đặt trên điện thoại..."
        OTHER_PACKAGES=$(adb -s "$CONNECTED_DEV" shell "pm list packages -3" 2>/dev/null | tr -d '\r' | sed 's/package://' | sort)
        echo "$OTHER_PACKAGES" | nl
        echo "----------------------------------------------------------"
        read -rp "👉 Nhập số thứ tự hoặc tên package: " PKG_INDEX
        if [[ "$PKG_INDEX" =~ ^[0-9]+$ ]]; then
            PKG=$(echo "$OTHER_PACKAGES" | sed -n "${PKG_INDEX}p")
            APP_NAME="$PKG"
        else
            PKG="$PKG_INDEX"
            APP_NAME="$PKG"
        fi
    else
        PKG="$USER_CHOICE"
        APP_NAME="$USER_CHOICE"
    fi
else
    case "$INPUT_APP" in
        teams|microsoft-teams) PKG="com.microsoft.teams"; APP_NAME="Microsoft Teams" ;;
        zalo) PKG="com.zing.zalo"; APP_NAME="Zalo" ;;
        youtube|yt) PKG="com.google.android.youtube"; APP_NAME="YouTube" ;;
        spotify) PKG="com.spotify.music"; APP_NAME="Spotify" ;;
        messenger|fb-messenger) PKG="com.facebook.orca"; APP_NAME="Messenger" ;;
        discord) PKG="com.discord"; APP_NAME="Discord" ;;
        telegram|tele) PKG="org.telegram.messenger"; APP_NAME="Telegram" ;;
        chrome) PKG="com.android.chrome"; APP_NAME="Google Chrome" ;;
        gmail) PKG="com.google.android.gm"; APP_NAME="Gmail" ;;
        tiktok) PKG="com.ss.android.ugc.trill"; APP_NAME="TikTok" ;;
        notes|note) PKG="com.miui.notes"; APP_NAME="Ghi chú" ;;
        *)
            PKG=$(adb -s "$CONNECTED_DEV" shell "pm list packages" 2>/dev/null | tr -d '\r' | sed 's/package://' | grep -i "$INPUT_APP" | head -n 1)
            if [ -z "$PKG" ]; then
                PKG="$INPUT_APP"
            fi
            APP_NAME="$PKG"
            ;;
    esac
fi

# Thiết lập tỷ lệ màn hình ban đầu
if [ "$FORCE_ORIENTATION" = "portrait" ]; then
    DISPLAY_RES="720x1280/280"
    ORIENTATION_TEXT="Chế độ Dọc (Portrait)"
elif [ "$FORCE_ORIENTATION" = "landscape" ]; then
    DISPLAY_RES="1280x720/280"
    ORIENTATION_TEXT="Chế độ Ngang (Landscape)"
else
    case "$PKG" in
        com.google.android.youtube|com.spotify.music)
            DISPLAY_RES="1280x720/280"
            ORIENTATION_TEXT="Tự động Khởi đầu Ngang (YouTube/Video) + Flex Responsive"
            ;;
        *)
            DISPLAY_RES="720x1280/280"
            ORIENTATION_TEXT="Tự động Khởi đầu Dọc (Chat/Đọc sách) + Flex Responsive"
            ;;
    esac
fi

echo "🚀 Đang khởi chạy: ${APP_NAME:-$PKG}"
echo "📐 Độ phân giải khởi đầu: $DISPLAY_RES ($ORIENTATION_TEXT)"
echo "✨ Kéo chuột ở góc cửa sổ để mở rộng Ngang/Dọc tuỳ ý (Flex Responsive)!"

# Tối ưu hóa cài đặt Android cho màn hình ngoài
adb -s "$CONNECTED_DEV" shell "settings put global enable_freeform_support 0" 2>/dev/null || true
adb -s "$CONNECTED_DEV" shell "settings put global force_resizable_activities 1" 2>/dev/null || true
adb -s "$CONNECTED_DEV" shell "settings put global force_desktop_mode_on_external_displays 1" 2>/dev/null || true
adb -s "$CONNECTED_DEV" shell "appops set com.android.shell READ_CLIPBOARD allow" 2>/dev/null || true
adb -s "$CONNECTED_DEV" shell "appops set com.android.shell WRITE_CLIPBOARD allow" 2>/dev/null || true

if [ -n "$PKG" ]; then
    adb -s "$CONNECTED_DEV" shell "am compat enable OVERRIDE_ANY_ORIENTATION $PKG" 2>/dev/null || true
    adb -s "$CONNECTED_DEV" shell "am compat enable OVERRIDE_ENABLE_COMPAT_IGNORE_REQUESTED_ORIENTATION $PKG" 2>/dev/null || true
    adb -s "$CONNECTED_DEV" shell "am compat enable OVERRIDE_ANY_ORIENTATION_TO_USER $PKG" 2>/dev/null || true
fi

# Tiến trình nền giám sát và cấu hình các màn hình ảo mới (Chạy 1 lần duy nhất để chống giật cảm ứng)
(
    CONFIGURED_IDS=""
    for i in {1..30}; do
        sleep 0.3
        SCRCPY_DISPLAYS=$(adb -s "$CONNECTED_DEV" shell "dumpsys display" 2>/dev/null | grep -oE 'DisplayInfo\{"scrcpy", displayId [0-9]+' | awk '{print $3}' | sort -u)
        for d in $SCRCPY_DISPLAYS; do
            if [ -n "$d" ] && [ "$d" != "0" ]; then
                if [[ ! " $CONFIGURED_IDS " =~ " $d " ]]; then
                    adb -s "$CONNECTED_DEV" shell "wm set-display-windowing-mode -d $d 1" 2>/dev/null
                    adb -s "$CONNECTED_DEV" shell "wm set-letterbox-style --aspectRatio 0 --minAspectRatioForUnresizable 0 --isUserAppAspectRatioFullscreenEnabled true" 2>/dev/null
                    adb -s "$CONNECTED_DEV" shell "wm set-multi-window-config --supportsNonResizable 1 --respectsActivityMinWidthHeight -1" 2>/dev/null
                    CONFIGURED_IDS="$CONFIGURED_IDS $d"
                fi
            fi
        done
        if [ -n "$CONFIGURED_IDS" ]; then
            sleep 1.7
        fi
    done
) &
WATCHER_PID=$!

# Tự động đồng bộ ảnh chụp màn hình / ảnh copy từ laptop sang điện thoại
CLIP_WATCHER_PID=""
if command -v wl-paste >/dev/null 2>&1; then
    (
        LAST_HASH=""
        while true; do
            if wl-paste -l 2>/dev/null | grep -q "image/"; then
                CURR_HASH=$(wl-paste -t image/png 2>/dev/null | md5sum | awk '{print $1}')
                if [ -n "$CURR_HASH" ] && [ "$CURR_HASH" != "$LAST_HASH" ]; then
                    LAST_HASH="$CURR_HASH"
                    FILENAME="laptop_screenshot_$(date +%Y%m%d_%H%M%S).png"
                    TMPFILE="/tmp/$FILENAME"
                    DEST_PHONE="/sdcard/Pictures/Screenshots/$FILENAME"
                    wl-paste -t image/png > "$TMPFILE" 2>/dev/null
                    if [ -s "$TMPFILE" ]; then
                        adb -s "$CONNECTED_DEV" push "$TMPFILE" "$DEST_PHONE" >/dev/null 2>&1
                        adb -s "$CONNECTED_DEV" shell "am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file://$DEST_PHONE" >/dev/null 2>&1
                        rm -f "$TMPFILE"
                        command -v notify-send >/dev/null 2>&1 && notify-send "📱 Phone Dual" "📸 Đã chuyển ảnh sang điện thoại! Bấm icon 📷 trên màn hình để chọn gửi." -i camera-photo
                    fi
                fi
            fi
            sleep 1.5
        done
    ) &
    CLIP_WATCHER_PID=$!
fi

# Tự động đồng bộ ảnh chụp từ Điện thoại về Laptop (Phone -> Laptop Auto-Sync)
# Khi chụp ảnh bằng Camera hoặc chụp màn hình trên điện thoại, ảnh sẽ tự động:
# 1. Tải về máy tính tại ~/Pictures/Phone/
# 2. Copy sẵn vào Clipboard máy tính (sẵn sàng Ctrl + V ngay lập tức)
# 3. Phát thông báo Desktop
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
                
                # Bỏ qua các file ảnh xuất phát từ laptop đẩy sang
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
                        
                        command -v notify-send >/dev/null 2>&1 && notify-send "📱 Phone Dual" "📸 Đã lưu ảnh từ điện thoại vào máy tính!\n📁 $FILENAME (Đã copy vào Clipboard)" -i camera-photo
                    fi
                fi
            done <<< "$NEW_FILES"
        fi
    done
) &
PHONE_PULL_WATCHER_PID=$!

trap "kill $WATCHER_PID $CLIP_WATCHER_PID $PHONE_PULL_WATCHER_PID 2>/dev/null; adb -s \"$CONNECTED_DEV\" shell \"rm -f /sdcard/.phone_sync_marker\" 2>/dev/null" EXIT INT TERM

WINDOW_TITLE="Dual: ${APP_NAME:-$PKG}"

OPTS=(
    --port=27183:27299
    --window-title="$WINDOW_TITLE"
    --new-display="$DISPLAY_RES"
    --flex-display
    --no-window-aspect-ratio-lock
    --push-target=/sdcard/Pictures/Screenshots/
    --video-codec=h264
    --max-size=1600
    --video-bit-rate=12M
    --max-fps=60
    --video-buffer=25
    --keyboard=uhid
)

if [ -n "$PKG" ]; then
    OPTS+=(--start-app="$PKG")
fi

if [ "$SHOW_TOUCHES" = "true" ]; then
    OPTS+=(--show-touches)
fi

if [ "$AUDIO_MODE" = "both" ]; then
    OPTS+=(--audio-buffer=50 --audio-dup)
    echo "🔊 Âm thanh: Phát cả trên Loa Laptop lẫn Loa Điện thoại (--audio-dup)"
elif [ "$AUDIO_MODE" = "laptop" ]; then
    OPTS+=(--audio-buffer=50)
    echo "🔊 Âm thanh: Chỉ phát trên Loa Laptop"
else
    OPTS+=(--no-audio)
    echo "📱 Âm thanh: Phát trực tiếp trên Loa Điện thoại (Laptop không phát)"
    adb -s "$CONNECTED_DEV" shell "cmd media_session volume --stream 3 --set 12" 2>/dev/null
fi

echo "🟢 Đang mở cửa sổ..."
scrcpy -s "$CONNECTED_DEV" "${OPTS[@]}"
