import Foundation

/// ⚙️ FILE CẤU HÌNH BÀN PHÍM (USER CONFIG)
///
/// 💡 HƯỚNG DẪN SỬ DỤNG:
/// - Bạn có thể dễ dàng thiết lập phím bằng cách gõ `keyboard.` hoặc `Keyboard.`
///   Trình soạn thảo sẽ tự động gợi ý (Auto-complete / IntelliSense) toàn bộ danh sách phím!
///
/// 💡 CÁCH GẮN MODIFIER (Phím bổ trợ):
/// - Dùng dấu chấm nối tiếp: `keyboard.r.cmd`, `keyboard.r.cmd.shift`, `keyboard.f5.ctrl`
/// - Hoặc dùng toán tử + : `keyboard.r + .cmd + .shift`
/// - Hoặc dùng hàm `.with(...)`: `keyboard.r.with(.cmd, .shift)`
///
/// 💡 CÁCH REMAP PHÍM:
/// - Cú pháp ngắn gọn: `keyboard.<phím_gốc> => keyboard.<phím_đích>`
///   Ví dụ: `keyboard.f5 => keyboard.r.cmd`
///
/// 🚀 SAU KHI SỬA FILE NÀY:
/// - Chỉ cần chạy lệnh: `./build.sh` để biên dịch lại nháy mắt!
public struct UserConfig {
    /// Bật chế độ log chi tiết mỗi khi nhấn phím (true: Bật, false: Tắt)
    public static let verbose: Bool = false

    /// Bật chế độ chuyển đổi Control + Click thành Command + Click
    /// (true: Bật — ⌃ Ctrl+Click sẽ hoạt động như ⌘ Cmd+Click để mở link trong tab mới, v.v.)
    public static let controlClickToCommandClick: Bool = true

    /// Danh sách các quy tắc ánh xạ phím (Key Mappings)
    public static let mappings: [KeyMapping] = [
        // =================================================================
        // 1. Phím chức năng hệ thống (Windows Function Keys)
        // =================================================================
        // F2 ➔ Enter (Đổi tên file trong Finder như Windows Explorer)
        keyboard.f2 => keyboard.enter,

        // F5 ➔ ⌘ Cmd + R (Tải lại trang / Reload)
        keyboard.f5 => keyboard.r.cmd,

        // ⌃ Ctrl + F5 ➔ ⇧ Shift + ⌘ Cmd + R (Tải lại cứng / Hard reload bỏ cache)
        keyboard.f5.ctrl => keyboard.r.cmd.shift,

        // F6 ➔ ⌘ Cmd + W (Đóng tab hiện tại)
        keyboard.f6 => keyboard.w.cmd,

        // Alt + F4 ➔ ⌘ Cmd + Q (Đóng ứng dụng hoàn toàn như Windows)
        keyboard.f4.alt => keyboard.q.cmd,

        // F11 ➔ ⌃ Ctrl + ⌘ Cmd + F (Bật/tắt chế độ toàn màn hình Full Screen)
        keyboard.f11 => keyboard.f.cmd.ctrl,

        // PrtSc / PctSc ➔ ⌃ Ctrl + ⇧ Shift + ⌘ Cmd + 4 (Chụp ảnh màn hình vùng chọn & Tự động sao chép vào Clipboard)
        keyboard.pctSc => keyboard.num4.cmd.shift.ctrl,

        // =================================================================
        // 2. Thao tác Clipboard & Chỉnh sửa cơ bản (Clipboard & Editing)
        // =================================================================
        // ⌃ Ctrl + A ➔ ⌘ Cmd + A (Chọn tất cả / Select All)
        keyboard.a.ctrl => keyboard.a.cmd,

        // ⌃ Ctrl + C ➔ ⌘ Cmd + C (Sao chép / Copy)
        keyboard.c.ctrl => keyboard.c.cmd,

        // ⌃ Ctrl + X ➔ ⌘ Cmd + X (Cắt / Cut)
        keyboard.x.ctrl => keyboard.x.cmd,

        // ⌃ Ctrl + V ➔ ⌘ Cmd + V (Dán / Paste)
        keyboard.v.ctrl => keyboard.v.cmd,

        // ⌃ Ctrl + Z ➔ ⌘ Cmd + Z (Hoàn tác / Undo)
        keyboard.z.ctrl => keyboard.z.cmd,

        // ⌃ Ctrl + Y ➔ ⇧ Shift + ⌘ Cmd + Z (Làm lại / Redo theo chuẩn Windows)
        keyboard.y.ctrl => keyboard.z.cmd.shift,

        // ⌃ Ctrl + ⇧ Shift + Z ➔ ⇧ Shift + ⌘ Cmd + Z (Làm lại / Redo)
        keyboard.z.ctrl.shift => keyboard.z.cmd.shift,

        // =================================================================
        // 3. Quản lý File & Cửa sổ (File & Window Operations)
        // =================================================================
        // ⌃ Ctrl + S ➔ ⌘ Cmd + S (Lưu / Save)
        keyboard.s.ctrl => keyboard.s.cmd,

        // ⌃ Ctrl + ⇧ Shift + S ➔ ⇧ Shift + ⌘ Cmd + S (Lưu bản sao / Save As)
        keyboard.s.ctrl.shift => keyboard.s.cmd.shift,

        // ⌃ Ctrl + O ➔ ⌘ Cmd + O (Mở file / Open)
        keyboard.o.ctrl => keyboard.o.cmd,

        // ⌃ Ctrl + N ➔ ⌘ Cmd + N (Tạo mới / New Window / New Document)
        keyboard.n.ctrl => keyboard.n.cmd,

        // ⌃ Ctrl + ⇧ Shift + N ➔ ⇧ Shift + ⌘ Cmd + N (Cửa sổ ẩn danh / Thư mục mới)
        keyboard.n.ctrl.shift => keyboard.n.cmd.shift,

        // ⌃ Ctrl + P ➔ ⌘ Cmd + P (In ấn / Quick Open file trong editor)
        keyboard.p.ctrl => keyboard.p.cmd,

        // ⌃ Ctrl + ⇧ Shift + P ➔ ⇧ Shift + ⌘ Cmd + P (Command Palette trong VS Code, Sublime)
        keyboard.p.ctrl.shift => keyboard.p.cmd.shift,

        // =================================================================
        // 4. Tìm kiếm (Search & Find)
        // =================================================================
        // ⌃ Ctrl + F ➔ ⌘ Cmd + F (Tìm kiếm / Find)
        keyboard.f.ctrl => keyboard.f.cmd,

        // ⌃ Ctrl + ⇧ Shift + F ➔ ⇧ Shift + ⌘ Cmd + F (Tìm trong toàn bộ dự án / Find in Files)
        keyboard.f.ctrl.shift => keyboard.f.cmd.shift,

        // ⌃ Ctrl + G ➔ ⌘ Cmd + G (Tìm kết quả tiếp theo / Find Next)
        keyboard.g.ctrl => keyboard.g.cmd,

        // ⌃ Ctrl + ⇧ Shift + G ➔ ⇧ Shift + ⌘ Cmd + G (Tìm kết quả trước đó / Find Previous)
        keyboard.g.ctrl.shift => keyboard.g.cmd.shift,

        // =================================================================
        // 5. Trình duyệt Web & Quản lý Tab (Browser & Tabs)
        // =================================================================
        // ⌃ Ctrl + T ➔ ⌘ Cmd + T (Mở tab mới)
        keyboard.t.ctrl => keyboard.t.cmd,

        // ⌃ Ctrl + ⇧ Shift + T ➔ ⇧ Shift + ⌘ Cmd + T (Mở lại tab vừa đóng)
        keyboard.t.ctrl.shift => keyboard.t.cmd.shift,

        // ⌃ Ctrl + W ➔ ⌘ Cmd + W (Đóng tab hiện tại)
        keyboard.w.ctrl => keyboard.w.cmd,

        // ⌃ Ctrl + ⇧ Shift + W ➔ ⇧ Shift + ⌘ Cmd + W (Đóng toàn bộ cửa sổ)
        keyboard.w.ctrl.shift => keyboard.w.cmd.shift,

        // ⌃ Ctrl + ⇧ Shift + R ➔ ⇧ Shift + ⌘ Cmd + R (Tải lại bỏ cache)
        keyboard.r.ctrl.shift => keyboard.r.cmd.shift,

        // ⌃ Ctrl + L ➔ ⌘ Cmd + L (Nhảy lên thanh địa chỉ URL)
        keyboard.l.ctrl => keyboard.l.cmd,

        // ⌃ Ctrl + D ➔ ⌘ Cmd + D (Đánh dấu trang Bookmark / Multi-cursor trong code)
        keyboard.d.ctrl => keyboard.d.cmd,

        // ⌃ Ctrl + J ➔ ⌘ Cmd + J (Tải xuống / Toggle Panel)
        keyboard.j.ctrl => keyboard.j.cmd,

        // ⌃ Ctrl + Enter ➔ ⌘ Cmd + Enter (Gửi tin nhắn / Submit form)
        keyboard.enter.ctrl => keyboard.enter.cmd,

        // =================================================================
        // 6. Chuyển Tab nhanh 1 - 9 (Switch to Tab 1-9)
        // =================================================================
        keyboard.num1.ctrl => keyboard.num1.cmd,
        keyboard.num2.ctrl => keyboard.num2.cmd,
        keyboard.num3.ctrl => keyboard.num3.cmd,
        keyboard.num4.ctrl => keyboard.num4.cmd,
        keyboard.num5.ctrl => keyboard.num5.cmd,
        keyboard.num6.ctrl => keyboard.num6.cmd,
        keyboard.num7.ctrl => keyboard.num7.cmd,
        keyboard.num8.ctrl => keyboard.num8.cmd,
        keyboard.num9.ctrl => keyboard.num9.cmd,

        // =================================================================
        // 7. Phóng to / Thu nhỏ (Zoom In / Out / Reset)
        // =================================================================
        // ⌃ Ctrl + = ➔ ⌘ Cmd + = (Phóng to / Zoom In)
        keyboard.equal.ctrl => keyboard.equal.cmd,

        // ⌃ Ctrl + - ➔ ⌘ Cmd + - (Thu nhỏ / Zoom Out)
        keyboard.minus.ctrl => keyboard.minus.cmd,

        // ⌃ Ctrl + 0 ➔ ⌘ Cmd + 0 (Khôi phục kích thước chuẩn / Reset Zoom)
        keyboard.num0.ctrl => keyboard.num0.cmd,

        // =================================================================
        // 8. Định dạng văn bản & Soạn thảo Code (Formatting & Coding)
        // =================================================================
        // ⌃ Ctrl + B ➔ ⌘ Cmd + B (In đậm / Toggle Sidebar trong VS Code)
        keyboard.b.ctrl => keyboard.b.cmd,

        // ⌃ Ctrl + I ➔ ⌘ Cmd + I (In nghiêng)
        keyboard.i.ctrl => keyboard.i.cmd,

        // ⌃ Ctrl + U ➔ ⌘ Cmd + U (Gạch chân)
        keyboard.u.ctrl => keyboard.u.cmd,

        // ⌃ Ctrl + K ➔ ⌘ Cmd + K (Chèn link / Quick open)
        keyboard.k.ctrl => keyboard.k.cmd,

        // ⌃ Ctrl + / ➔ ⌘ Cmd + / (Bật/tắt chú thích dòng / Toggle Comment)
        keyboard.slash.ctrl => keyboard.slash.cmd,

        // =================================================================
        // 9. Điều hướng Home / End như trên Windows (Cực kỳ hữu ích!)
        // =================================================================
        // Home ➔ ⌘ Cmd + ← (Nhảy về đầu dòng)
        keyboard.home => keyboard.left.cmd,

        // End ➔ ⌘ Cmd + → (Nhảy về cuối dòng)
        keyboard.end => keyboard.right.cmd,

        // ⇧ Shift + Home ➔ ⇧ Shift + ⌘ Cmd + ← (Bôi đen về đầu dòng)
        keyboard.home.shift => keyboard.left.cmd.shift,

        // ⇧ Shift + End ➔ ⇧ Shift + ⌘ Cmd + → (Bôi đen về cuối dòng)
        keyboard.end.shift => keyboard.right.cmd.shift,

        // ⌃ Ctrl + Home ➔ ⌘ Cmd + ↑ (Nhảy về đầu tài liệu / trang)
        keyboard.home.ctrl => keyboard.up.cmd,

        // ⌃ Ctrl + End ➔ ⌘ Cmd + ↓ (Nhảy về cuối tài liệu / trang)
        keyboard.end.ctrl => keyboard.down.cmd,

        // ⌃ Ctrl + ⇧ Shift + Home ➔ ⇧ Shift + ⌘ Cmd + ↑ (Bôi đen về đầu tài liệu)
        keyboard.home.ctrl.shift => keyboard.up.cmd.shift,

        // ⌃ Ctrl + ⇧ Shift + End ➔ ⇧ Shift + ⌘ Cmd + ↓ (Bôi đen về cuối tài liệu)
        keyboard.end.ctrl.shift => keyboard.down.cmd.shift,

        // =================================================================
        // 10. Điều hướng & Xóa từng từ (Word-by-word Navigation & Deletion)
        // =================================================================
        // ⌃ Ctrl + ← ➔ ⌥ Opt + ← (Nhảy sang từ bên trái)
        keyboard.left.ctrl => keyboard.left.opt,

        // ⌃ Ctrl + → ➔ ⌥ Opt + → (Nhảy sang từ bên phải)
        keyboard.right.ctrl => keyboard.right.opt,

        // ⌃ Ctrl + ⇧ Shift + ← ➔ ⇧ Shift + ⌥ Opt + ← (Bôi đen từ bên trái)
        keyboard.left.ctrl.shift => keyboard.left.opt.shift,

        // ⌃ Ctrl + ⇧ Shift + → ➔ ⇧ Shift + ⌥ Opt + → (Bôi đen từ bên phải)
        keyboard.right.ctrl.shift => keyboard.right.opt.shift,

        // ⌃ Ctrl + Backspace ➔ ⌥ Opt + Backspace (Xóa cả từ phía trước)
        keyboard.backspace.ctrl => keyboard.backspace.opt,

        // ⌃ Ctrl + Delete (Forward Delete) ➔ ⌥ Opt + Delete (Xóa cả từ phía sau)
        keyboard.forwardDelete.ctrl => keyboard.forwardDelete.opt,
    ]
}
