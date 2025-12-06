import Foundation

/// Command to type text into an element
public struct TypeTextCommand: UICommand, Equatable, Sendable {
    public let command: String = "typeText"
    public let text: String
    public let target: ElementTarget?

    private enum CodingKeys: String, CodingKey {
        case command
        case text
        case target
    }

    public init(text: String, target: ElementTarget? = nil) {
        self.text = text
        self.target = target
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let command = try container.decodeIfPresent(String.self, forKey: .command) {
            guard command == "typeText" else {
                throw DecodingError.dataCorruptedError(
                    forKey: .command,
                    in: container,
                    debugDescription: "Expected 'typeText' command"
                )
            }
        }
        self.text = try container.decode(String.self, forKey: .text)
        self.target = try container.decodeIfPresent(ElementTarget.self, forKey: .target)
    }
}
