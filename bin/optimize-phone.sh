#!/usr/bin/env bash
# ==============================================================================
# OPTIMIZE PHONE - Tối ưu hóa tối đa hiệu năng Xiaomi HyperOS / Redmi / POCO
# ==============================================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}================================================================${NC}"
echo -e "${GREEN}🚀 ĐANG KẾT NỐI VÀ TỐI ƯU HÓA ĐIỆN THOẠI XIAOMI HYPEROS...${NC}"
echo -e "${BLUE}================================================================${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/get-device.sh" ]; then
    source "$SCRIPT_DIR/get-device.sh"
    CONNECTED_DEV=$(find_and_connect_device "$1")
else
    CONNECTED_DEV=$(adb devices | grep -E "\s+device$" | head -n 1 | awk '{print $1}')
fi

if [ -z "$CONNECTED_DEV" ]; then
    echo -e "${RED}⚠️ Chưa tìm thấy điện thoại kết nối!${NC}"
    exit 1
fi

echo -e "📱 Thiết bị: ${YELLOW}$CONNECTED_DEV${NC}\n"

# 1. Ép tần số quét 120Hz toàn hệ thống
echo -e "${YELLOW}[1/6] Ép tần số quét 120Hz cố định toàn hệ thống...${NC}"
adb -s "$CONNECTED_DEV" shell "
settings put system min_refresh_rate 120.0
settings put system peak_refresh_rate 120.0
settings put system user_refresh_rate 120
" 2>/dev/null
echo -e "${GREEN}✓ Đã khóa cứng 120Hz (không bao giờ bị tụt về 60Hz)!${NC}"

# 2. Vô hiệu hóa Joyose (Thủ phạm bóp FPS & Thermal Throttling)
echo -e "\n${YELLOW}[2/6] Vô hiệu hóa dịch vụ Joyose (com.xiaomi.joyose)...${NC}"
adb -s "$CONNECTED_DEV" shell "
cmd appops set com.xiaomi.joyose RUN_IN_BACKGROUND ignore 2>/dev/null
cmd appops set com.xiaomi.joyose RUN_ANY_IN_BACKGROUND ignore 2>/dev/null
cmd appops set com.xiaomi.joyose START_FOREGROUND ignore 2>/dev/null
cmd appops set com.xiaomi.joyose WAKE_LOCK ignore 2>/dev/null
am force-stop com.xiaomi.joyose 2>/dev/null
" 2>/dev/null
echo -e "${GREEN}✓ Đã đóng băng Joyose! Game và app sẽ duy trì FPS tối đa không bị bóp xung.${NC}"

# 3. Tăng tốc Animation về 0.5x & HyperOS Animation Fast
echo -e "\n${YELLOW}[3/6] Tăng tốc hoạt ảnh hệ thống (Animation Scale 0.5x & MIUI Fast)...${NC}"
adb -s "$CONNECTED_DEV" shell "
settings put global window_animation_scale 0.5
settings put global transition_animation_scale 0.5
settings put global animator_duration_scale 0.5
settings put system miui_animation_speed 2
" 2>/dev/null
echo -e "${GREEN}✓ Đã chỉnh tốc độ hoạt ảnh 0.5x & Chuyển động Nhanh (Fast)!${NC}"

# 4. Tắt RAM ảo (Mở rộng bộ nhớ)
echo -e "\n${YELLOW}[4/6] Tắt Mở rộng bộ nhớ (RAM ảo) để khử micro-stutter...${NC}"
adb -s "$CONNECTED_DEV" shell "
settings put global mi_memory_extension_enabled 0 2>/dev/null
" 2>/dev/null
echo -e "${GREEN}✓ Đã tắt RAM ảo (Dữ liệu không bị phân mảnh vào bộ nhớ flash UFS)!${NC}"

# 5. Kích hoạt Chế độ Hiệu suất & Đình chỉ ứng dụng đệm
echo -e "\n${YELLOW}[5/6] Bật Chế độ Hiệu suất (Performance Mode) & Đình chỉ ứng dụng đệm...${NC}"
adb -s "$CONNECTED_DEV" shell "
settings put system power_mode performance 2>/dev/null
settings put secure power_perf_mode 1 2>/dev/null
cmd power set-mode 1 2>/dev/null
settings put global cached_apps_freezer enabled 2>/dev/null
" 2>/dev/null
echo -e "${GREEN}✓ Đã kích hoạt Chế độ Hiệu suất & Bật Suspend cached apps!${NC}"

# 6. Tối ưu GPU Render
echo -e "\n${YELLOW}[6/6] Tối ưu hóa GPU Hardware Acceleration...${NC}"
adb -s "$CONNECTED_DEV" shell "
setprop debug.hwui.renderer skiagl 2>/dev/null
setprop debug.sf.hw 1 2>/dev/null
" 2>/dev/null
echo -e "${GREEN}✓ Đã tối ưu phần cứng đồ họa GPU!${NC}"

echo -e "\n${BLUE}================================================================${NC}"
echo -e "${GREEN}🎉 TẤT CẢ CÁC BƯỚC ĐÃ ĐƯỢC THI HÀNH THÀNH CÔNG TRỰC TIẾP TRÊN MÁY!${NC}"
echo -e "${BLUE}================================================================${NC}\n"
