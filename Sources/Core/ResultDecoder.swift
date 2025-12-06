import Foundation

/// Result from the UITest driver
public struct CommandResult: Codable, Sendable {
    public let success: Bool
    public let result: ResultValue?
    public let error: String?

    public init(success: Bool, result: ResultValue? = nil, error: String? = nil) {
        self.success = success
        self.result = result
        self.error = error
    }
}

/// Generic result value container
public struct ResultValue: Codable, Sendable {
    private let storage: [String: AnyCodable]

    public init() {
        self.storage = [:]
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.storage = try container.decode([String: AnyCodable].self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(storage)
    }

    public subscript(key: String) -> Any? {
        storage[key]?.value
    }
}

/// Type-erased Codable wrapper
public struct AnyCodable: Codable, Sendable {
    public let value: Any & Sendable

    public init(_ value: Any & Sendable) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            self.value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode value")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [any Sendable]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: any Sendable]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Cannot encode value"))
        }
    }
}

/// Decodes results from the UITest driver
public struct ResultDecoder: Sendable {
    public let sessionId: String
    public let directory: URL

    public var resultFilePath: URL {
        directory.appendingPathComponent("iossim-mcp-\(sessionId)-result.json")
    }

    public init(sessionId: String, directory: URL = URL(fileURLWithPath: "/tmp")) {
        self.sessionId = sessionId
        self.directory = directory
    }

    /// Reads the result file synchronously
    public func read() throws -> CommandResult {
        let data = try Data(contentsOf: resultFilePath)
        return try JSONDecoder().decode(CommandResult.self, from: data)
    }

    /// Waits for the result file to appear and reads it
    public func waitForResult(timeout: TimeInterval, pollInterval: TimeInterval = 0.1) async throws -> CommandResult {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if FileManager.default.fileExists(atPath: resultFilePath.path) {
                return try read()
            }
            try await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        }

        throw Error.timeout
    }

    public enum Error: Swift.Error, Sendable {
        case timeout
        case fileNotFound
    }
}
