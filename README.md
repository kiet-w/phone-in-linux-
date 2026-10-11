# 📱 Phone in Linux (`phone-in-linux`)

> **Biến điện thoại Android thành Màn hình phụ thứ 2 Độc lập (Dual Screen) hoặc Phản chiếu (Mirror) 60 FPS siêu mượt trên Linux (Ubuntu, Arch, Fedora, Debian).**

Được tối ưu hóa đặc biệt cho **Xiaomi HyperOS / MIUI**, **Samsung OneUI**, **Google Pixel** và mọi thiết bị Android 10+ kết nối qua **Wi-Fi không dây** hoặc **cáp USB**.

---

## 🌟 Tính Năng Nổi Bật

* 🖥️ **Màn hình phụ Độc lập (Virtual Dual Display):** Mở bất kỳ ứng dụng Android nào (Teams, Zalo, YouTube, Spotify, Notes...) trên một màn hình riêng biệt trên Linux mà không chiếm màn hình chính của điện thoại.
* 🔄 **Flex Display Responsive:** Co giãn kích thước cửa sổ tự do bằng chuột. Tự động chuyển đổi mượt mà giữa chế độ **Dọc (Portrait)** khi cửa sổ cao hơn và **Ngang (Landscape)** khi cửa sổ rộng hơn.
* 🚫 **Không viền đen, Không nút 3 chấm:** Tự động loại bỏ hoàn toàn khung trôi nổi (`• • •`) và viền đen (letterboxing) của Xiaomi HyperOS.
* ⚡ **Mở nhiều ứng dụng cùng lúc:** Hỗ trợ mở nhiều cửa sổ `phone-dual` song song độc lập với dải cổng tự động (`27183-27299`).
* 🖐️ **Cảm ứng mượt mà 60 FPS:** Triệt tiêu hoàn toàn hiện tượng khựng/giật lag cảm ứng nhờ cơ chế cấu hình WindowManager 1 lần duy nhất cho mỗi màn hình ảo.
* ⌨️ **Gõ Tiếng Việt Telex phần cứng 100%:** Tích hợp `--keyboard=uhid` trực tiếp từ bàn phím laptop.
* 🔊 **Quản lý Âm thanh Thông minh:**
  * **Mặc định:** Âm thanh phát trên loa ngoài của Điện thoại.
  * Thêm cờ `-a` hoặc `--audio`: Phát trên Loa Laptop.
  * Thêm cờ `--dup`: Phát đồng thời trên cả Loa Laptop và Điện thoại.
* 📋 **Đồng bộ Clipboard 2 chiều & Ảnh chụp màn hình:**
  * Copy văn bản từ laptop $\leftrightarrow$ điện thoại mượt mà.
  * Tự động bắt ảnh chụp màn hình / ảnh copy trên laptop và bắn ngay vào Thư viện ảnh (`/sdcard/Pictures/Screenshots/`) trên điện thoại kèm thông báo desktop.
* 📂 **Kéo & Thả tập tin (Drag & Drop):** Kéo thả file ảnh/tài liệu từ máy tính vào cửa sổ scrcpy để chuyển thẳng vào điện thoại.

---

## 🚀 Cài Đặt 1-Click (Quick Install)

Khi sang máy mới, bạn chỉ cần chạy 2 lệnh sau:

```bash
git clone https://github.com/kiet-w/phone-in-linux-.git
cd phone-in-linux-
./install.sh
```

Trình cài đặt sẽ tự động:
1. Nhận diện bản phân phối Linux (Ubuntu, Debian, Arch Linux, Manjaro, Fedora...) và cài đặt các công cụ: `scrcpy`, `adb`, `wl-clipboard`, `libnotify`.
2. Thiết lập quyền truy cập thiết bị qua USB (`udev rules`).
3. Tạo các liên kết thực thi vào `~/.local/bin/`.
4. Cài đặt các biểu tượng Desktop Launcher vào Menu ứng dụng của Linux.

---

## ⚙️ Chuẩn Bị Trên Điện Thoại (Chỉ Làm 1 Lần)

1. **Bật Tùy chọn nhà phát triển (Developer Options):**
   * Vào **Cài đặt** $\rightarrow$ **Giới thiệu điện thoại** $\rightarrow$ Chạm 7 lần liên tục vào **Phiên bản OS / MIUI**.
2. **Bật Gỡ lỗi (Debugging):**
   * Vào **Cài đặt bổ sung** $\rightarrow$ **Tùy chọn nhà phát triển**.
   * Bật **Gỡ lỗi USB (USB Debugging)**.
   * *(Riêng Xiaomi)*: Bật thêm **Gỡ lỗi USB (Cài đặt bảo mật)** (*USB debugging (Security settings)*) để cho phép điều khiển chuột/phím và mở màn hình ngoài.
3. **Bật Gỡ lỗi qua Wi-Fi (Wireless Debugging):**
   * Bật mục **Gỡ lỗi qua Wi-Fi** (Wireless Debugging).
   * Đảm bảo laptop và điện thoại đang kết nối cùng một mạng Wi-Fi.

---

## 📖 Hướng Dẫn Sử Dụng

### 1. `phone-dual` (Màn hình phụ độc lập)

Chạy lệnh trong terminal hoặc bấm biểu tượng **Phone Dual Screen** trong menu ứng dụng:

```bash
phone-dual
```
* Sẽ hiển thị menu tương tác để bạn chọn app (Teams, Zalo, YouTube, Spotify, Chrome...).
* Bạn cũng có thể mở trực tiếp một app cụ thể:
  ```bash
  phone-dual teams         # Mở Microsoft Teams
  phone-dual zalo          # Mở Zalo
  phone-dual youtube       # Mở YouTube
  phone-dual spotify       # Mở Spotify
  ```

#### Cờ tùy chọn cho `phone-dual`:
| Cờ lệnh | Ý nghĩa |
| :--- | :--- |
| `-p` hoặc `-d` | Khởi đầu ở chế độ **Dọc (Portrait)** |
| `-l` hoặc `-n` | Khởi đầu ở chế độ **Ngang (Landscape)** |
| `-a` hoặc `--audio` | Chuyển âm thanh phát trên **Loa Laptop** |
| `--dup` | Phát âm thanh trên **cả hai loa** (Laptop + ĐT) |
| `-t` | Hiển thị chấm tròn vị trí chạm cảm ứng |

*Ví dụ:*
```bash
phone-dual -l youtube          # Mở YouTube chế độ ngang
phone-dual -a spotify          # Mở Spotify với âm thanh phát qua loa Laptop
```

---

### 2. `phone` (Phản chiếu màn hình chính)

Phản chiếu màn hình điện thoại gốc với độ trễ cực thấp, tốc độ khung hình 60 FPS:

```bash
phone                          # Mặc định loa điện thoại
phone -a                       # Phát âm thanh qua loa laptop
```

---

### 3. `phone-tablet` (Chế độ Máy tính bảng)

Chuyển đổi giao diện điện thoại thành máy tính bảng tỷ lệ ngang rộng 2400x1080:

```bash
phone-tablet
```

---

### 4. `phone-reset` (Khôi phục cài đặt gốc)

Khôi phục toàn bộ cài đặt độ phân giải, mật độ hiển thị DPI và cử chỉ vuốt về mặc định của nhà sản xuất:

```bash
phone-reset
```

---

### 5. `phone-clip` (Đẩy Clipboard & Ảnh chụp sang điện thoại)

```bash
phone-clip
```
* Nếu trên laptop vừa chụp ảnh màn hình / copy ảnh: Đẩy thẳng vào Thư viện ảnh của điện thoại.
* Nếu trên laptop copy chữ: Gửi lệnh dán trực tiếp vào điện thoại.

---

### 6. `phone-snap` (Chụp màn hình điện thoại từ máy tính)

```bash
phone-snap
```
* Chụp ảnh khung hình hiện tại của điện thoại (hoặc màn hình ảo `phone-dual`).
* Lưu thẳng file ảnh vào `~/Pictures/Phone/`.
* Tự động copy sẵn vào Clipboard của máy tính (bấm `Ctrl + V` để dán ngay).

---

### 7. `optimize-phone` (Tối ưu hiệu năng HyperOS)

```bash
optimize-phone
```
* Khóa cứng 120Hz toàn hệ thống (không bao giờ tụt về 60Hz).
* Đóng băng dịch vụ Joyose (loại bỏ bóp FPS và hạ xung khi ấm máy).
* Chỉnh tốc độ hoạt ảnh Animation về 0.5x & MIUI Fast siêu mượt.
* Tắt RAM ảo và kích hoạt Performance Mode.

---

## 📸 Đồng Bộ Ảnh Chụp 2 Chiều (Bi-directional Photo Sync)

> **Tính năng độc quyền trong `phone-dual` và `phone`:**

### 1. Khi chụp ảnh trên Điện thoại $\rightarrow$ Tự động lưu vào Laptop:
* Khi bạn đang bật `phone-dual`: Bất cứ khi nào bạn **chụp ảnh bằng Camera** hoặc **chụp ảnh màn hình (Screenshot)** trên điện thoại:
  * Ảnh sẽ **tự động được tải về máy tính** tại thư mục: `~/Pictures/Phone/`
  * Ảnh được **tự động nạp sẵn vào Clipboard của Laptop** $\rightarrow$ Bạn chỉ cần bấm **`Ctrl + V`** ở bất kỳ phần mềm nào trên máy tính là dán ảnh được ngay!
  * Máy tính sẽ phát thông báo Desktop báo ảnh đã sẵn sàng.

### 2. Khi chụp ảnh trên Laptop $\rightarrow$ Tự động gửi sang Điện thoại:
* Khi bạn chụp màn hình hoặc copy ảnh trên laptop: Ảnh được tự động đẩy ngay vào thư mục Thư viện ảnh của điện thoại (`/sdcard/Pictures/Screenshots/`).
* Trong ô chat Teams / Zalo, chỉ cần để ô chat trống và bấm biểu tượng **Máy ảnh 📷**, ảnh từ laptop sẽ nằm ngay đầu danh sách!

### 3. Kéo & Thả (Drag & Drop):
* Kéo thả trực tiếp file ảnh từ máy tính thả vào cửa sổ scrcpy của điện thoại.

---

## 🗑️ Gỡ Cài Đặt (Uninstall)

```bash
cd phone-in-linux-
./uninstall.sh
```

---

## 📜 Giấy Phép (License)

Dự án được phát hành theo giấy phép [MIT License](LICENSE).
Tác giả: [kiet-w](https://github.com/kiet-w)
