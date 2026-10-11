#!/usr/bin/env bash
# ==============================================================================
# PHONE IN LINUX - Cài đặt tự động 1 click cho mọi máy Linux mới
# ==============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}================================================================${NC}"
echo -e "${GREEN}📱 CÀI ĐẶT PHONE IN LINUX (SCRCPY DUAL SCREEN & MIRROR WORKSPACE)${NC}"
echo -e "${BLUE}================================================================${NC}"

# 1. Phát hiện hệ điều hành & cài đặt gói phụ thuộc
echo -e "\n${YELLOW}[1/5] Kiểm tra và cài đặt các gói phụ thuộc cần thiết...${NC}"

install_dependencies() {
    if command -v pacman >/dev/null 2>&1; then
        echo "👉 Phát hiện Arch Linux / Manjaro / EndeavourOS..."
        sudo pacman -S --needed --noconfirm scrcpy android-tools wl-clipboard libnotify
    elif command -v apt-get >/dev/null 2>&1; then
        echo "👉 Phát hiện Ubuntu / Debian / Linux Mint..."
        sudo apt-get update
        sudo apt-get install -y scrcpy adb wl-clipboard libnotify-bin
    elif command -v dnf >/dev/null 2>&1; then
        echo "👉 Phát hiện Fedora / RHEL..."
        sudo dnf install -y scrcpy android-tools wl-clipboard libnotify
    elif command -v zypper >/dev/null 2>&1; then
        echo "👉 Phát hiện openSUSE..."
        sudo zypper install -y scrcpy android-tools wl-clipboard libnotify
    else
        echo -e "${RED}⚠️ Không thể nhận diện trình quản lý gói! Vui lòng cài đặt thủ công: scrcpy, adb, wl-clipboard.${NC}"
    fi
}

if ! command -v scrcpy >/dev/null 2>&1 || ! command -v adb >/dev/null 2>&1; then
    install_dependencies
else
    echo -e "${GREEN}✓ scrcpy và adb đã được cài đặt!${NC}"
fi

# 2. Cấu hình quyền Udev cho USB Android (Nếu có quyền sudo)
echo -e "\n${YELLOW}[2/5] Cấu hình quyền truy cập USB Android (udev rules)...${NC}"
if [ -d "/etc/udev/rules.d" ] && [ -w "/etc/udev/rules.d" -o -n "$SUDO_USER" ] || sudo -n true 2>/dev/null; then
    if sudo cp "$SCRIPT_DIR/udev/51-android.rules" /etc/udev/rules.d/51-android.rules 2>/dev/null; then
        sudo udevadm control --reload-rules 2>/dev/null || true
        sudo udevadm trigger 2>/dev/null || true
        echo -e "${GREEN}✓ Đã cấu hình /etc/udev/rules.d/51-android.rules thành công!${NC}"
    fi
else
    echo "ℹ️ Bỏ qua cài đặt udev rules cấp hệ thống (yêu cầu mật khẩu sudo)."
fi

# 3. Cài đặt các tệp thực thi vào ~/.local/bin
echo -e "\n${YELLOW}[3/5] Cài đặt các công cụ vào ~/.local/bin...${NC}"
mkdir -p "$HOME/.local/bin"

chmod +x "$SCRIPT_DIR/bin/"*.sh

ln -sf "$SCRIPT_DIR/bin/phone-dual.sh" "$HOME/.local/bin/phone-dual"
ln -sf "$SCRIPT_DIR/bin/phone.sh" "$HOME/.local/bin/phone"
ln -sf "$SCRIPT_DIR/bin/phone-tablet.sh" "$HOME/.local/bin/phone-tablet"
ln -sf "$SCRIPT_DIR/bin/phone-reset.sh" "$HOME/.local/bin/phone-reset"
ln -sf "$SCRIPT_DIR/bin/phone-clip.sh" "$HOME/.local/bin/phone-clip"
ln -sf "$SCRIPT_DIR/bin/phone-clip.sh" "$HOME/.local/bin/phone-paste"
ln -sf "$SCRIPT_DIR/bin/phone-snap.sh" "$HOME/.local/bin/phone-snap"
ln -sf "$SCRIPT_DIR/bin/optimize-phone.sh" "$HOME/.local/bin/optimize-phone"

# Đảm bảo ~/.local/bin nằm trong PATH
SHELL_RC="$HOME/.bashrc"
[ -n "$ZSH_VERSION" ] || [ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$SHELL_RC"
    echo "✓ Đã thêm ~/.local/bin vào PATH trong $SHELL_RC"
fi

echo -e "${GREEN}✓ Đã tạo liên kết các lệnh: phone-dual, phone, phone-tablet, phone-reset, phone-clip!${NC}"

# 4. Cài đặt Desktop Launchers
echo -e "\n${YELLOW}[4/5] Cài đặt biểu tượng khởi chạy ứng dụng (Desktop Launchers)...${NC}"
mkdir -p "$HOME/.local/share/applications"
cp -f "$SCRIPT_DIR/desktop/"*.desktop "$HOME/.local/share/applications/"
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
echo -e "${GREEN}✓ Đã cài đặt Desktop Launchers vào Menu ứng dụng!${NC}"

# 5. Khởi động ADB Server
echo -e "\n${YELLOW}[5/5] Khởi động ADB daemon...${NC}"
adb start-server >/dev/null 2>&1 || true

echo -e "\n${BLUE}================================================================${NC}"
echo -e "${GREEN}🎉 CÀI ĐẶT HOÀN TẤT THÀNH CÔNG!${NC}"
echo -e "${BLUE}================================================================${NC}"
echo -e "👉 Các lệnh sử dụng:"
echo -e "  - ${GREEN}phone-dual${NC}        : Mở ứng dụng trên Màn hình thứ 2 Độc lập (Co giãn tự do, Flex Ngang/Dọc)"
echo -e "  - ${GREEN}phone${NC}             : Phản chiếu màn hình điện thoại mượt mà 60 FPS"
echo -e "  - ${GREEN}phone-tablet${NC}      : Chuyển sang giao diện Máy tính bảng (Tablet ngang 2400x1080)"
echo -e "  - ${GREEN}phone-reset${NC}       : Khôi phục màn hình điện thoại về cài đặt gốc"
echo -e "  - ${GREEN}phone-clip${NC}        : Gửi ảnh chụp màn hình / clipboard từ laptop sang điện thoại"
echo -e "  - ${GREEN}phone-snap${NC}        : Chụp ảnh màn hình điện thoại từ máy tính lưu vào ~/Pictures/Phone"
echo -e "  - ${GREEN}optimize-phone${NC}    : Tối ưu 120Hz, tắt Joyose, giảm animation cho Xiaomi HyperOS"
echo -e "\n💡 Mẹo âm thanh cho phone-dual & phone:"
echo -e "  - Mặc định: Phát trực tiếp trên Loa Điện Thoại"
echo -e "  - Thêm ${YELLOW}-a${NC} hoặc ${YELLOW}--audio${NC}: Phát trên Loa Laptop"
echo -e "  - Thêm ${YELLOW}--dup${NC}: Phát trên cả hai loa cùng lúc"
echo -e "${BLUE}================================================================${NC}\n"
