import Foundation
import CoreGraphics

public struct KeyCodeHelper {
    // Map human-readable key names to macOS CGKeyCode
    public static let keyNameToCode: [String: CGKeyCode] = [
        // Letters
        "a": 0x00, "s": 0x01, "d": 0x02, "f": 0x03, "h": 0x04, "g": 0x05, "z": 0x06, "x": 0x07,
        "c": 0x08, "v": 0x09, "b": 0x0B, "q": 0x0C, "w": 0x0D, "e": 0x0E, "r": 0x0F, "y": 0x10,
        "t": 0x11, "1": 0x12, "2": 0x13, "3": 0x14, "4": 0x15, "6": 0x16, "5": 0x17, "equal": 0x18,
        "=": 0x18, "9": 0x19, "7": 0x1A, "minus": 0x1B, "-": 0x1B, "8": 0x1C, "0": 0x1D,
        "rightbracket": 0x1E, "]": 0x1E, "o": 0x1F, "u": 0x20, "leftbracket": 0x21, "[": 0x21,
        "i": 0x22, "p": 0x23, "l": 0x25, "j": 0x26, "quote": 0x27, "'": 0x27, "k": 0x28,
        "semicolon": 0x29, ";": 0x29, "backslash": 0x2A, "\\": 0x2A, "comma": 0x2B, ",": 0x2B,
        "slash": 0x2C, "/": 0x2C, "n": 0x2D, "m": 0x2E, "period": 0x2F, ".": 0x2F,
        "grave": 0x32, "`": 0x32,

        // Whitespace and editing
        "return": 0x24, "enter": 0x24,
        "tab": 0x30,
        "space": 0x31,
        "delete": 0x33, "backspace": 0x33,
        "escape": 0x35, "esc": 0x35,
        "capslock": 0x39,
        "forwarddelete": 0x75,

        // Function keys
        "f1": 0x7A, "f2": 0x78, "f3": 0x63, "f4": 0x76,
        "f5": 0x60, "f6": 0x61, "f7": 0x62, "f8": 0x64,
        "f9": 0x65, "f10": 0x6D, "f11": 0x67, "f12": 0x6F,
        "f13": 0x69, "f14": 0x6B, "f15": 0x71, "f16": 0x6A,
        "f17": 0x40, "f18": 0x4F, "f19": 0x50, "f20": 0x5A,
        "printscreen": 0x69, "prtsc": 0x69, "pctsc": 0x69, "prtscr": 0x69, "prtscn": 0x69,

        // Navigation
        "home": 0x73, "end": 0x77,
        "pageup": 0x74, "pagedown": 0x79,
        "left": 0x7B, "right": 0x7C, "down": 0x7D, "up": 0x7E,

        // Keypad
        "keypad0": 0x52, "keypad1": 0x53, "keypad2": 0x54, "keypad3": 0x55,
        "keypad4": 0x56, "keypad5": 0x57, "keypad6": 0x58, "keypad7": 0x59,
        "keypad8": 0x5B, "keypad9": 0x5C, "keypaddecimal": 0x41,
        "keypadmultiply": 0x43, "keypadplus": 0x45, "keypadclear": 0x47,
        "keypaddivide": 0x4B, "keypadenter": 0x4C, "keypadminus": 0x4E, "keypadequals": 0x51
    ]

    // Reverse lookup for keycode to canonical name
    public static let codeToKeyName: [CGKeyCode: String] = {
        var dict = [CGKeyCode: String]()
        for (name, code) in keyNameToCode {
            // Keep the cleaner/standard name
            if dict[code] == nil || name.count > (dict[code]?.count ?? 0) {
                dict[code] = name.uppercased()
            }
        }
        // Preferred canonical display names
        dict[0x24] = "Return"
        dict[0x30] = "Tab"
        dict[0x31] = "Space"
        dict[0x33] = "Backspace"
        dict[0x35] = "Esc"
        dict[0x7B] = "←"
        dict[0x7C] = "→"
        dict[0x7D] = "↓"
        dict[0x7E] = "↑"
        dict[0x60] = "F5"
        dict[0x61] = "F6"
        dict[0x62] = "F7"
        dict[0x64] = "F8"
        dict[0x65] = "F9"
        dict[0x6D] = "F10"
        dict[0x67] = "F11"
        dict[0x6F] = "F12"
        dict[0x69] = "PrtSc"
        return dict
    }()

    public static func keyCode(for name: String) -> CGKeyCode? {
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return keyNameToCode[normalized]
    }

    public static func keyName(for code: CGKeyCode) -> String {
        return codeToKeyName[code] ?? "KeyCode(\(code))"
    }

    // Convert modifier string list to CGEventFlags
    public static func parseModifiers(_ names: [String]?) -> CGEventFlags {
        guard let names = names else { return [] }
        var flags: CGEventFlags = []
        for rawName in names {
            let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            switch name {
            case "cmd", "command", "win", "windows", "super":
                flags.insert(.maskCommand)
            case "ctrl", "control":
                flags.insert(.maskControl)
            case "alt", "opt", "option":
                flags.insert(.maskAlternate)
            case "shift":
                flags.insert(.maskShift)
            case "fn", "function":
                flags.insert(.maskSecondaryFn)
            default:
                break
            }
        }
        return flags
    }

    // Convert flags to pretty symbols
    public static func modifierSymbols(for flags: CGEventFlags) -> [String] {
        var symbols: [String] = []
        if flags.contains(.maskControl) { symbols.append("⌃ Ctrl") }
        if flags.contains(.maskAlternate) { symbols.append("⌥ Opt") }
        if flags.contains(.maskShift) { symbols.append("⇧ Shift") }
        if flags.contains(.maskCommand) { symbols.append("⌘ Cmd") }
        return symbols
    }

    // Format human friendly combination
    public static func formatCombo(key: String, modifiers: [String]?) -> String {
        let flags = parseModifiers(modifiers)
        var parts = modifierSymbols(for: flags)
        parts.append(key.uppercased())
        return parts.joined(separator: " + ")
    }

    public static func formatCombo(code: CGKeyCode, flags: CGEventFlags) -> String {
        let relevant = flags.intersection([.maskCommand, .maskControl, .maskAlternate, .maskShift])
        var parts = modifierSymbols(for: relevant)
        parts.append(keyName(for: code))
        return parts.joined(separator: " + ")
    }

    // Only compare relevant modifiers
    public static let modifierMask: CGEventFlags = [.maskCommand, .maskControl, .maskAlternate, .maskShift]
}
