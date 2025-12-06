import Foundation

/// Command to tap on an element
public struct TapCommand: UICommand, Equatable, Sendable {
    public let command: String = "tap"
    public let target: ElementTarget

    private enum CodingKeys: String, CodingKey {
        case command
        case target
    }

    public init(target: ElementTarget) {
        self.target = target
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Validate command field if present
        if let command = try container.decodeIfPresent(String.self, forKey: .command) {
            guard command == "tap" else {
                throw DecodingError.dataCorruptedError(
                    forKey: .command,
                    in: container,
                    debugDescription: "Expected 'tap' command"
                )
            }
        }
        self.target = try container.decode(ElementTarget.self, forKey: .target)
    }
}
