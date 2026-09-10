import Foundation
import CoreGraphics

// MARK: - Modifiers

public enum Modifier: String, Codable, CaseIterable, Equatable, Hashable {
    case cmd
    case ctrl
    case opt
    case alt
    case shift
    case fn

    public var canonicalName: String {
        switch self {
        case .cmd: return "cmd"
        case .ctrl: return "ctrl"
        case .opt, .alt: return "opt"
        case .shift: return "shift"
        case .fn: return "fn"
        }
    }
}

// MARK: - Key Definition

public struct Key: Equatable, Hashable {
    public let name: String
    public let keyCode: CGKeyCode
    public var modifiers: [Modifier]
    /// Lọc app áp dụng rule này (nil = tất cả app)
    public var appFilter: AppFilter?

    public init(_ name: String, keyCode: CGKeyCode, modifiers: [Modifier] = []) {
        self.name = name
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.appFilter = nil
    }

    // MARK: - Fluent Modifier Chaining

    /// Thêm Command (⌘) vào tổ hợp phím
    public var cmd: Key { with(.cmd) }
    /// Thêm Command (⌘) vào tổ hợp phím
    public var command: Key { with(.cmd) }

    /// Thêm Control (⌃) vào tổ hợp phím
    public var ctrl: Key { with(.ctrl) }
    /// Thêm Control (⌃) vào tổ hợp phím
    public var control: Key { with(.ctrl) }

    /// Thêm Option/Alt (⌥) vào tổ hợp phím
    public var opt: Key { with(.opt) }
    /// Thêm Option/Alt (⌥) vào tổ hợp phím
    public var option: Key { with(.opt) }
    /// Thêm Option/Alt (⌥) vào tổ hợp phím
    public var alt: Key { with(.alt) }

    /// Thêm Shift (⇧) vào tổ hợp phím
    public var shift: Key { with(.shift) }

    /// Thêm phím Fn vào tổ hợp phím
    public var fn: Key { with(.fn) }

    /// Bổ sung danh sách modifiers
    public func with(_ newModifiers: Modifier...) -> Key {
        var copy = self
        for m in newModifiers {
            if !copy.modifiers.contains(m) {
                copy.modifiers.append(m)
            }
        }
        return copy
    }

    public func with(_ newModifiers: [Modifier]) -> Key {
        var copy = self
        for m in newModifiers {
            if !copy.modifiers.contains(m) {
                copy.modifiers.append(m)
            }
        }
        return copy
    }

    // MARK: - App Filter Chaining

    /// Chỉ áp dụng rule này khi một trong các app chỉ định đang active
    ///
    /// Ví dụ: `keyboard.forwardDelete.only("com.google.Chrome") => keyboard.forwardDelete.shift`
    public func only(_ bundleIds: String...) -> Key {
        var copy = self
        copy.appFilter = .only(bundleIds)
        return copy
    }

    /// Áp dụng rule này cho tất cả app, TRỪ các app chỉ định
    ///
    /// Ví dụ: `keyboard.c.ctrl.except("com.apple.Terminal") => keyboard.c.cmd`
    public func except(_ bundleIds: String...) -> Key {
        var copy = self
        copy.appFilter = .except(bundleIds)
        return copy
    }

    /// Tạo rule passthrough (không remap) — thường dùng cho app cụ thể
    ///
    /// Ví dụ: `keyboard.c.ctrl.only("com.apple.Terminal").passthrough()`
    public func passthrough() -> KeyMapping {
        return KeyMapping(from: self, to: nil as Key?, appFilter: self.appFilter)
    }

    /// Tạo quy tắc remap phím đến phím đích
    public func remap(to target: Key) -> KeyMapping {
        return KeyMapping(from: self, to: target, appFilter: self.appFilter)
    }

    public var displayString: String {
        return KeyCodeHelper.formatCombo(key: name, modifiers: modifiers.map { $0.canonicalName })
    }
}

// MARK: - Operators

infix operator => : AdditionPrecedence

/// Cú pháp gán phím trực quan: `keyboard.f5 => keyboard.r.cmd`
/// App filter (nếu có) sẽ được lấy từ `lhs`
public func => (lhs: Key, rhs: Key) -> KeyMapping {
    return KeyMapping(from: lhs, to: rhs, appFilter: lhs.appFilter)
}

/// Thêm modifier bằng toán tử + : `keyboard.r + .cmd`
public func + (lhs: Key, rhs: Modifier) -> Key {
    return lhs.with(rhs)
}

/// Thêm modifier bằng toán tử + : `.cmd + keyboard.r`
public func + (lhs: Modifier, rhs: Key) -> Key {
    return rhs.with(lhs)
}

// MARK: - Keyboard Keys Enum / Struct

public struct Keyboard {
    // MARK: Function Keys
    public static let f1 = Key("f1", keyCode: 0x7A)
    public static let f2 = Key("f2", keyCode: 0x78)
    public static let f3 = Key("f3", keyCode: 0x63)
    public static let f4 = Key("f4", keyCode: 0x76)
    public static let f5 = Key("f5", keyCode: 0x60)
    public static let f6 = Key("f6", keyCode: 0x61)
    public static let f7 = Key("f7", keyCode: 0x62)
    public static let f8 = Key("f8", keyCode: 0x64)
    public static let f9 = Key("f9", keyCode: 0x65)
    public static let f10 = Key("f10", keyCode: 0x6D)
    public static let f11 = Key("f11", keyCode: 0x67)
    public static let f12 = Key("f12", keyCode: 0x6F)
    public static let f13 = Key("f13", keyCode: 0x69)
    public static let f14 = Key("f14", keyCode: 0x6B)
    public static let f15 = Key("f15", keyCode: 0x71)
    public static let f16 = Key("f16", keyCode: 0x6A)
    public static let f17 = Key("f17", keyCode: 0x40)
    public static let f18 = Key("f18", keyCode: 0x4F)
    public static let f19 = Key("f19", keyCode: 0x50)
    public static let f20 = Key("f20", keyCode: 0x5A)

    // MARK: Print Screen
    public static let printScreen = Key("prtsc", keyCode: 0x69)
    public static let prtSc = printScreen
    public static let pctSc = printScreen
    public static let prtScr = printScreen
    public static let prtScn = printScreen

    // MARK: Letters (a-z)
    public static let a = Key("a", keyCode: 0x00)
    public static let b = Key("b", keyCode: 0x0B)
    public static let c = Key("c", keyCode: 0x08)
    public static let d = Key("d", keyCode: 0x02)
    public static let e = Key("e", keyCode: 0x0E)
    public static let f = Key("f", keyCode: 0x03)
    public static let g = Key("g", keyCode: 0x05)
    public static let h = Key("h", keyCode: 0x04)
    public static let i = Key("i", keyCode: 0x22)
    public static let j = Key("j", keyCode: 0x26)
    public static let k = Key("k", keyCode: 0x28)
    public static let l = Key("l", keyCode: 0x25)
    public static let m = Key("m", keyCode: 0x2E)
    public static let n = Key("n", keyCode: 0x2D)
    public static let o = Key("o", keyCode: 0x1F)
    public static let p = Key("p", keyCode: 0x23)
    public static let q = Key("q", keyCode: 0x0C)
    public static let r = Key("r", keyCode: 0x0F)
    public static let s = Key("s", keyCode: 0x01)
    public static let t = Key("t", keyCode: 0x11)
    public static let u = Key("u", keyCode: 0x20)
    public static let v = Key("v", keyCode: 0x09)
    public static let w = Key("w", keyCode: 0x0D)
    public static let x = Key("x", keyCode: 0x07)
    public static let y = Key("y", keyCode: 0x10)
    public static let z = Key("z", keyCode: 0x06)

    // MARK: Numbers
    public static let num0 = Key("0", keyCode: 0x1D)
    public static let num1 = Key("1", keyCode: 0x12)
    public static let num2 = Key("2", keyCode: 0x13)
    public static let num3 = Key("3", keyCode: 0x14)
    public static let num4 = Key("4", keyCode: 0x15)
    public static let num5 = Key("5", keyCode: 0x17)
    public static let num6 = Key("6", keyCode: 0x16)
    public static let num7 = Key("7", keyCode: 0x1A)
    public static let num8 = Key("8", keyCode: 0x1C)
    public static let num9 = Key("9", keyCode: 0x19)

    // Number aliases
    public static let zero = num0
    public static let one = num1
    public static let two = num2
    public static let three = num3
    public static let four = num4
    public static let five = num5
    public static let six = num6
    public static let seven = num7
    public static let eight = num8
    public static let nine = num9

    public static let k0 = num0
    public static let k1 = num1
    public static let k2 = num2
    public static let k3 = num3
    public static let k4 = num4
    public static let k5 = num5
    public static let k6 = num6
    public static let k7 = num7
    public static let k8 = num8
    public static let k9 = num9

    // MARK: Whitespace & Editing
    public static let enter = Key("enter", keyCode: 0x24)
    public static let returnKey = Key("return", keyCode: 0x24)
    public static let `return` = Key("return", keyCode: 0x24)
    public static let tab = Key("tab", keyCode: 0x30)
    public static let space = Key("space", keyCode: 0x31)
    public static let delete = Key("delete", keyCode: 0x33)
    public static let backspace = Key("backspace", keyCode: 0x33)
    public static let escape = Key("escape", keyCode: 0x35)
    public static let esc = Key("esc", keyCode: 0x35)
    public static let capslock = Key("capslock", keyCode: 0x39)
    public static let forwardDelete = Key("forwarddelete", keyCode: 0x75)

    // MARK: Navigation
    public static let left = Key("left", keyCode: 0x7B)
    public static let right = Key("right", keyCode: 0x7C)
    public static let down = Key("down", keyCode: 0x7D)
    public static let up = Key("up", keyCode: 0x7E)
    public static let arrowLeft = left
    public static let arrowRight = right
    public static let arrowDown = down
    public static let arrowUp = up

    public static let home = Key("home", keyCode: 0x73)
    public static let end = Key("end", keyCode: 0x77)
    public static let pageUp = Key("pageup", keyCode: 0x74)
    public static let pageDown = Key("pagedown", keyCode: 0x79)

    // MARK: Symbols & Punctuation
    public static let minus = Key("minus", keyCode: 0x1B)
    public static let equal = Key("equal", keyCode: 0x18)
    public static let leftBracket = Key("leftbracket", keyCode: 0x21)
    public static let bracketLeft = leftBracket
    public static let rightBracket = Key("rightbracket", keyCode: 0x1E)
    public static let bracketRight = rightBracket
    public static let quote = Key("quote", keyCode: 0x27)
    public static let semicolon = Key("semicolon", keyCode: 0x29)
    public static let backslash = Key("backslash", keyCode: 0x2A)
    public static let comma = Key("comma", keyCode: 0x2B)
    public static let slash = Key("slash", keyCode: 0x2C)
    public static let period = Key("period", keyCode: 0x2F)
    public static let dot = period
    public static let grave = Key("grave", keyCode: 0x32)

    // MARK: Keypad
    public static let keypad0 = Key("keypad0", keyCode: 0x52)
    public static let keypad1 = Key("keypad1", keyCode: 0x53)
    public static let keypad2 = Key("keypad2", keyCode: 0x54)
    public static let keypad3 = Key("keypad3", keyCode: 0x55)
    public static let keypad4 = Key("keypad4", keyCode: 0x56)
    public static let keypad5 = Key("keypad5", keyCode: 0x57)
    public static let keypad6 = Key("keypad6", keyCode: 0x58)
    public static let keypad7 = Key("keypad7", keyCode: 0x59)
    public static let keypad8 = Key("keypad8", keyCode: 0x5B)
    public static let keypad9 = Key("keypad9", keyCode: 0x5C)
    public static let keypadDecimal = Key("keypaddecimal", keyCode: 0x41)
    public static let keypadMultiply = Key("keypadmultiply", keyCode: 0x43)
    public static let keypadPlus = Key("keypadplus", keyCode: 0x45)
    public static let keypadClear = Key("keypadclear", keyCode: 0x47)
    public static let keypadDivide = Key("keypaddivide", keyCode: 0x4B)
    public static let keypadEnter = Key("keypadenter", keyCode: 0x4C)
    public static let keypadMinus = Key("keypadminus", keyCode: 0x4E)
    public static let keypadEquals = Key("keypadequals", keyCode: 0x51)

    /// Cho phép tạo phím tùy biến nếu cần
    public static func custom(_ name: String) -> Key {
        let code = KeyCodeHelper.keyCode(for: name) ?? 0
        return Key(name, keyCode: code)
    }
}

/// Cho phép gõ chữ thường `keyboard.<key>` hoặc chữ hoa `Keyboard.<key>`
public typealias keyboard = Keyboard
