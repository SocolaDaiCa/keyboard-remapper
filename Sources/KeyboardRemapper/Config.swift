import Foundation
import CoreGraphics

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

public struct KeyMapping: Codable, Equatable {
    public var from: KeyCombo
    public var to: KeyCombo

    public init(from: KeyCombo, to: KeyCombo) {
        self.from = from
        self.to = to
    }

    public init(from: Key, to: Key) {
        self.from = KeyCombo(from)
        self.to = KeyCombo(to)
    }

    public var description: String {
        return "\(from.displayString)  ➔  \(to.displayString)"
    }
}

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

public struct CompiledMapping {
    public let fromCode: CGKeyCode
    public let fromFlags: CGEventFlags
    public let toCode: CGKeyCode
    public let toFlags: CGEventFlags
    public let displayString: String

    public func matches(code: CGKeyCode, flags: CGEventFlags) -> Bool {
        guard code == fromCode else { return false }
        let relevantFlags = flags.intersection(KeyCodeHelper.modifierMask)
        return relevantFlags == fromFlags
    }
}

public struct ConfigCompiler {
    public static func compile(config: Config) throws -> [CompiledMapping] {
        var compiled: [CompiledMapping] = []

        for (index, mapping) in config.mappings.enumerated() {
            guard let fromCode = KeyCodeHelper.keyCode(for: mapping.from.key) else {
                throw ConfigError.unknownKey(mapping.from.key, ruleIndex: index + 1, direction: "from")
            }
            guard let toCode = KeyCodeHelper.keyCode(for: mapping.to.key) else {
                throw ConfigError.unknownKey(mapping.to.key, ruleIndex: index + 1, direction: "to")
            }

            let fromFlags = KeyCodeHelper.parseModifiers(mapping.from.modifiers)
            let toFlags = KeyCodeHelper.parseModifiers(mapping.to.modifiers)

            compiled.append(
                CompiledMapping(
                    fromCode: fromCode,
                    fromFlags: fromFlags,
                    toCode: toCode,
                    toFlags: toFlags,
                    displayString: mapping.description
                )
            )
        }

        return compiled
    }
}

public enum ConfigError: LocalizedError {
    case unknownKey(String, ruleIndex: Int, direction: String)

    public var errorDescription: String? {
        switch self {
        case .unknownKey(let key, let ruleIndex, let direction):
            return "Quy tắc #\(ruleIndex): Không nhận dạng được phím '\(key)' trong phần '\(direction)'. Dùng --list-keys để xem danh sách phím hỗ trợ."
        }
    }
}
