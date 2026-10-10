#!/usr/bin/env bash
# ==============================================================================
# OPTIMIZE PHONE - Tối ưu hóa tối đa hiệu năng Xiaomi HyperOS / Redmi / POCO
# - Ép 120Hz cố định toàn hệ thống (không bao giờ tụt về 60Hz)
# - Tắt dịch vụ Joyose (Gỡ bỏ triệt để bóp FPS và hạ xung nhiệt độ của Xiaomi)
# - Chỉnh Animation về 0.5x siêu mượt, phản hồi chạm tức thì
# - Tắt mở rộng bộ nhớ (RAM ảo) khử micro-stutter
# - Kích hoạt chế độ Hiệu suất cao (Performance Mode)
# ==============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}================================================================${NC}"
echo -e "${GREEN}🚀 ĐANG KẾT NỐI VÀ TỐI ƯU HÓA ĐIỆN THOẠI XIAOMI HYPEROS...${NC}"
echo -e "${BLUE}================================================================${NC}"

# Tìm thiết bị
CONNECTED_DEV=$(adb devices | grep -E "(:[0-9]+|_tcp)\s+device" | head -n 1 | awk '{print $1}')
if [ -z "$CONNECTED_DEV" ]; then
    MDNS_DEV=$(adb mdns services 2>/dev/null | grep "_adb-tls-connect" | head -n 1 | awk '{print $NF}')
    if [ -n "$MDNS_DEV" ]; then
        echo "Đang kết nối tới $MDNS_DEV..."
        adb connect "$MDNS_DEV" >/dev/null 2>&1
        CONNECTED_DEV="$MDNS_DEV"
    fi
fi
if [ -z "$CONNECTED_DEV" ]; then
    USB_DEV=$(adb devices | grep -v "List" | grep -E "\s+device$" | head -n 1 | awk '{print $1}')
    [ -n "$USB_DEV" ] && CONNECTED_DEV="$USB_DEV"
fi

if [ -z "$CONNECTED_DEV" ]; then
    echo -e "${RED}⚠️ Chưa tìm thấy điện thoại kết nối!${NC}"
    echo -e "👉 Vui lòng mở điện thoại: Vào Cài đặt > Tùy chọn nhà phát triển > Bật 'Gỡ lỗi qua Wi-Fi' (hoặc cắm cáp USB)."
    exit 1
fi

echo -e "📱 Thiết bị: ${YELLOW}$CONNECTED_DEV${NC}\n"

# 1. Ép tần số quét 120Hz toàn hệ thống
echo -e "${YELLOW}[1/6] Ép tần số quét 120Hz cố định toàn hệ thống...${NC}"
adb -s "$CONNECTED_DEV" shell "
settings put system min_refresh_rate 120.0
settings put system peak_refresh_rate 120.0
settings put system user_refresh_rate 120
"
echo -e "${GREEN}✓ Đã khóa cứng 120Hz (không bị tụt về 60Hz khi dùng app thường)!${NC}"

# 2. Vô hiệu hóa Joyose (Gỡ bỏ bóp FPS khi máy ấm)
echo -e "\n${YELLOW}[2/6] Vô hiệu hóa Joyose (com.xiaomi.joyose)...${NC}"
if adb -s "$CONNECTED_DEV" shell "pm disable-user --user 0 com.xiaomi.joyose" 2>/dev/null; then
    echo -e "${GREEN}✓ Đã tắt Joyose thành công! Game và ứng dụng sẽ giữ FPS tối đa không bị bóp xung.${NC}"
else
    echo -e "${YELLOW}ℹ️ Không thể tắt Joyose (có thể cần bật 'Gỡ lỗi USB - Cài đặt bảo mật' trong Tùy chọn nhà phát triển).${NC}"
fi

# 3. Tăng tốc Animation về 0.5x
echo -e "\n${YELLOW}[3/6] Tăng tốc hoạt ảnh hệ thống (Animation Scale 0.5x)...${NC}"
adb -s "$CONNECTED_DEV" shell "
settings put global window_animation_scale 0.5
settings put global transition_animation_scale 0.5
settings put global animator_duration_scale 0.5
"
echo -e "${GREEN}✓ Đã chuyển tốc độ hoạt ảnh sang 0.5x (phản hồi chạm siêu tốc)!${NC}"

# 4. Tắt RAM ảo (Mở rộng bộ nhớ)
echo -e "\n${YELLOW}[4/6] Tắt Mở rộng bộ nhớ (RAM ảo) để khử micro-stutter...${NC}"
adb -s "$CONNECTED_DEV" shell "
settings put global mi_memory_extension_enabled 0 2>/dev/null
setprop persist.miui.extm.enable 0 2>/dev/null
"
echo -e "${GREEN}✓ Đã gửi lệnh tắt RAM ảo (Cần khởi động lại máy để áp dụng hoàn toàn).${NC}"

# 5. Kích hoạt Chế độ Hiệu suất (Performance Mode)
echo -e "\n${YELLOW}[5/6] Bật chế độ Hiệu suất pin...${NC}"
adb -s "$CONNECTED_DEV" shell "
settings put secure power_perf_mode 1 2>/dev/null
cmd power set-mode 1 2>/dev/null
"
echo -e "${GREEN}✓ Đã kích hoạt Chế độ Hiệu suất!${NC}"

# 6. Tối ưu GPU & Cảm ứng
echo -e "\n${YELLOW}[6/6] Tối ưu hóa GPU Renderer và cảm ứng...${NC}"
adb -s "$CONNECTED_DEV" shell "
setprop debug.hwui.renderer skiagl 2>/dev/null
setprop debug.sf.hw 1 2>/dev/null
setprop debug.egl.hw 1 2>/dev/null
"
echo -e "${GREEN}✓ Đã tối ưu hóa phần cứng đồ họa GPU!${NC}"

echo -e "\n${BLUE}================================================================${NC}"
echo -e "${GREEN}🎉 TỐI ƯU HÓA HOÀN TẤT THÀNH CÔNG!${NC}"
echo -e "${BLUE}================================================================${NC}"
echo -e "👉 Điện thoại của bạn hiện đã được ép 120Hz, tắt bóp xung Joyose và tăng tốc cảm ứng."
echo -e "💡 Khuyên dùng: Khởi động lại điện thoại 1 lần để RAM ảo được giải phóng hoàn toàn.\n"
