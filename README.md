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

### 1. Chạy với cấu hình mặc định (UserConfig.swift):
```bash
./keyboard-remapper
# hoặc vừa build vừa chạy
./build.sh && ./keyboard-remapper
```
Mặc định, chương trình sẽ nạp trực tiếp cấu hình được định nghĩa trong `Sources/KeyboardRemapper/UserConfig.swift`.

### 2. Bật chế độ hiển thị log chi tiết (Verbose):
```bash
./keyboard-remapper --verbose
```
Mỗi khi nhấn phím đã được remap, terminal sẽ hiển thị log real-time:
```
⚡ [DOWN] F5  ➔  ⌘ Cmd + R
⚡ [UP]   F5  ➔  ⌘ Cmd + R
```

### 3. Chạy với file cấu hình JSON:
Nếu muốn tuỳ biến phím mà không cần biên dịch lại code:
```bash
./keyboard-remapper --config config.json
# hoặc đường dẫn tuỳ ý
./keyboard-remapper -c /path/to/custom-config.json
```

### 4. Xuất cấu hình từ Swift sang JSON:
```bash
./keyboard-remapper --export-json            # Xuất ra config.json
./keyboard-remapper --export-json my.json    # Xuất ra file chỉ định
```

### 5. Xem danh sách phím và modifier được hỗ trợ:
```bash
./keyboard-remapper --list-keys
```

### 6. Dừng chương trình:
Nhấn **Ctrl + C** hoặc **Ctrl + \** trong Terminal bất cứ lúc nào để dừng an toàn.

---

## ⚙️ Hướng dẫn Cấu hình

Có 2 cách cấu hình phím:

### Cách 1: Cấu hình bằng Swift (Mặc định & Khuyên dùng)
Chỉnh sửa file `Sources/KeyboardRemapper/UserConfig.swift`:
- **Auto-complete**: Có gợi ý mã nguồn (IntelliSense) ngay trong IDE khi gõ `keyboard.`
- **Cú pháp cực ngắn**: Sử dụng toán tử `=>`
- Sau khi chỉnh sửa, chỉ cần chạy `./build.sh` là xong!

```swift
public struct UserConfig {
    public static let verbose: Bool = false

    public static let mappings: [KeyMapping] = [
        // F2 ➔ Enter (Đổi tên file như Windows)
        keyboard.f2 => keyboard.enter,

        // F5 ➔ ⌘ Cmd + R (Tải lại trang)
        keyboard.f5 => keyboard.r.cmd,

        // ⌃ Ctrl + F5 ➔ ⇧ Shift + ⌘ Cmd + R (Hard reload)
        keyboard.f5.ctrl => keyboard.r.cmd.shift,

        // Alt + F4 ➔ ⌘ Cmd + Q (Thoát ứng dụng)
        keyboard.f4.alt => keyboard.q.cmd,

        // ⌃ Ctrl + C ➔ ⌘ Cmd + C (Copy)
        keyboard.c.ctrl => keyboard.c.cmd,

        // ⌃ Ctrl + V ➔ ⌘ Cmd + V (Paste)
        keyboard.v.ctrl => keyboard.v.cmd,

        // Home / End theo dòng
        keyboard.home => keyboard.left.cmd,
        keyboard.end  => keyboard.right.cmd,
    ]
}
```

### Cách 2: Cấu hình bằng JSON (`config.json`)
Dành cho trường hợp muốn thay đổi phím nóng runtime mà không cần compile lại:

```json
{
  "verbose": false,
  "mappings": [
    {
      "from": { "key": "f2" },
      "to": { "key": "enter" }
    },
    {
      "from": { "key": "f5" },
      "to": { "key": "r", "modifiers": ["cmd"] }
    },
    {
      "from": { "key": "c", "modifiers": ["ctrl"] },
      "to": { "key": "c", "modifiers": ["cmd"] }
    }
  ]
}
```

> **Gợi ý**: Bạn có thể sinh file `config.json` đầy đủ mẫu tự động bằng lệnh:
> ```bash
> ./keyboard-remapper --export-json
> ```

---

## ⌨️ Bảng Modifiers hỗ trợ

| Modifier | Cú pháp Swift DSL | Cú pháp JSON |
| :--- | :--- | :--- |
| **Command (⌘)** | `.cmd`, `.win` | `"cmd"`, `"command"`, `"win"`, `"windows"` |
| **Control (⌃)** | `.ctrl` | `"ctrl"`, `"control"` |
| **Option / Alt (⌥)** | `.alt`, `.opt` | `"alt"`, `"opt"`, `"option"` |
| **Shift (⇧)** | `.shift` | `"shift"` |
| **Fn** | `.fn` | `"fn"` |
