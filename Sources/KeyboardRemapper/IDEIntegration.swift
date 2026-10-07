import Foundation

/// Tự động phát hiện và đồng bộ cấu hình phím tắt cho các IDE phổ biến (Antigravity IDE, VS Code, Cursor, VSCodium).
/// Giúp tổ hợp Ctrl+C hoạt động thông minh:
/// - Khi bôi đen đoạn code (hoặc văn bản) ➔ Tự động Copy.
/// - Khi trong Terminal và không bôi đen ➔ Giữ nguyên Ctrl+C (gửi tín hiệu SIGINT ngắt tiến trình).
public struct IDEIntegration {
    public struct TargetIDE {
        public let name: String
        public let bundleId: String
        public let relativeUserPath: String
    }

    public static let supportedIDEs: [TargetIDE] = [
        TargetIDE(
            name: "Antigravity IDE",
            bundleId: "com.google.antigravity-ide",
            relativeUserPath: "Library/Application Support/Antigravity IDE/User"
        ),
        TargetIDE(
            name: "Visual Studio Code",
            bundleId: "com.microsoft.VSCode",
            relativeUserPath: "Library/Application Support/Code/User"
        ),
        TargetIDE(
            name: "Cursor",
            bundleId: "com.todesktop.230313mzl4w4u92",
            relativeUserPath: "Library/Application Support/Cursor/User"
        ),
        TargetIDE(
            name: "VSCodium",
            bundleId: "com.vscodium",
            relativeUserPath: "Library/Application Support/VSCodium/User"
        )
    ]

    /// Tự động quét và đồng bộ cấu hình keybindings.json cho tất cả IDE được hỗ trợ đã cài đặt trên máy
    @discardableResult
    public static func syncKeybindings(verbose: Bool = false) -> [String] {
        var syncedIDEs: [String] = []
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path

        for ide in supportedIDEs {
            let userDir = "\(homeDir)/\(ide.relativeUserPath)"
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: userDir, isDirectory: &isDir), isDir.boolValue else {
                continue
            }

            let keybindingsPath = "\(userDir)/keybindings.json"
            if patchKeybindingsFile(at: keybindingsPath) {
                syncedIDEs.append(ide.name)
                print("💡 [IDE Auto-Sync] Đã tự động cấu hình phím tắt Ctrl+C cho \(ide.name) (Copy khi bôi đen, SIGINT trong terminal).")
            } else if verbose {
                print("ℹ️  [IDE Auto-Sync] \(ide.name) đã có cấu hình Ctrl+C chuẩn.")
            }
        }

        return syncedIDEs
    }

    /// Thêm rule ctrl+c vào file keybindings.json nếu chưa có
    private static func patchKeybindingsFile(at path: String) -> Bool {
        let fileManager = FileManager.default

        let rulesToAdd = """
            {
                "key": "ctrl+c",
                "command": "editor.action.clipboardCopyAction",
                "when": "textInputFocus"
            },
            {
                "key": "ctrl+c",
                "command": "workbench.action.terminal.copySelection",
                "when": "terminalFocus && terminalTextSelected"
            }
        """

        if !fileManager.fileExists(atPath: path) {
            let content = """
            // Place your key bindings in this file to override the defaults
            [
            \(rulesToAdd)
            ]
            """
            do {
                try content.write(toFile: path, atomically: true, encoding: .utf8)
                return true
            } catch {
                return false
            }
        }

        guard let existingContent = try? String(contentsOfFile: path, encoding: .utf8) else {
            return false
        }

        // Nếu đã có cấu hình ctrl+c cho clipboardCopyAction thì không cần sửa
        if existingContent.contains("editor.action.clipboardCopyAction") && existingContent.contains("ctrl+c") {
            return false
        }

        // Tìm vị trí đóng ngoặc vuông ']' cuối cùng của mảng JSON
        if let lastBracketIndex = existingContent.lastIndex(of: "]") {
            var prefix = String(existingContent[..<lastBracketIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
            let suffix = String(existingContent[lastBracketIndex...])

            if prefix.hasSuffix("[") {
                let newContent = "\(prefix)\n\(rulesToAdd)\n\(suffix)\n"
                do {
                    try newContent.write(toFile: path, atomically: true, encoding: .utf8)
                    return true
                } catch {
                    return false
                }
            } else {
                if !prefix.hasSuffix(",") {
                    prefix += ","
                }
                let newContent = "\(prefix)\n\(rulesToAdd)\n\(suffix)\n"
                do {
                    try newContent.write(toFile: path, atomically: true, encoding: .utf8)
                    return true
                } catch {
                    return false
                }
            }
        } else {
            let newContent = """
            [
            \(rulesToAdd)
            ]
            """
            do {
                try newContent.write(toFile: path, atomically: true, encoding: .utf8)
                return true
            } catch {
                return false
            }
        }
    }
}
