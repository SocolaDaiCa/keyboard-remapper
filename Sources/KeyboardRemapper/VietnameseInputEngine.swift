import Foundation
import CoreGraphics

// =============================================================================
// 🇻🇳 VIETNAMESE TELEX INPUT ENGINE
// =============================================================================
//
// Bộ gõ tiếng Việt kiểu Telex hoạt động ở system-level.
// Không cần bật input source tiếng Việt của macOS — không bị gạch chân,
// hoạt động hoàn hảo trong Terminal và mọi ứng dụng.
//
// Quy tắc Telex:
//   Nguyên âm:  aa→â  ee→ê  oo→ô  ow/wo→ơ  uw/wu→ư  dd→đ
//   Dấu thanh: (sau nguyên âm)
//     s = sắc (´)   f = huyền (`)   r = hỏi (̉)
//     x = ngã (~)   j = nặng (.)    z = bỏ dấu
// =============================================================================

// MARK: - Action

/// Kết quả xử lý của engine cho mỗi ký tự gõ vào
public enum VietnameseAction {
    /// Gõ bình thường, không có gì đặc biệt
    case passThrough
    /// Xóa `deleteCount` ký tự đã in ra màn hình, rồi chèn chuỗi `insert`
    case replace(deleteCount: Int, insert: String)
    /// Reset trạng thái bộ gõ (Space, Enter, Esc, arrow keys...)
    case reset
}

// MARK: - Engine

public class VietnameseInputEngine {

    // MARK: State

    /// Buffer các ký tự đã gõ trong từ hiện tại (dạng raw Telex input, VD: "tieegns")
    private var inputBuffer: String = ""

    /// Chuỗi Unicode đã được compose và in ra màn hình (VD: "tiếng")
    private var outputBuffer: String = ""

    // MARK: - Vowels & Tone Marks

    /// Các nguyên âm cơ bản có thể mang dấu mũ/móc
    private static let baseVowels: Set<Character> = ["a", "e", "o", "u", "i"]

    /// Dấu mũ/móc Telex triggers
    private static let hatTriggers: [String: Character] = [
        "aa": "â", "ee": "ê", "oo": "ô"
    ]

    /// Biến thể nguyên âm đầy đủ (cả thường và hoa)
    private static let vowelVariants: [Character: [Character]] = [
        // a
        "a": ["a", "à", "á", "ả", "ã", "ạ",
               "â", "ầ", "ấ", "ẩ", "ẫ", "ậ",
               "ă", "ằ", "ắ", "ẳ", "ẵ", "ặ"],
        "A": ["A", "À", "Á", "Ả", "Ã", "Ạ",
               "Â", "Ầ", "Ấ", "Ẩ", "Ẫ", "Ậ",
               "Ă", "Ằ", "Ắ", "Ẳ", "Ẵ", "Ặ"],
        // e
        "e": ["e", "è", "é", "ẻ", "ẽ", "ẹ",
               "ê", "ề", "ế", "ể", "ễ", "ệ"],
        "E": ["E", "È", "É", "Ẻ", "Ẽ", "Ẹ",
               "Ê", "Ề", "Ế", "Ể", "Ễ", "Ệ"],
        // o
        "o": ["o", "ò", "ó", "ỏ", "õ", "ọ",
               "ô", "ồ", "ố", "ổ", "ỗ", "ộ",
               "ơ", "ờ", "ớ", "ở", "ỡ", "ợ"],
        "O": ["O", "Ò", "Ó", "Ỏ", "Õ", "Ọ",
               "Ô", "Ồ", "Ố", "Ổ", "Ỗ", "Ộ",
               "Ơ", "Ờ", "Ớ", "Ở", "Ỡ", "Ợ"],
        // u
        "u": ["u", "ù", "ú", "ủ", "ũ", "ụ",
               "ư", "ừ", "ứ", "ử", "ữ", "ự"],
        "U": ["U", "Ù", "Ú", "Ủ", "Ũ", "Ụ",
               "Ư", "Ừ", "Ứ", "Ử", "Ữ", "Ự"],
        // i
        "i": ["i", "ì", "í", "ỉ", "ĩ", "ị"],
        "I": ["I", "Ì", "Í", "Ỉ", "Ĩ", "Ị"],
        // y
        "y": ["y", "ỳ", "ý", "ỷ", "ỹ", "ỵ"],
        "Y": ["Y", "Ỳ", "Ý", "Ỷ", "Ỹ", "Ỵ"],
        // d
        "d": ["d", "đ"],
        "D": ["D", "Đ"],
    ]

    // Chỉ số tone trong mảng vowelVariants (offset trong nhóm 6)
    // 0=ngang, 1=huyền, 2=sắc, 3=hỏi, 4=ngã, 5=nặng
    private static let toneIndex: [Character: Int] = [
        "s": 2, // sắc
        "f": 1, // huyền
        "r": 3, // hỏi
        "x": 4, // ngã
        "j": 5, // nặng
        "z": 0, // bỏ dấu (về ngang)
    ]

    // MARK: - Public API

    public init() {}

    /// Reset hoàn toàn trạng thái bộ gõ (gọi khi gặp phím không phải ký tự)
    public func reset() {
        inputBuffer = ""
        outputBuffer = ""
    }

    /// Xử lý một ký tự vừa gõ. Trả về action cần thực hiện.
    /// - Parameter char: Ký tự Unicode từ event (đã lowercase nếu cần)
    /// - Parameter rawChar: Ký tự gốc (có thể hoa)
    /// - Returns: Action cho RemapperEngine thực hiện
    public func processCharacter(_ rawChar: Character) -> VietnameseAction {
        let lower = Character(rawChar.lowercased())

        // --- 1. Thử áp dụng dấu thanh điệu ---
        if let toneIdx = Self.toneIndex[lower] {
            if let result = applyTone(toneIdx, trigger: lower) {
                return result
            }
            // Nếu không có nguyên âm trong buffer để gắn dấu → xuất bình thường
            return appendChar(rawChar)
        }

        // --- 2. Thử chuyển đổi nguyên âm (aa→â, ee→ê, oo→ô) ---
        if let hatResult = tryApplyHat(rawChar) {
            return hatResult
        }

        // --- 3. Thử ow/wo → ơ, uw/wu → ư ---
        if let hookResult = tryApplyHook(rawChar) {
            return hookResult
        }

        // --- 4. Thử dd → đ ---
        if lower == "d", let ddResult = tryApplyD(rawChar) {
            return ddResult
        }

        // --- 5. Gõ bình thường ---
        return appendChar(rawChar)
    }

    // MARK: - Private Compose Logic

    /// Thêm ký tự vào buffer và trả về passThrough
    private func appendChar(_ char: Character) -> VietnameseAction {
        inputBuffer.append(char)
        outputBuffer.append(char)
        return .passThrough
    }

    /// Áp dụng dấu thanh điệu lên nguyên âm cuối cùng trong outputBuffer
    private func applyTone(_ toneIdx: Int, trigger: Character) -> VietnameseAction? {
        // Tìm nguyên âm cuối cùng có thể mang dấu trong outputBuffer
        guard let (vowelPos, vowelChar, variants) = findLastVowel(in: outputBuffer) else {
            return nil
        }

        // Lấy base vowel và hat type của nguyên âm hiện tại
        let (_, hatType, _) = decompose(vowelChar)

        // Lấy mảng variants cho baseKey
        guard let variantList = variants else {
            return nil
        }

        // Tính index mới trong mảng variants
        // Cấu trúc: [ngang(0), huyền(1), sắc(2), hỏi(3), ngã(4), nặng(5),
        //            ^ngang(6), ^huyền(7), ^sắc(8), ^hỏi(9), ^ngã(10), ^nặng(11),
        //            hook_ngang(12), ...]
        let groupOffset = hatType * 6
        let newIdx = groupOffset + toneIdx
        guard newIdx < variantList.count else { return nil }

        let newChar = variantList[newIdx]

        // Tính số ký tự cần xóa = từ vị trí vowel đến cuối outputBuffer
        let charsAfterVowel = outputBuffer.distance(from: vowelPos, to: outputBuffer.endIndex) - 1
        let deleteCount = charsAfterVowel + 1 // +1 cho chính vowelChar

        // Tạo suffix (phần sau nguyên âm)
        let suffixStart = outputBuffer.index(after: vowelPos)
        let suffix = String(outputBuffer[suffixStart...])

        // Cập nhật state
        let beforeVowel = String(outputBuffer[..<vowelPos])
        outputBuffer = beforeVowel + String(newChar) + suffix
        inputBuffer.append(trigger)

        let insertString = String(newChar) + suffix
        return .replace(deleteCount: deleteCount, insert: insertString)
    }

    /// Thử chuyển đổi aa→â, ee→ê, oo→ô
    private func tryApplyHat(_ rawChar: Character) -> VietnameseAction? {
        let lower = Character(rawChar.lowercased())
        guard Self.baseVowels.contains(lower) else { return nil }

        // Lấy ký tự cuối của outputBuffer
        guard let lastOut = outputBuffer.last else { return nil }
        let lastLower = Character(lastOut.lowercased())

        // Phải trùng nguyên âm: aa, ee, oo
        guard lastLower == lower, ["a", "e", "o"].contains(lower) else { return nil }

        // Xác định hat char
        let hatChar: Character
        switch lower {
        case "a": hatChar = lastOut.isUppercase ? "Â" : "â"
        case "e": hatChar = lastOut.isUppercase ? "Ê" : "ê"
        case "o": hatChar = lastOut.isUppercase ? "Ô" : "ô"
        default: return nil
        }

        // Cập nhật state: thay ký tự cuối outputBuffer
        outputBuffer.removeLast()
        outputBuffer.append(hatChar)
        inputBuffer.append(rawChar)

        return .replace(deleteCount: 1, insert: String(hatChar))
    }

    /// Thử chuyển đổi ow/wo→ơ, uw/wu→ư
    private func tryApplyHook(_ rawChar: Character) -> VietnameseAction? {
        let lower = Character(rawChar.lowercased())
        guard let lastOut = outputBuffer.last else { return nil }
        let lastLower = Character(lastOut.lowercased())
        let isUpper = lastOut.isUppercase || rawChar.isUppercase

        let hookChar: Character?
        switch (lastLower, lower) {
        case ("o", "w"), ("w", "o"):
            hookChar = isUpper ? "Ơ" : "ơ"
        case ("u", "w"), ("w", "u"):
            hookChar = isUpper ? "Ư" : "ư"
        default:
            hookChar = nil
        }

        guard let result = hookChar else { return nil }

        outputBuffer.removeLast()
        outputBuffer.append(result)
        inputBuffer.append(rawChar)

        return .replace(deleteCount: 1, insert: String(result))
    }

    /// Thử chuyển đổi dd→đ
    private func tryApplyD(_ rawChar: Character) -> VietnameseAction? {
        guard let lastOut = outputBuffer.last else { return nil }
        let lastLower = Character(lastOut.lowercased())
        guard lastLower == "d" else { return nil }

        // Phải là đầu từ (không có ký tự không phải d trước đó trong buffer)
        let isUpper = lastOut.isUppercase || rawChar.isUppercase
        let result: Character = isUpper ? "Đ" : "đ"

        outputBuffer.removeLast()
        outputBuffer.append(result)
        inputBuffer.append(rawChar)

        return .replace(deleteCount: 1, insert: String(result))
    }

    // MARK: - Vowel Decomposition Helpers

    /// Tìm nguyên âm cuối cùng trong chuỗi có thể mang dấu thanh
    /// Returns: (index trong string, ký tự, mảng variants)
    private func findLastVowel(in str: String) -> (String.Index, Character, [Character]?)? {
        var idx = str.endIndex
        while idx > str.startIndex {
            str.formIndex(before: &idx)
            let ch = str[idx]
            let base = Character(ch.lowercased())
            if let variants = Self.vowelVariants[base] ?? Self.vowelVariants[ch] {
                return (idx, ch, variants)
            }
            // Nếu gặp phụ âm không phải cuối từ thì dừng
            if !isVowelLike(base) && base != "đ" {
                break
            }
        }
        return nil
    }

    private func isVowelLike(_ c: Character) -> Bool {
        let vowelSet: Set<Character> = ["a","â","ă","e","ê","o","ô","ơ","u","ư","i","y",
                                         "à","á","ả","ã","ạ","ề","ế","ể","ễ","ệ"]
        return vowelSet.contains(c)
    }

    /// Phân tích một nguyên âm đã compose thành (baseKey, hatType, toneIdx)
    /// hatType: 0=thường, 1=mũ(â/ê/ô), 2=móc(ơ/ư/ă)
    private func decompose(_ ch: Character) -> (Character, Int, [Character]?) {
        for (baseKey, variants) in Self.vowelVariants {
            if let pos = variants.firstIndex(of: ch) {
                let hatType = pos / 6
                return (baseKey, hatType, variants)
            }
        }
        return (ch, 0, nil)
    }
}

// MARK: - Character Extension

private extension Character {
    var isUppercase: Bool {
        return self == Character(self.uppercased()) && self != Character(self.lowercased())
    }
}
