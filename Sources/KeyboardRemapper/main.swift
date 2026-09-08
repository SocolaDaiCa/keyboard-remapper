import Foundation
import CoreGraphics

// Disable output buffering so logs show immediately in non-TTY/redirected streams
setbuf(stdout, nil)
setbuf(stderr, nil)

func printUsage() {
    print("""
    ===================================================================
    ⌨️  KEYBOARD REMAPPER FOR MACOS (Swift Native CLI)
    ===================================================================

    Cú pháp:
      keyboard-remapper [options]

    Tùy chọn:
      -c, --config <file>     Chỉ định file cấu hình JSON (mặc định: dùng UserConfig.swift)
      --export-json [file]    Xuất cấu hình từ UserConfig.swift ra file JSON (mặc định: config.json)
      --init                  Tạo file config.json mẫu từ UserConfig.swift
      --list-keys             Xem toàn bộ danh sách phím và modifier được hỗ trợ
      --check-permission      Kiểm tra và yêu cầu cấp quyền Accessibility trên macOS
      -v, --verbose           Bật log chi tiết khi các phím được remap
      -h, --help              Hiển thị hướng dẫn này

    Ví dụ:
      keyboard-remapper                      # Chạy với cấu hình UserConfig.swift
      keyboard-remapper --verbose            # Chạy với log chi tiết
      keyboard-remapper --export-json        # Xuất ra file config.json
      keyboard-remapper --config custom.json # Chạy với file JSON tùy biến
    ===================================================================
    """)
}

func printKeysList() {
    print("""
    ===================================================================
    📋 DANH SÁCH PHÍM & MODIFIER ĐƯỢC HỖ TRỢ
    ===================================================================

    1. Function Keys:
       f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12, ... f20
       prtsc, pctsc, printscreen (F13)
       Cú pháp Swift: keyboard.f1 ... keyboard.f20, keyboard.prtSc / keyboard.pctSc

    2. Chữ cái & Số:
       a .. z, 0 .. 9
       Cú pháp Swift: keyboard.a ... keyboard.z, keyboard.num0 ... keyboard.num9

    3. Phím điều hướng & Soạn thảo:
       return, enter, tab, space, delete, backspace, escape, esc,
       left, right, up, down, home, end, pageup, pagedown, forwarddelete
       Cú pháp Swift: keyboard.enter, keyboard.space, keyboard.esc, keyboard.left...

    4. Dấu & Ký tự:
       minus, equal, leftbracket, rightbracket, semicolon, quote,
       backslash, comma, period, slash, grave
       Cú pháp Swift: keyboard.minus, keyboard.equal, keyboard.slash, keyboard.comma...

    5. Keypad:
       keypad0 .. keypad9, keypadplus, keypadminus, keypadmultiply,
       keypaddivide, keypadenter, keypaddecimal, keypadclear
       Cú pháp Swift: keyboard.keypad0 ... keyboard.keypadPlus...

    6. Modifiers (Tổ hợp phím):
       - .cmd    ➔ Phím Command (⌘)  (Ví dụ: keyboard.r.cmd)
       - .ctrl   ➔ Phím Control (⌃)  (Ví dụ: keyboard.f5.ctrl)
       - .opt    ➔ Phím Option (⌥)   (Ví dụ: keyboard.c.opt)
       - .shift  ➔ Phím Shift (⇧)    (Ví dụ: keyboard.r.cmd.shift)
       - .fn     ➔ Phím Fn
    ===================================================================
    """)
}

func initConfigFile(at path: String) {
    let fileManager = FileManager.default
    if fileManager.fileExists(atPath: path) {
        print("⚠️ File '\(path)' đã tồn tại. Bỏ qua để tránh mất dữ liệu.")
        print("💡 Hãy chỉnh sửa trực tiếp file '\(path)' hoặc xóa file trước khi chạy lại --init.")
        return
    }

    let cfg = Config(verbose: UserConfig.verbose, mappings: UserConfig.mappings)
    do {
        try cfg.save(to: path)
        print("✅ Đã tạo thành công file cấu hình JSON tại: \(path)")
        print("💡 Cấu hình được khởi tạo dựa trên UserConfig.swift.")
    } catch {
        print("❌ Lỗi khi tạo file config: \(error.localizedDescription)")
        exit(1)
    }
}

func exportConfigToJson(path: String) {
    let cfg = Config(verbose: UserConfig.verbose, mappings: UserConfig.mappings)
    do {
        try cfg.save(to: path)
        print("✅ Đã xuất cấu hình từ UserConfig.swift ra: \(path)")
    } catch {
        print("❌ Lỗi khi xuất file JSON: \(error.localizedDescription)")
        exit(1)
    }
}

func checkPermissionOnly() {
    print("🔍 Đang kiểm tra quyền Trợ năng (Accessibility)...")
    let trusted = RemapperEngine.checkAccessibility(prompt: false)
    if trusted {
        print("✅ Tuyệt vời! Terminal/Ứng dụng ĐÃ ĐƯỢC CẤP QUYỀN Accessibility.")
    } else {
        print("⚠️  Chưa được cấp quyền Trợ năng!")
        print("🔔 Đang gửi yêu cầu mở hộp thoại cấp quyền hệ thống macOS...")
        _ = RemapperEngine.checkAccessibility(prompt: true)
        print("""

        👉 Hướng dẫn cấp quyền:
           1. Mở Cài đặt hệ thống (System Settings).
           2. Chọn Quyền riêng tư & Bảo mật (Privacy & Security) ➔ Trợ năng (Accessibility).
           3. Bật công tắc (ON) cho Terminal / iTerm / Cursor / Antigravity của bạn.
           4. Khởi động lại ứng dụng nếu cần.
        """)
    }
}

// -------------------------------------------------------------
// Main CLI Execution
// -------------------------------------------------------------

var customConfigPath: String? = nil
var verboseFlag = false

var args = Array(CommandLine.arguments.dropFirst())
var index = 0

while index < args.count {
    let arg = args[index]
    switch arg {
    case "-h", "--help":
        printUsage()
        exit(0)
    case "--list-keys":
        printKeysList()
        exit(0)
    case "--init":
        initConfigFile(at: "config.json")
        exit(0)
    case "--export-json":
        var targetFile = "config.json"
        if index + 1 < args.count && !args[index + 1].starts(with: "-") {
            targetFile = args[index + 1]
            index += 1
        }
        exportConfigToJson(path: targetFile)
        exit(0)
    case "--check-permission":
        checkPermissionOnly()
        exit(0)
    case "-v", "--verbose":
        verboseFlag = true
        index += 1
    case "-c", "--config":
        if index + 1 < args.count {
            customConfigPath = args[index + 1]
            index += 2
        } else {
            print("❌ Thiếu đường dẫn file cấu hình sau cờ --config")
            exit(1)
        }
    default:
        print("❌ Tùy chọn không hợp lệ: \(arg)")
        printUsage()
        exit(1)
    }
}

// Xác định nguồn cấu hình (Ưu tiên JSON nếu truyền --config, ngược lại dùng UserConfig.swift)
let configSourceDescription: String
let config: Config

if let customPath = customConfigPath {
    guard FileManager.default.fileExists(atPath: customPath) else {
        print("❌ Không tìm thấy file cấu hình tại: \(customPath)")
        exit(1)
    }
    do {
        config = try Config.load(from: customPath)
        configSourceDescription = "JSON (\(customPath))"
    } catch {
        print("❌ Lỗi khi đọc file cấu hình '\(customPath)': \(error.localizedDescription)")
        exit(1)
    }
} else {
    config = Config(verbose: UserConfig.verbose, mappings: UserConfig.mappings)
    configSourceDescription = "Swift Native (UserConfig.swift)"
}

let isVerbose = verboseFlag || (config.verbose ?? false)

// Biên dịch quy tắc ánh xạ phím
let compiledMappings: [CompiledMapping]
do {
    compiledMappings = try ConfigCompiler.compile(config: config)
} catch {
    print("❌ Lỗi cấu hình: \(error.localizedDescription)")
    exit(1)
}

if compiledMappings.isEmpty {
    print("⚠️ Cảnh báo: Danh sách mappings đang trống. Không có phím nào được remap.")
}

let isTrusted = RemapperEngine.checkAccessibility(prompt: false)

// In banner
print("""
===================================================================
⌨️  KEYBOARD REMAPPER FOR MACOS
===================================================================
Trạng thái Trợ năng (Accessibility): \(isTrusted ? "✅ Đã cấp quyền" : "⚠️  Chưa cấp quyền (Đang yêu cầu...)")
Nguồn cấu hình: \(configSourceDescription)
Chế độ Log chi tiết: \(isVerbose ? "BẬT" : "TẮT")
⌃ Ctrl+Click → ⌘ Cmd+Click: \(UserConfig.controlClickToCommandClick ? "BẬT" : "TẮT")

Danh sách quy tắc phím đang kích hoạt (\(compiledMappings.count)):
""")

for (idx, mapping) in compiledMappings.enumerated() {
    print("  [\(idx + 1)] \(mapping.displayString)")
}

print("""
===================================================================
Đang chạy nền và lắng nghe phím...
👉 Nhấn Ctrl + C hoặc Ctrl + \\ bất cứ lúc nào để dừng.
""")

let engine = RemapperEngine(
    mappings: compiledMappings,
    verbose: isVerbose,
    controlClickToCommandClick: UserConfig.controlClickToCommandClick
)

// Đăng ký bắt tín hiệu ngắt Ctrl+C, Ctrl+\ và SIGTERM để dừng sạch sẽ
signal(SIGINT, SIG_IGN)
let sigintSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
sigintSource.setEventHandler {
    print("\n👋 Đã dừng Keyboard Remapper. Tạm biệt!")
    engine.stop()
    exit(0)
}
sigintSource.resume()

signal(SIGQUIT, SIG_IGN)
let sigquitSource = DispatchSource.makeSignalSource(signal: SIGQUIT, queue: .main)
sigquitSource.setEventHandler {
    print("\n👋 Đã dừng Keyboard Remapper. Tạm biệt!")
    engine.stop()
    exit(0)
}
sigquitSource.resume()

signal(SIGTERM, SIG_IGN)
let sigtermSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
sigtermSource.setEventHandler {
    print("\n👋 Đã dừng Keyboard Remapper.")
    engine.stop()
    exit(0)
}
sigtermSource.resume()

// Khởi động remapper engine
do {
    try engine.start()
} catch {
    print("\n\(error.localizedDescription)")
    exit(1)
}

// Chạy RunLoop chính
CFRunLoopRun()
