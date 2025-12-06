import Foundation

/// Command to swipe in a direction
public struct SwipeCommand: UICommand, Equatable, Sendable {
    public let command: String = "swipe"
    public let direction: SwipeDirection
    public let target: ElementTarget?

    private enum CodingKeys: String, CodingKey {
        case command
        case direction
        case target
    }

    public init(direction: SwipeDirection, target: ElementTarget? = nil) {
        self.direction = direction
        self.target = target
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let command = try container.decodeIfPresent(String.self, forKey: .command) {
            guard command == "swipe" else {
                throw DecodingError.dataCorruptedError(
                    forKey: .command,
                    in: container,
                    debugDescription: "Expected 'swipe' command"
                )
            }
        }
        self.direction = try container.decode(SwipeDirection.self, forKey: .direction)
        self.target = try container.decodeIfPresent(ElementTarget.self, forKey: .target)
    }
}
