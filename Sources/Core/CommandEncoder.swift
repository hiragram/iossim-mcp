import Foundation

/// Encodes UI commands to JSON files for the UITest driver to consume
public struct CommandEncoder: Sendable {
    public let sessionId: String
    public let directory: URL

    public var commandFilePath: URL {
        directory.appendingPathComponent("iossim-mcp-\(sessionId)-command.json")
    }

    public var resultFilePath: URL {
        directory.appendingPathComponent("iossim-mcp-\(sessionId)-result.json")
    }

    public init(sessionId: String, directory: URL = URL(fileURLWithPath: "/tmp")) {
        self.sessionId = sessionId
        self.directory = directory
    }

    /// Writes a command to the command file
    public func write<T: UICommand>(_ command: T) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(command)
        try data.write(to: commandFilePath, options: .atomic)
    }
}
