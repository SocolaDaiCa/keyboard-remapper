import Foundation
import CoreGraphics

// MARK: - App Filter

/// Lọc ứng dụng để áp dụng quy tắc remap có điều kiện
public enum AppFilter: Codable, Equatable, Hashable {
    /// Chỉ áp dụng rule cho các app có bundle ID trong danh sách
    case only([String])
    /// Áp dụng cho tất cả app, TRỪ các app có bundle ID trong danh sách
    case except([String])

    private enum CodingKeys: String, CodingKey { case type, bundleIds }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .only(let ids):
            try c.encode("only", forKey: .type)
            try c.encode(ids, forKey: .bundleIds)
        case .except(let ids):
            try c.encode("except", forKey: .type)
            try c.encode(ids, forKey: .bundleIds)
        }
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(String.self, forKey: .type)
        let ids  = try c.decode([String].self, forKey: .bundleIds)
        switch type {
        case "only":   self = .only(ids)
        case "except": self = .except(ids)
        default:       self = .only(ids)
        }
    }

    /// Kiểm tra filter có match với bundle ID hiện tại không
    public func matches(bundleId: String?) -> Bool {
        guard let bundleId = bundleId else {
            // App không xác định → chỉ pass nếu là `.except`
            if case .except = self { return true }
            return false
        }
        switch self {
        case .only(let ids):   return ids.contains(bundleId)
        case .except(let ids): return !ids.contains(bundleId)
        }
    }
}

// MARK: - KeyCombo

public struct KeyCombo: Codable, Equatable {
    public var key: String
    public var modifiers: [String]?

    public init(key: String, modifiers: [String]? = nil) {
        self.key = key
        self.modifiers = modifiers
    }

    public init(_ key: Key) {
        self.key = key.name
        self.modifiers = key.modifiers.isEmpty ? nil : key.modifiers.map { $0.canonicalName }
    }

    public var displayString: String {
        return KeyCodeHelper.formatCombo(key: key, modifiers: modifiers)
    }
}

// MARK: - KeyMapping

public struct KeyMapping: Codable, Equatable {
    public var from: KeyCombo
    /// Phím đích. `nil` = passthrough (không remap, để event đi qua bình thường)
    public var to: KeyCombo?
    /// Lọc theo ứng dụng. `nil` = áp dụng cho tất cả app
    public var appFilter: AppFilter?

    public init(from: KeyCombo, to: KeyCombo?, appFilter: AppFilter? = nil) {
        self.from = from
        self.to = to
        self.appFilter = appFilter
    }

    public init(from: Key, to: Key?, appFilter: AppFilter? = nil) {
        self.from = KeyCombo(from)
        self.to = to.map { KeyCombo($0) }
        self.appFilter = appFilter
    }

    public var isPassthrough: Bool { to == nil }

    public var description: String {
        let fromStr = from.displayString
        let toStr   = to?.displayString ?? "passthrough"
        let appStr: String
        switch appFilter {
        case .only(let ids):   appStr = " [only: \(ids.joined(separator: ", "))]"
        case .except(let ids): appStr = " [except: \(ids.joined(separator: ", "))]"
        case nil:              appStr = ""
        }
        return "\(fromStr)  ➔  \(toStr)\(appStr)"
    }
}

// MARK: - Config

public struct Config: Codable {
    public var verbose: Bool?
    public var mappings: [KeyMapping]

    public init(verbose: Bool? = false, mappings: [KeyMapping]) {
        self.verbose = verbose
        self.mappings = mappings
    }

    public static var `default`: Config {
        return Config(
            verbose: false,
            mappings: [
                KeyMapping(
                    from: KeyCombo(key: "f5"),
                    to: KeyCombo(key: "r", modifiers: ["cmd"])
                ),
                KeyMapping(
                    from: KeyCombo(key: "f6"),
                    to: KeyCombo(key: "w", modifiers: ["cmd"])
                ),
                KeyMapping(
                    from: KeyCombo(key: "f5", modifiers: ["ctrl"]),
                    to: KeyCombo(key: "r", modifiers: ["cmd", "shift"])
                ),
                KeyMapping(
                    from: KeyCombo(key: "f2"),
                    to: KeyCombo(key: "enter")
                )
            ]
        )
    }

    public static func load(from filePath: String) throws -> Config {
        let url = URL(fileURLWithPath: filePath)
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(Config.self, from: data)
    }

    public func save(to filePath: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        try data.write(to: URL(fileURLWithPath: filePath))
    }
}

// MARK: - CompiledMapping

public struct CompiledMapping {
    public let fromCode: CGKeyCode
    public let fromFlags: CGEventFlags
    /// `nil` = passthrough (chặn event gốc, KHÔNG gửi event thay thế → event đi qua)
    public let toCode: CGKeyCode?
    public let toFlags: CGEventFlags?
    public let appFilter: AppFilter?
    public let displayString: String

    public var isPassthrough: Bool { toCode == nil }

    /// Kiểm tra rule có khớp với phím + modifier + app hiện tại không
    public func matches(code: CGKeyCode, flags: CGEventFlags, bundleId: String? = nil) -> Bool {
        guard code == fromCode else { return false }
        let relevantFlags = flags.intersection(KeyCodeHelper.modifierMask)
        guard relevantFlags == fromFlags else { return false }
        if let filter = appFilter {
            return filter.matches(bundleId: bundleId)
        }
        return true // Không có filter = áp dụng cho tất cả
    }
}

// MARK: - ConfigCompiler

public struct ConfigCompiler {
    public static func compile(config: Config) throws -> [CompiledMapping] {
        var compiled: [CompiledMapping] = []

        for (index, mapping) in config.mappings.enumerated() {
            guard let fromCode = KeyCodeHelper.keyCode(for: mapping.from.key) else {
                throw ConfigError.unknownKey(mapping.from.key, ruleIndex: index + 1, direction: "from")
            }

            let fromFlags = KeyCodeHelper.parseModifiers(mapping.from.modifiers)

            if let to = mapping.to {
                guard let toCode = KeyCodeHelper.keyCode(for: to.key) else {
                    throw ConfigError.unknownKey(to.key, ruleIndex: index + 1, direction: "to")
                }
                let toFlags = KeyCodeHelper.parseModifiers(to.modifiers)
                compiled.append(
                    CompiledMapping(
                        fromCode: fromCode,
                        fromFlags: fromFlags,
                        toCode: toCode,
                        toFlags: toFlags,
                        appFilter: mapping.appFilter,
                        displayString: mapping.description
                    )
                )
            } else {
                // Passthrough rule
                compiled.append(
                    CompiledMapping(
                        fromCode: fromCode,
                        fromFlags: fromFlags,
                        toCode: nil,
                        toFlags: nil,
                        appFilter: mapping.appFilter,
                        displayString: mapping.description
                    )
                )
            }
        }

        return compiled
    }
}

// MARK: - ConfigError

public enum ConfigError: LocalizedError {
    case unknownKey(String, ruleIndex: Int, direction: String)

    public var errorDescription: String? {
        switch self {
        case .unknownKey(let key, let ruleIndex, let direction):
            return "Quy tắc #\(ruleIndex): Không nhận dạng được phím '\(key)' trong phần '\(direction)'. Dùng --list-keys để xem danh sách phím hỗ trợ."
        }
    }
}
