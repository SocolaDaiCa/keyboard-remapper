import Foundation
import CoreGraphics
import ApplicationServices

public enum RemapperError: LocalizedError {
    case accessibilityNotGranted
    case tapCreationFailed

    public var errorDescription: String? {
        switch self {
        case .accessibilityNotGranted:
            return """
            ❌ Chưa được cấp quyền Trợ năng (Accessibility Permission)!
               Trên macOS, ứng dụng cần quyền Trợ năng để can thiệp bàn phím.
               Vui lòng mở:
                 System Settings ➔ Privacy & Security ➔ Accessibility
                 (Cài đặt hệ thống ➔ Quyền riêng tư & Bảo mật ➔ Trợ năng)
               Và BẬT quyền cho ứng dụng Terminal / iTerm / IDE của bạn.
            """
        case .tapCreationFailed:
            return """
            ❌ Không thể khởi tạo CGEventTap.
               Nguyên nhân phổ biến: Tiến trình chưa có quyền Accessibility, hoặc bị xung đột.
               Hãy chạy lệnh: keyboard-remapper --check-permission
            """
        }
    }
}

public class RemapperEngine {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var mouseTap: CFMachPort?
    private var mouseRunLoopSource: CFRunLoopSource?
    private let mappings: [CompiledMapping]
    private let verbose: Bool
    private let controlClickToCommandClick: Bool
    private let eventSource: CGEventSource?
    public static let magicTag: Int64 = 0x52454D4150 // ASCII "REMAP"

    public init(mappings: [CompiledMapping], verbose: Bool = false, controlClickToCommandClick: Bool = false) {
        self.mappings = mappings
        self.verbose = verbose
        self.controlClickToCommandClick = controlClickToCommandClick
        // HID system state source simulates hardware input events
        self.eventSource = CGEventSource(stateID: .hidSystemState)
    }

    /// Kiểm tra quyền Accessibility trên macOS
    @discardableResult
    public static func checkAccessibility(prompt: Bool = false) -> Bool {
        if prompt {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            return AXIsProcessTrustedWithOptions(options)
        } else {
            return AXIsProcessTrusted()
        }
    }

    /// Khởi động Event Tap và gắn vào RunLoop
    public func start() throws {
        let isTrusted = RemapperEngine.checkAccessibility(prompt: false)
        if !isTrusted {
            // Hiển thị dialog hệ thống yêu cầu cấp quyền
            RemapperEngine.checkAccessibility(prompt: true)
            throw RemapperError.accessibilityNotGranted
        }

        let eventMask = (1 << CGEventType.keyDown.rawValue) |
                        (1 << CGEventType.keyUp.rawValue)

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        // Thử tạo EventTap tại cghidEventTap (toàn hệ thống), nếu không được fallback sang cgSessionEventTap
        let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let engine = Unmanaged<RemapperEngine>.fromOpaque(refcon).takeUnretainedValue()
                return engine.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: selfPtr
        ) ?? CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let engine = Unmanaged<RemapperEngine>.fromOpaque(refcon).takeUnretainedValue()
                return engine.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: selfPtr
        )

        guard let validTap = tap else {
            throw RemapperError.tapCreationFailed
        }

        self.eventTap = validTap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, validTap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: validTap, enable: true)

        // Khởi động Mouse Event Tap nếu bật tính năng Control+Click → Command+Click
        if controlClickToCommandClick {
            let mouseMask = (1 << CGEventType.leftMouseDown.rawValue) |
                            (1 << CGEventType.leftMouseUp.rawValue)

            let mouseTap = CGEvent.tapCreate(
                tap: .cghidEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: CGEventMask(mouseMask),
                callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                    guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                    let engine = Unmanaged<RemapperEngine>.fromOpaque(refcon).takeUnretainedValue()
                    return engine.handleMouseEvent(proxy: proxy, type: type, event: event)
                },
                userInfo: selfPtr
            ) ?? CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: CGEventMask(mouseMask),
                callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                    guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                    let engine = Unmanaged<RemapperEngine>.fromOpaque(refcon).takeUnretainedValue()
                    return engine.handleMouseEvent(proxy: proxy, type: type, event: event)
                },
                userInfo: selfPtr
            )

            if let validMouseTap = mouseTap {
                self.mouseTap = validMouseTap
                let mouseSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, validMouseTap, 0)
                self.mouseRunLoopSource = mouseSource
                CFRunLoopAddSource(CFRunLoopGetCurrent(), mouseSource, .commonModes)
                CGEvent.tapEnable(tap: validMouseTap, enable: true)
                if verbose {
                    print("🖱️  Mouse EventTap (⌃ Ctrl+Click → ⌘ Cmd+Click) đã được kích hoạt.")
                }
            } else if verbose {
                print("⚠️ Không thể khởi tạo Mouse EventTap cho Control+Click → Command+Click.")
            }
        }

        if verbose {
            print("🚀 CGEventTap đã được kích hoạt thành công.")
        }
    }

    /// Dừng Event Tap và gỡ bỏ khỏi RunLoop
    public func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            }
            self.eventTap = nil
            self.runLoopSource = nil
        }
        if let tap = mouseTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = mouseRunLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            }
            self.mouseTap = nil
            self.mouseRunLoopSource = nil
        }
    }

    /// Xử lý callback của từng sự kiện phím
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Nếu hệ thống tạm ngắt do timeout hoặc lag, tự động kích hoạt lại tap
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
                if verbose {
                    print("⚠️ EventTap bị tạm ngắt bởi macOS, đã tự động phục hồi.")
                }
            }
            return Unmanaged.passRetained(event)
        }

        // Bỏ qua các sự kiện do chính remapper phát ra để tránh loop vô tận
        let userData = event.getIntegerValueField(.eventSourceUserData)
        if userData == RemapperEngine.magicTag {
            return Unmanaged.passRetained(event)
        }

        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags

        // Tìm quy tắc khớp với phím và modifiers hiện tại
        guard let rule = mappings.first(where: { $0.matches(code: keyCode, flags: flags) }) else {
            return Unmanaged.passRetained(event)
        }

        let isDown = (type == .keyDown)
        let isAutorepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0

        if verbose {
            let eventName = isDown ? (isAutorepeat ? "REPEAT" : "DOWN") : "UP"
            let original = KeyCodeHelper.formatCombo(code: keyCode, flags: flags)
            let target = KeyCodeHelper.formatCombo(code: rule.toCode, flags: rule.toFlags)
            print("⚡ [\(eventName)] \(original)  ➔  \(target)")
        }

        // Tạo sự kiện mới với phím và tổ hợp phím đích
        guard let newEvent = CGEvent(
            keyboardEventSource: eventSource,
            virtualKey: rule.toCode,
            keyDown: isDown
        ) else {
            return nil
        }

        newEvent.flags = rule.toFlags
        newEvent.setIntegerValueField(.eventSourceUserData, value: RemapperEngine.magicTag)
        if isAutorepeat {
            newEvent.setIntegerValueField(.keyboardEventAutorepeat, value: 1)
        }

        // Đẩy sự kiện tổng hợp ra hệ thống (HID level)
        newEvent.post(tap: .cghidEventTap)

        // Triệt tiêu sự kiện phím gốc (chặn không cho gửi tiếp)
        return nil
    }

    /// Xử lý mouse events: chuyển Control+Click thành Command+Click
    private func handleMouseEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Tự phục hồi nếu tap bị timeout
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = mouseTap {
                CGEvent.tapEnable(tap: tap, enable: true)
                if verbose {
                    print("⚠️ Mouse EventTap bị tạm ngắt bởi macOS, đã tự động phục hồi.")
                }
            }
            return Unmanaged.passRetained(event)
        }

        // Bỏ qua event do chính remapper phát ra
        let userData = event.getIntegerValueField(.eventSourceUserData)
        if userData == RemapperEngine.magicTag {
            return Unmanaged.passRetained(event)
        }

        let flags = event.flags

        // Chỉ xử lý khi đang giữ Control (và không có Command)
        guard flags.contains(.maskControl),
              !flags.contains(.maskCommand) else {
            return Unmanaged.passRetained(event)
        }

        // Xây dựng flags mới: bỏ Control, thêm Command (giữ lại Shift, Option nếu có)
        var newFlags = flags
        newFlags.remove(.maskControl)
        newFlags.insert(.maskCommand)

        // Clone event và cập nhật flags
        guard let newEvent = event.copy() else {
            return Unmanaged.passRetained(event)
        }
        newEvent.flags = newFlags
        newEvent.setIntegerValueField(.eventSourceUserData, value: RemapperEngine.magicTag)

        if verbose {
            let eventName = (type == .leftMouseDown) ? "MouseDown" : "MouseUp"
            print("🖱️  [\(eventName)] ⌃ Ctrl+Click  ➔  ⌘ Cmd+Click")
        }

        // Đẩy event mới và triệt tiêu event gốc
        newEvent.post(tap: .cghidEventTap)
        return nil
    }
}
