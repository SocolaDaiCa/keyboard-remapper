# ⌨️ Keyboard Remapper for macOS

Ứng dụng CLI viết bằng **Swift** chạy native trên macOS, sử dụng `CoreGraphics` (`CGEventTap`) để bắt và chuyển đổi phím / tổ hợp phím theo ý muốn với độ trễ cực thấp (near-zero latency).

Ví dụ:
- Nhấn **F5** ➔ tự động chuyển thành **Command (⌘) + R** (Refresh trình duyệt/Finder)
- Nhấn **F6** ➔ tự động chuyển thành **Command (⌘) + W** (Đóng tab)
- Nhấn **Ctrl + F5** ➔ tự động chuyển thành **Command (⌘) + Shift (⇧) + R** (Hard reload)

---

## 🛠 Yêu cầu hệ thống
- macOS 12 (Monterey) trở lên.
- Swift toolchain (có sẵn khi cài đặt Xcode hoặc Command Line Tools: `xcode-select --install`).

---

## 🚀 Cài đặt & Biên dịch

1. Di chuyển vào thư mục:
   ```bash
   cd keyboard-remapper
   ```

2. Biên dịch binary:
   ```bash
   chmod +x build.sh
   ./build.sh
   ```
   Hoặc bằng lệnh Swift chuẩn:
   ```bash
   swift build -c release
   cp $(swift build -c release --show-bin-path)/keyboard-remapper ./keyboard-remapper
   ```

---

## ⚠️ Cấp quyền Trợ năng (Accessibility) trên macOS

Để can thiệp phím ở cấp hệ thống, macOS yêu cầu cấp quyền **Trợ năng (Accessibility)**:

1. Chạy lệnh kiểm tra:
   ```bash
   ./keyboard-remapper --check-permission
   ```
2. Nếu chưa được cấp quyền, macOS sẽ tự động hiển thị popup yêu cầu hoặc bạn mở:
   - **System Settings** (Cài đặt hệ thống) ➔ **Privacy & Security** (Quyền riêng tư & Bảo mật) ➔ **Accessibility** (Trợ năng).
3. Bật công tắc **ON** cho ứng dụng terminal bạn đang dùng (ví dụ: **Terminal**, **iTerm2**, **Cursor**, **VS Code**, v.v.).

---

## 📖 Cách sử dụng

### 1. Chạy với cấu hình mặc định:
```bash
./keyboard-remapper
```
Chương trình sẽ tự động đọc file `config.json` tại thư mục hiện tại.

### 2. Bật chế độ hiển thị log chi tiết (Verbose):
```bash
./keyboard-remapper --verbose
```
Mỗi khi nhấn phím đã được remap, terminal sẽ hiển thị log real-time:
```
⚡ [DOWN] F5  ➔  ⌘ Cmd + R
⚡ [UP]   F5  ➔  ⌘ Cmd + R
```

### 3. Chỉ định file cấu hình khác:
```bash
./keyboard-remapper --config /path/to/my-config.json
```

### 4. Xem danh sách phím và modifier được hỗ trợ:
```bash
./keyboard-remapper --list-keys
```

### 5. Dừng chương trình:
Nhấn **Ctrl + C** trong Terminal bất cứ lúc nào để dừng.

---

## ⚙️ Cấu hình (`config.json`)

Cấu trúc file `config.json` rất đơn giản:

```json
{
  "verbose": false,
  "mappings": [
    {
      "from": { "key": "f5" },
      "to": { "key": "r", "modifiers": ["cmd"] }
    },
    {
      "from": { "key": "f6" },
      "to": { "key": "w", "modifiers": ["cmd"] }
    },
    {
      "from": { "key": "f5", "modifiers": ["ctrl"] },
      "to": { "key": "r", "modifiers": ["cmd", "shift"] }
    }
  ]
}
```

### Tên Modifiers hợp lệ:
- `cmd`, `command`, `win`, `windows` ➔ Phím Command (⌘)
- `ctrl`, `control` ➔ Phím Control (⌃)
- `alt`, `opt`, `option` ➔ Phím Option (⌥)
- `shift` ➔ Phím Shift (⇧)
- `fn` ➔ Phím Fn
