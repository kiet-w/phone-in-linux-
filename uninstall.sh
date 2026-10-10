#!/usr/bin/env bash
# ==============================================================================
# PHONE IN LINUX - Gỡ cài đặt hoàn toàn
# ==============================================================================

echo "Đang gỡ cài đặt Phone in Linux..."

rm -f "$HOME/.local/bin/phone-dual"
rm -f "$HOME/.local/bin/phone"
rm -f "$HOME/.local/bin/phone-tablet"
rm -f "$HOME/.local/bin/phone-reset"
rm -f "$HOME/.local/bin/phone-clip"
rm -f "$HOME/.local/bin/phone-paste"

rm -f "$HOME/.local/share/applications/phone-dual.desktop"
rm -f "$HOME/.local/share/applications/phone.desktop"
rm -f "$HOME/.local/share/applications/phone-tablet.desktop"

update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

echo "✅ Đã gỡ cài đặt các liên kết lệnh và desktop launcher thành công!"
