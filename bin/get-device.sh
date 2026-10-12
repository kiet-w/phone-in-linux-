#!/usr/bin/env bash
# ==============================================================================
# GET-DEVICE: Tìm và kết nối thiết bị Android một cách an toàn và chính xác
# - Ưu tiên thiết bị ĐÃ kết nối (USB hoặc Wi-Fi)
# - Xử lý thông minh khi có nhiều thiết bị (trên mạng trường học/công ty)
# - Tự động phát hiện Xiaomi quen thuộc qua mDNS
# - Hỗ trợ nhập thủ công IP & Cổng nếu mạng công cộng chặn quét
# ==============================================================================

is_device_ready() {
    local target="$1"
    [ -n "$target" ] && [ "$(adb -s "$target" get-state 2>/dev/null)" = "device" ]
}

find_and_connect_device() {
    local CONNECTED_DEV=""
    
    # 1. Kiểm tra tham số truyền vào nếu có dạng IP:Port hoặc serial
    if [ -n "$1" ] && [[ "$1" =~ :[0-9]+$ ]]; then
        echo "Đang thử kết nối tới tham số chỉ định: $1..."
        adb connect "$1" >/dev/null 2>&1
        if is_device_ready "$1"; then
            echo "$1"
            return 0
        fi
    fi

    # 2. Kiểm tra các thiết bị ĐÃ kết nối và sẵn sàng
    local READY_DEVS=($(adb devices | grep -E "\s+device$" | awk '{print $1}'))

    if [ ${#READY_DEVS[@]} -eq 1 ]; then
        echo "${READY_DEVS[0]}"
        return 0
    elif [ ${#READY_DEVS[@]} -gt 1 ]; then
        echo "📱 Phát hiện nhiều thiết bị Android đang kết nối:" >&2
        for i in "${!READY_DEVS[@]}"; do
            local DEV_NAME=$(adb -s "${READY_DEVS[$i]}" shell getprop ro.product.model 2>/dev/null || echo "${READY_DEVS[$i]}")
            echo "  $((i+1))) ${READY_DEVS[$i]} ($DEV_NAME)" >&2
        done
        read -rp "👉 Chọn thiết bị bạn muốn dùng [1]: " DEV_IDX >&2
        DEV_IDX="${DEV_IDX:-1}"
        echo "${READY_DEVS[$((DEV_IDX-1))]}"
        return 0
    fi

    # 3. Dò tìm qua mDNS
    local XIAOMI_MDNS=$(adb mdns services 2>/dev/null | grep "adb-y5byr4qszx5xxwga-auiTWP" | head -n 1 | awk '{print $NF}')
    if [ -n "$XIAOMI_MDNS" ]; then
        echo "Đang thử kết nối tới điện thoại của bạn tại $XIAOMI_MDNS..." >&2
        adb connect "$XIAOMI_MDNS" >/dev/null 2>&1
        if is_device_ready "$XIAOMI_MDNS"; then
            echo "$XIAOMI_MDNS"
            return 0
        fi
    fi

    local MDNS_LIST=($(adb mdns services 2>/dev/null | grep "_adb-tls-connect" | awk '{print $NF}'))
    for endpoint in "${MDNS_LIST[@]}"; do
        echo "Đang kiểm tra kết nối tới $endpoint..." >&2
        adb connect "$endpoint" >/dev/null 2>&1
        if is_device_ready "$endpoint"; then
            echo "$endpoint"
            return 0
        fi
    done

    # 4. Nếu vẫn chưa kết nối được: Yêu cầu người dùng cắm USB hoặc nhập IP:Port
    while [ -z "$CONNECTED_DEV" ] || ! is_device_ready "$CONNECTED_DEV"; do
        echo "==========================================================" >&2
        echo "⚠️ Chưa tìm thấy điện thoại kết nối!" >&2
        echo "👉 Bạn hãy chọn 1 trong 2 cách:" >&2
        echo "   1) Cắm cáp USB sạc nối điện thoại vào laptop (Khuyên dùng khi ở mạng công ty/trường học)" >&2
        echo "   HOẶC" >&2
        echo "   2) Mở điện thoại: Vào Cài đặt > Tùy chọn nhà phát triển > Bật 'Gỡ lỗi không dây'" >&2
        echo "==========================================================" >&2
        read -rp "👉 Nhập IP & Cổng trên màn hình điện thoại (ví dụ: 10.45.111.225:45129) hoặc nhấn Enter để quét lại: " USER_INPUT >&2

        if [ -n "$USER_INPUT" ]; then
            echo "Đang kết nối tới $USER_INPUT..." >&2
            adb connect "$USER_INPUT" >&2
            if is_device_ready "$USER_INPUT"; then
                CONNECTED_DEV="$USER_INPUT"
                break
            else
                echo "❌ Không thể kết nối tới $USER_INPUT. Vui lòng kiểm tra lại IP/Cổng và xác nhận 'Cho phép' trên màn hình điện thoại!" >&2
            fi
        else
            local NEW_DEV=$(adb devices | grep -E "\s+device$" | head -n 1 | awk '{print $1}')
            if [ -n "$NEW_DEV" ]; then
                CONNECTED_DEV="$NEW_DEV"
                break
            fi
        fi
    done

    echo "$CONNECTED_DEV"
    return 0
}
