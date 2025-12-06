import Foundation

/// Target specification for UI commands
public enum ElementTarget: Codable, Equatable, Sendable {
    case identifier(String)
    case label(String)
    case coordinate(x: Int, y: Int)

    private enum CodingKeys: String, CodingKey {
        case type
        case value
        case x
        case y
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "identifier":
            let value = try container.decode(String.self, forKey: .value)
            self = .identifier(value)
        case "label":
            let value = try container.decode(String.self, forKey: .value)
            self = .label(value)
        case "coordinate":
            let x = try container.decode(Int.self, forKey: .x)
            let y = try container.decode(Int.self, forKey: .y)
            self = .coordinate(x: x, y: y)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown target type: \(type)"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .identifier(let value):
            try container.encode("identifier", forKey: .type)
            try container.encode(value, forKey: .value)
        case .label(let value):
            try container.encode("label", forKey: .type)
            try container.encode(value, forKey: .value)
        case .coordinate(let x, let y):
            try container.encode("coordinate", forKey: .type)
            try container.encode(x, forKey: .x)
            try container.encode(y, forKey: .y)
        }
    }
}

/// Swipe direction
public enum SwipeDirection: String, Codable, Sendable {
    case up
    case down
    case left
    case right
}

/// Protocol for all UI commands
public protocol UICommand: Codable, Sendable {
    var command: String { get }
}
